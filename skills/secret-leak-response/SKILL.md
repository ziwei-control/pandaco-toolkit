---
name: secret-leak-response
description: Respond to a secret/API-key leak across Git repos — triage, contain, rewrite history, verify, re-open. Use when discovering hard-coded API keys, tokens, SSL private keys, or passwords committed to Gitee/GitHub repos (public or private).
---

# Secret Leak Response — Emergency Playbook

Use this when you find committed secrets (API keys, tokens, SSL private keys, passwords) in Git repos that need to be purged from history.

## When to invoke

- Grep across cloned repos finds `sk-*`, `ghp_*`, `AKIA*`, `BEGIN * PRIVATE KEY`, or 32/40-hex tokens
- User says "check my repos for leaked keys" or "扫描所有仓库看有没有密钥泄露"
- Any git-tracked file contains real credentials (not placeholders like `your-key`, `xxx`)

## The 4 phases (execute in strict order)

### Phase 1 — CONTAIN (stop the bleeding, ~1 min)

Turn every *public* repo containing leaked secrets → **private** immediately. This costs nothing, buys time.

```python
# Gitee
url = f"https://gitee.com/api/v5/repos/{owner}/{repo}"
data = {"access_token": TOKEN, "name": repo, "private": True}
# PATCH with content-type json
```

```python
# GitHub
url = f"https://api.github.com/repos/{owner}/{repo}"
# PATCH with {"private": True} and Authorization: token ...
```

### Phase 2 — INVALIDATE (revoke the leaked secrets)

**Ask the user to revoke every leaked key** — history rewrites do NOT undo prior public exposure. Provide a checklist:

- [ ] Aliyun DashScope keys → 控制台 → API-Key 管理 → 删除
- [ ] GitHub PATs → github.com/settings/tokens → Delete
- [ ] Gitee tokens → gitee.com/personal_access_tokens → Delete
- [ ] SSL certs → `sudo certbot renew --cert-name <domain> --force-renewal --key-type ecdsa --new-key --deploy-hook "systemctl reload nginx"`

Verify revocation by curl-ing the endpoint with the old key — should get `invalid_api_key`.

### Phase 3 — REWRITE (purge history from every affected repo)

**Prereq**: `git-filter-repo` installed (`~/.local/bin/git-filter-repo`, single file from newren/git-filter-repo).

Create `/tmp/secrets.txt` (one `LEAKED==>REPLACEMENT` per line):

```
sk-sp-actualkey==>REDACTED_DASHSCOPE_KEY
ghp_actualtoken==>REDACTED_GITHUB_PAT
```

Purge script (see `templates/purge_repo.sh`). Per-repo workflow:

```bash
git clone --mirror --quiet "$URL" /tmp/purge/$repo
cd /tmp/purge/$repo
# Remove sensitive FILE paths
git filter-repo --force --invert-paths \
  --path config/privkey.pem --path config/fullchain.pem \
  --path-glob '.env' --path-glob '**/privkey.pem'
# Replace secret STRINGS in remaining content
git filter-repo --force --replace-text /tmp/secrets.txt
# Force push mirror
git push --force --mirror "$URL"
```

**Run this sequentially, not in parallel** — filter-repo needs full history and push bandwidth. Expect 10-30s per small repo, several minutes for a large one (>100MB history).

### Phase 4 — VERIFY (confirm rewrite worked)

Prefer **API-based verification** over `git clone --mirror + strings`:
- Gitee: clone `--mirror` + `find objects/*.pack -exec strings {} +` (works locally)
- GitHub: use Code Search API — much faster than cloning from China:

```python
url = f"https://api.github.com/search/code?q={leaked_string}+user:{owner}"
# Authorization: token ...
# total_count == 0 means clean
```

GitHub's Code Search index refreshes within ~5-30 min after force-push. If it still shows hits after 1h, force-push again (empty commit) to trigger reindex.

### Phase 5 — REOPEN (transition private → public again)

Once verify is 🟢, PATCH visibility back to public via the same APIs used in Phase 1 with `{"private": False}`.

## Common pitfalls

1. **Never trust user "已作废"**. Always verify by curl-ing the old key against the real endpoint. Expired keys return `invalid_api_key` / 401.
2. **China-based servers can't `git push github.com`** (great firewall). API endpoints (api.github.com) work. Push via git protocol needs a proxy or Gitee mirror. Use `--mirror` when possible so the operation is atomic.
3. **Empty repos**: Gitee refuses to transfer visibility of empty repos ("空仓库不支持设置为公开仓库"). Skip and note.
4. **Placeholder false positives**: When scanning, exclude strings containing `your-`, `xxx`, `example`, `placeholder`, `changeme`, `<...`. Only chase real 32/40-hex tokens or prefix-matched keys.
5. **`.env` files with real secrets**: keep `.env` locally (chmod 600), add to `.gitignore`, replace hard-coded refs in source with `process.env.KEY_NAME`. Ship `.env.example` with placeholders.
6. **filter-repo removes remote**. Re-add: `git remote add origin $URL` after filter-repo runs.
7. **Prompt cache / logs**: if the leaked key was ever sent through an LLM or CI log, those systems may still have it. Rotate anyway.

## Priorities under pressure

If disk space or time is tight, execute in this order:
1. Phase 1 (contain — 1 min)
2. Phase 2 (revoke — user does this)
3. Local source cleanup (replace hard-codes with env vars, restart services)
4. Phase 3 (rewrite history — can run overnight)
5. Phase 4 → 5 (verify + reopen)

## Templates

See `templates/purge_repo.sh` and `templates/deep_scan.py`.
