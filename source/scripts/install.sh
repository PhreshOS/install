#!/usr/bin/env bash

set -euo pipefail

readonly node_channel="https://nodejs.org/dist/latest-v24.x"
readonly cli_package="@phreshos/cli@latest"

export LANG=C
export LC_ALL=C
export npm_config_update_notifier=false

fail() {

    printf '\nphresh: %s\n\n' "$1" >&2

    exit 1
}

command -v curl >/dev/null 2>&1 || fail "curl is required to download PhreshOS"

command -v tar >/dev/null 2>&1 || fail "tar is required to unpack the PhreshOS runtime"

case "$(uname -s)" in

    Darwin)

        readonly node_platform="darwin"

        readonly install_root="${HOME}/Library/Application Support/PhreshOS/Bootstrap"

        ;;

    Linux)

        readonly node_platform="linux"

        readonly install_root="${XDG_DATA_HOME:-${HOME}/.local/share}/phreshos/bootstrap"

        ;;

    *) fail "PhreshOS supports this installer only on Linux and macOS" ;;

esac

case "$(uname -m)" in

    x86_64 | amd64) readonly node_architecture="x64" ;;

    arm64 | aarch64) readonly node_architecture="arm64" ;;

    *) fail "PhreshOS does not support this processor architecture" ;;

esac

readonly temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/phreshos-install.XXXXXXXX")"

cleanup() {

    rm -rf -- "$temporary_directory"
}

trap cleanup EXIT

readonly checksums="$temporary_directory/SHASUMS256.txt"

curl -fsSL "$node_channel/SHASUMS256.txt" -o "$checksums"

readonly archive_suffix="-${node_platform}-${node_architecture}.tar.gz"

archive_name="$(awk -v suffix="$archive_suffix" 'index($2, suffix) == length($2) - length(suffix) + 1 { print $2; exit }' "$checksums")"

[[ "$archive_name" =~ ^node-v[0-9]+\.[0-9]+\.[0-9]+-${node_platform}-${node_architecture}\.tar\.gz$ ]] || fail "Node.js did not publish a compatible runtime"

readonly archive_name

expected_digest="$(awk -v name="$archive_name" '$2 == name { print $1; exit }' "$checksums")"

[[ "$expected_digest" =~ ^[a-f0-9]{64}$ ]] || fail "The Node.js checksum manifest is invalid"

readonly expected_digest

readonly runtime_name="${archive_name%.tar.gz}"
readonly runtime_root="$install_root/node/$runtime_name"

if [[ ! -x "$runtime_root/bin/node" ]]; then

    readonly archive="$temporary_directory/$archive_name"

    curl -fsSL "$node_channel/$archive_name" -o "$archive"

    if command -v shasum >/dev/null 2>&1; then

        actual_digest="$(shasum -a 256 "$archive" | awk '{ print $1 }')"

    elif command -v sha256sum >/dev/null 2>&1; then

        actual_digest="$(sha256sum "$archive" | awk '{ print $1 }')"

    else

        fail "SHA-256 verification is unavailable on this machine"

    fi

    [[ "$actual_digest" == "$expected_digest" ]] || fail "The downloaded Node.js runtime failed verification"

    readonly extracted="$temporary_directory/extracted"

    mkdir -p "$extracted" "$install_root/node"

    tar -xzf "$archive" -C "$extracted"

    [[ -x "$extracted/$runtime_name/bin/node" ]] || fail "The Node.js runtime archive is invalid"

    if [[ ! -e "$runtime_root" ]]; then

        mv "$extracted/$runtime_name" "$runtime_root"
    fi
fi

readonly node="$runtime_root/bin/node"
readonly npm="$runtime_root/lib/node_modules/npm/bin/npm-cli.js"
readonly cli_root="$install_root/cli"

[[ -x "$node" && -f "$npm" ]] || fail "The installed Node.js runtime is invalid"

"$node" "$npm" install --global --prefix "$cli_root" --no-audit --no-fund --loglevel=error "$cli_package"

readonly cli_entry="$cli_root/lib/node_modules/@phreshos/cli/dist/cli.js"

[[ -f "$cli_entry" ]] || fail "The published Phresh CLI is invalid"

readonly launcher_directory="${HOME}/.local/bin"
readonly launcher="$launcher_directory/phresh"
readonly pending_launcher="$temporary_directory/phresh"

mkdir -p "$launcher_directory"

printf '#!/usr/bin/env bash\nexport PATH=%q:"${PATH:-}"\nexec %q %q "$@"\n' "$runtime_root/bin" "$node" "$cli_entry" > "$pending_launcher"

chmod 755 "$pending_launcher"

mv "$pending_launcher" "$launcher"

case "${SHELL:-}" in

    */fish)

        profile="${HOME}/.config/fish/conf.d/phreshos.fish"

        path_line='fish_add_path --global "$HOME/.local/bin"'

        ;;

    */zsh)

        profile="${HOME}/.zshrc"

        path_line='export PATH="$HOME/.local/bin:$PATH"'

        ;;

    */bash)

        profile="${HOME}/.bashrc"

        path_line='export PATH="$HOME/.local/bin:$PATH"'

        ;;

    *)

        profile="${HOME}/.profile"

        path_line='export PATH="$HOME/.local/bin:$PATH"'

        ;;

esac

readonly profile path_line

mkdir -p "$(dirname "$profile")"

if [[ ! -f "$profile" ]] || ! grep -Fqx "$path_line" "$profile"; then

    printf '\n%s\n' "$path_line" >> "$profile"
fi

"$launcher" system install
