# Cicada (知了猴)

> CLAW Mesh / OpenClaw deployment entrypoint, Community Edition

`Cicada` is the entry layer for the broader `CLAW Mesh` stack.
It handles installation, configuration, startup, verification, updates, and basic operator actions so users can reach a working environment before they need to understand the full distributed control plane.

If `CLAW Mesh` is the control plane, `Cicada` is the deployment interface that gets people into the system.

## Positioning

- `CLAW Mesh`: routing, scheduling, governance, memory, and execution
- `Cicada`: installation, configuration, startup, connection testing, updates, and basic operations

`Cicada` solves the entry problem.
It does not replace the control plane.

## What It Does

- **One-click install**: environment detection, Node.js setup, OpenClaw setup, and guided onboarding
- **Model presets**: Doubao, DeepSeek, Kimi, GLM, Qwen, Ollama, and other common providers
- **Skill store**: browse, search, and install ClawHub skills
- **Dashboard**: service status polling, start and stop controls, and quick access to Web UI
- **Connection testing**: validate API and service settings before use
- **Auto updates**: check GitHub Releases and pull in the latest version

## Typical User Path

1. Download and launch `Cicada`
2. Run environment checks and install dependencies
3. Configure models and basic connectivity
4. Start local services and verify health
5. Enter the `CLAW Mesh / OpenClaw` runtime environment

This keeps the first experience focused on usability instead of infrastructure complexity.

## Download

From [Releases](https://github.com/2233admin/cicada/releases):

- Windows: `cicada-windows.zip`
- macOS / Linux: coming later

## Development

```bash
flutter pub get
flutter run -d windows
```

## Build

```bash
flutter build windows --release
```

## Tech Stack

Flutter 3.29 + Dart 3.7 + Material 3

## Editions

| Edition | Audience | Stack |
|---|---|---|
| **Cicada Community** | general users, developers, independent operators | Flutter Desktop |
| **Cicada Enterprise** | enterprise intranet, offline environments, controlled deployments | Tauri + React + Rust |

## License

GPL 3.0
