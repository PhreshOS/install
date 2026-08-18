# PhreshOS Install

The official clean-machine bootstrap for PhreshOS.

## Install

Linux and macOS:

```sh
curl -fsSL https://install.phreshos.com/sh | bash
```

Windows:

```powershell
powershell -c "irm https://install.phreshos.com/ps1 | iex"
```

Each endpoint detects its platform and architecture, acquires a verified
Node.js runtime, installs the published Phresh CLI, and delegates System setup
to `phresh system install`. The bootstrap does not duplicate System
installation or service policy owned by the CLI.

The scripts are safe to run again. They do not require Node.js, Bun, npm, or
Git to be installed in advance.

## Development

```sh
bun install
bun run check
```

`bun run deploy` publishes the Worker after both platform paths are supported
by released PhreshOS components. Source availability alone does not make an
endpoint a supported release.

## License

[MIT](LICENSE)
