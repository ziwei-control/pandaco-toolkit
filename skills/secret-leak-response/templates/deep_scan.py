#!/usr/bin/env python3
"""Scan a repo directory for REAL leaked secrets (not placeholders).
Usage: python3 deep_scan.py <repo_dir>
Exit code 1 if hits found, 0 if clean."""
import re, os, sys
from pathlib import Path

PATTERNS = {
    "openai_key":       re.compile(r'sk-(?:proj-)?[A-Za-z0-9_-]{40,}'),
    "dashscope_sp":     re.compile(r'sk-sp-[a-f0-9]{32}'),
    "anthropic_key":    re.compile(r'sk-ant-(?:api\d+-)?[A-Za-z0-9_-]{50,}'),
    "google_key":       re.compile(r'AIza[0-9A-Za-z_-]{35}'),
    "aws_access":       re.compile(r'AKIA[0-9A-Z]{16}'),
    "github_pat":       re.compile(r'ghp_[A-Za-z0-9]{36}'),
    "github_oauth":     re.compile(r'gho_[A-Za-z0-9]{36}'),
    "slack_bot":        re.compile(r'xox[baprs]-[A-Za-z0-9-]{20,}'),
    "priv_key":         re.compile(r'-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----'),
    "gitee_token_url":  re.compile(r'https?://[^:/@]+:[a-f0-9]{32}@gitee\.com'),
    "github_token_url": re.compile(r'https?://[^:/@]+:ghp_[A-Za-z0-9]{36}@github\.com'),
}

PLACEHOLDERS = ["your-", "your_", "YOUR-", "YOUR_", "xxx", "XXX", "example",
                "placeholder", "changeme", "here", "-here", "<...", "<your"]

SKIP_DIRS = {'.git', 'node_modules', '__pycache__', '.venv', 'venv', 'dist', 'build'}
SKIP_EXT = {'.png', '.jpg', '.jpeg', '.gif', '.pdf', '.mp4', '.mp3', '.wav',
            '.zip', '.tar', '.gz', '.woff', '.woff2', '.ttf', '.ico',
            '.min.js', '.min.css'}
SKIP_FILES = {'package-lock.json', 'yarn.lock'}

def is_placeholder(s):
    lo = s.lower()
    return any(p.lower() in lo for p in PLACEHOLDERS)

def scan(repo_dir):
    hits = []
    for root, dirs, files in os.walk(repo_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fn in files:
            if fn in SKIP_FILES or any(fn.endswith(e) for e in SKIP_EXT):
                continue
            p = Path(root) / fn
            try:
                if p.stat().st_size > 2_000_000:
                    continue
                with open(p, errors='ignore') as f:
                    for i, line in enumerate(f, 1):
                        for name, pat in PATTERNS.items():
                            m = pat.search(line)
                            if m and not is_placeholder(m.group(0)):
                                hits.append((str(p.relative_to(repo_dir)), i, name, m.group(0)[:80]))
            except Exception:
                continue
    return hits

if __name__ == "__main__":
    hits = scan(sys.argv[1])
    for rel, ln, name, val in hits:
        print(f"  🔴 {name}: {rel}:{ln}  {val}")
    if not hits:
        print("  🟢 clean")
    sys.exit(1 if hits else 0)
