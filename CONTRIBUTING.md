# Contributing

Thanks for helping improve Codex-Usage.

Keep changes small. This app intentionally does one thing: show local Codex
usage in the macOS menu bar.

## Development

```bash
swift test
./Scripts/package_app.sh
open ./Codex-Usage.app
```

## Pull Requests

- Explain what changed and why.
- Add or update a focused test when parser behavior changes.
- Do not read or print `~/.codex/auth.json`.
- Keep UI changes minimal.
