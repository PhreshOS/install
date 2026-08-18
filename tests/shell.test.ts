import { afterAll, describe, expect, test } from "bun:test"
import { createHash } from "node:crypto"
import { chmod, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { spawnSync } from "node:child_process"

const describeUnix = process.platform === "win32" ? describe.skip : describe

describeUnix("shell bootstrap", function () {

    const created: string[] = []

    afterAll(async function () {

        await Promise.all(created.map(path => rm(path, { recursive: true, force: true })))
    })

    test("installs from verified bytes and remains safe to run again", async function () {

        const root = await mkdtemp(join(tmpdir(), "phreshos install "))

        created.push(root)

        const home = join(root, "person")
        const commands = join(root, "commands")
        const temporary = join(root, "temporary")
        const curlLog = join(root, "curl.log")
        const installLog = join(root, "install.log")
        const fakeNode = join(root, "node")

        await Promise.all([mkdir(home), mkdir(commands), mkdir(temporary)])

        const archive = "archive\n"
        const digest = createHash("sha256").update(archive).digest("hex")

        await executable(join(commands, "uname"), `#!/bin/sh
if [ "$1" = "-s" ]; then printf 'Darwin\\n'; else printf 'arm64\\n'; fi
`)

        await executable(join(commands, "curl"), `#!/bin/sh
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o) output="$2"; shift 2 ;;
        http*) url="$1"; shift ;;
        *) shift ;;
    esac
done
printf '%s\\n' "$url" >> "$CURL_LOG"
case "$url" in
    */SHASUMS256.txt) printf '%s  node-v24.99.1-darwin-arm64.tar.gz\\n' "$EXPECTED_DIGEST" > "$output" ;;
    *) printf 'archive\\n' > "$output" ;;
esac
`)

        await executable(fakeNode, `#!/bin/sh
case "$1" in
    */npm-cli.js)
        shift
        while [ "$#" -gt 0 ]; do
            if [ "$1" = "--prefix" ]; then prefix="$2"; break; fi
            shift
        done
        entry="$prefix/lib/node_modules/@phreshos/cli/dist/cli.js"
        mkdir -p "$(dirname "$entry")"
        printf 'export {}\\n' > "$entry"
        ;;
    *) printf '%s\\n' "$*" >> "$INSTALL_LOG" ;;
esac
`)

        await executable(join(commands, "tar"), `#!/bin/sh
while [ "$#" -gt 0 ]; do
    if [ "$1" = "-C" ]; then destination="$2"; break; fi
    shift
done
runtime="$destination/node-v24.99.1-darwin-arm64"
mkdir -p "$runtime/bin" "$runtime/lib/node_modules/npm/bin"
cp "$FAKE_NODE" "$runtime/bin/node"
chmod 755 "$runtime/bin/node"
printf 'export {}\\n' > "$runtime/lib/node_modules/npm/bin/npm-cli.js"
`)

        const script = join(dirname(dirname(fileURLToPath(import.meta.url))), "source", "scripts", "install.sh")
        const environment = {

            HOME: home,

            SHELL: "/bin/zsh",

            TMPDIR: temporary,

            PATH: `${commands}:/usr/bin:/bin:/usr/sbin:/sbin`,

            CURL_LOG: curlLog,

            INSTALL_LOG: installLog,

            EXPECTED_DIGEST: digest,

            FAKE_NODE: fakeNode
        }

        run(script, environment)

        run(script, environment)

        const calls = (await readFile(curlLog, "utf8")).trim().split("\n")

        expect(calls.filter(call => call.endsWith(".tar.gz"))).toHaveLength(1)

        const installs = (await readFile(installLog, "utf8")).trim().split("\n")

        expect(installs).toHaveLength(2)

        expect(installs.every(value => value.endsWith(" system install"))).toBe(true)

        const profile = await readFile(join(home, ".zshrc"), "utf8")

        expect(profile.match(/export PATH=/g)).toHaveLength(1)
    })
})

async function executable(path: string, content: string) {

    await writeFile(path, content)

    await chmod(path, 0o755)
}

function run(script: string, environment: Record<string, string>) {

    const result = spawnSync("/bin/bash", [script], {

        env: environment,

        encoding: "utf8"
    })

    expect(result.status, result.stderr).toBe(0)
}
