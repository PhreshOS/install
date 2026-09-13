import { execFileSync } from "node:child_process"
import { test } from "vitest"

// This explicitly selected test installs and removes a real user-level System.
test.skipIf(process.platform !== "win32")("Windows bootstrap installs a working System", () => {
  execFileSync("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "tests/windows-install.ps1"], {
    stdio: "inherit",
    timeout: 600_000
  })
}, 660_000)
