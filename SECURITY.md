# Security

Codex-Usage reads local Codex session logs from:

```text
~/.codex/sessions/**/*.jsonl
~/.codex/archived_sessions/*.jsonl
```

It should not read `~/.codex/auth.json`, browser cookies, keychain items, or API
keys.

If you find a security issue, please open a private report if the repository has
GitHub private vulnerability reporting enabled. Otherwise, open an issue without
including secrets or sensitive local paths.
