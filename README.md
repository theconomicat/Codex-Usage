# Codex-Usage

![Codex-Usage icon](Assets/AppIcon.svg)

[한국어 README](README.ko.md)

macOS menu bar usage meter for OpenAI Codex.

![Codex-Usage menu bar preview](docs/menu-bar-preview.png)

Codex-Usage reads local Codex session logs from `~/.codex` and keeps remaining
5-hour and weekly quota visible directly in the menu bar. You do not need to
click the menu bar item to see the numbers. It is local-only and does not read
Codex auth tokens.

## What It Shows

The menu bar item is two compact circular gauges. The number inside each ring is
remaining quota:

```text
(79)   (96)
```

Left: 5-hour window. Right: weekly window.

Clicking the item opens a compact menu:

```text
5h · 79% · reset 2h
1w · 96% · reset 6d

Refresh
Quit Codex-Usage
```


## Data Source

Codex-Usage reads only known local Codex usage logs:

```text
~/.codex/sessions/**/*.jsonl
~/.codex/archived_sessions/*.jsonl
```

It looks for `event_msg` entries where `payload.type == "token_count"` and reads
`payload.rate_limits.primary` and `payload.rate_limits.secondary`.

It does not read `~/.codex/auth.json`.

## Install From Source

Requirements:

- macOS 13+
- Xcode command line tools
- OpenAI Codex app or CLI already used on this Mac

Build and open the app:

```bash
git clone https://github.com/YOUR_NAME/Codex-Usage.git
cd Codex-Usage
./Scripts/package_app.sh
open ./Codex-Usage.app
```

To keep it installed, move `Codex-Usage.app` to `/Applications`.

## Releases

Pushing a version tag builds the app on GitHub Actions and uploads
`Codex-Usage-macos.zip` to a GitHub Release automatically.

```bash
git tag v0.1.0
git push origin v0.1.0
```

To build the same zip locally:

```bash
./Scripts/package_app.sh
ditto -c -k --norsrc --keepParent Codex-Usage.app Codex-Usage-macos.zip
```

## Development

Print the latest local usage without opening the menu bar app:

```bash
swift run CodexUsage -- --print
```

Run tests:

```bash
swift test
```

Build an app bundle:

```bash
./Scripts/package_app.sh
open ./Codex-Usage.app
```

## Notes

The Codex local JSONL format is not a public API, so this project treats parsing
as best-effort and keeps the reader small and easy to update.

## License

MIT
