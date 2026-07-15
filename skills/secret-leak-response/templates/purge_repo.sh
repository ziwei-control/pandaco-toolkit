#!/bin/bash
# Purge secrets from a single Git repo: clone --mirror, filter-repo, force-push.
# Usage: purge_repo.sh <owner> <repo> <platform>
# platform: gitee | github
# Requires: /tmp/secrets.txt (LEAKED==>REPLACEMENT lines), $GITEE_TOKEN, $GH_TOKEN in env

set -u
OWNER="$1"; REPO="$2"; PLATFORM="$3"

case "$PLATFORM" in
  gitee)  URL="https://${OWNER}:${GITEE_TOKEN}@gitee.com/${OWNER}/${REPO}.git" ;;
  github) URL="https://ziwei-control:${GH_TOKEN}@github.com/${OWNER}/${REPO}.git" ;;
esac

WORK="/tmp/purge/${PLATFORM}-${REPO}"
mkdir -p /tmp/purge && rm -rf "$WORK"

echo "  → clone $PLATFORM/$REPO"
if ! git clone --mirror --quiet "$URL" "$WORK" 2>/tmp/clone.err; then
  echo "  ❌ clone failed: $(tail -1 /tmp/clone.err)"
  return 1 2>/dev/null || exit 1
fi

cd "$WORK"
# Skip empty repos
if [[ -z "$(git rev-list --all 2>/dev/null | head -1)" ]]; then
  echo "  ⚪ empty, skipping"
  return 0 2>/dev/null || exit 0
fi

# 1. Remove sensitive file paths
git filter-repo --force --invert-paths \
  --path config/privkey.pem --path config/fullchain.pem \
  --path-glob '.env' --path-glob '.env.backup' \
  --path-glob '**/privkey.pem' --path-glob '**/fullchain.pem' 2>&1 | tail -1

# 2. Replace secret strings in remaining content
git filter-repo --force --replace-text /tmp/secrets.txt 2>&1 | tail -1

# 3. GC to shrink pack
git reflog expire --expire=now --all
git gc --prune=now --quiet

# 4. Force push (mirror = branches + tags + all refs)
if git push --force --mirror "$URL" 2>&1 | tail -1; then
  echo "  ✓ done ($(du -sh "$WORK" | awk '{print $1}'))"
else
  echo "  ❌ push failed"
fi
