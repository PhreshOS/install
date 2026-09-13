import process from "node:process"
import { execFileSync } from "node:child_process"
import { test } from "vitest"

// This explicitly selected test installs and removes a real user-level System.
test.skipIf(process.platform !== "win32")("Windows bootstrap installs a working System", () => {
  execFileSync("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "tests/windows-install.ps1"], {
    // Rebuild Windows PowerShell paths instead of inheriting PowerShell 7 modules through Node.
    env: Object.fromEntries(Object.entries(process.env).filter((entry): entry is [string, string] => entry[0].toLowerCase() !== "psmodulepath" && typeof entry[1] === "string")),
    stdio: "inherit",
    timeout: 600_000
  })
}, 660_000)
