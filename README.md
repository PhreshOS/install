# PhreshOS Install

The official clean-machine bootstrap for PhreshOS.

The bootstrap acquires the required runtime, installs the published CLI, and
delegates System installation and service management to `phresh`.

## Installation

Linux and macOS:

```sh
curl -fsSL https://install.phreshos.com/sh | bash
```

Windows PowerShell:

```powershell
irm https://install.phreshos.com/ps1 | iex
```

The bootstrap detects the host platform and architecture, acquires a verified
Node.js runtime, installs `@phreshos/cli`, and runs `phresh system install`.
It does not require Node.js, a package manager, or Git to be installed first.

The scripts are safe to run again.

## Development

```sh
bun install --frozen-lockfile
bun run check
```

Run the local Worker with:

```sh
bun run dev
```

Build or deploy it with:

```sh
bun run build
bun run deploy
```

`check` verifies the TypeScript, tests, shell script, and Worker build.

## Repository boundary

This repository owns only clean-machine bootstrap and delivery of its platform
scripts. The CLI owns System acquisition, verification, installation, updates,
and native service policy.

## License

Licensed under the [MIT License](LICENSE). Copyright © 2026 Zohayr SLILEH.
