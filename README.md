# PhreshOS Install

The clean-machine bootstrap for the official PhreshOS CLI and System.

[Installation guide](https://docs.phreshos.com/installation) ·
[CLI](https://docs.phreshos.com/sdks/cli) ·
[Source](https://github.com/PhreshOS/install)

## Role

This repository detects the host platform and architecture, acquires a verified
Node.js runtime, installs `@phreshos/cli`, and delegates System installation and
native service policy to `phresh system install`.

It owns only clean-machine bootstrap and delivery of the platform scripts. The
CLI owns all behavior after it is available.

## Installation

Linux and macOS:

```sh
curl -fsSL https://install.phreshos.com/sh | bash
```

Windows PowerShell:

```powershell
irm https://install.phreshos.com/ps1 | iex
```

The bootstrap does not require Node.js, a package manager, or Git to be
installed first, and it is safe to run again. See the
[installation guide](https://docs.phreshos.com/installation) for requirements
and System lifecycle commands.

## Development

```sh
bun install --frozen-lockfile
bun run check
bun run dev
```

Build or deploy the Worker with:

```sh
bun run build
bun run deploy
```

`check` verifies the TypeScript, tests, shell script, and Worker build.

## Related repositories

- [`@phreshos/cli`](https://github.com/PhreshOS/cli) owns System acquisition,
  installation, updates, and native service management.
- [PhreshOS System](https://github.com/PhreshOS/system) provides the release
  installed by the CLI.
- [PhreshOS Documentation](https://github.com/PhreshOS/docs) owns the canonical
  installation workflow.

## License

Licensed under the [MIT License](LICENSE). Copyright © 2026 Zohayr SLILEH.
