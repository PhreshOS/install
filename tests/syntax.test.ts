import { execFileSync } from "node:child_process"
import { test } from "vitest"

test.skipIf(process.platform === "win32")("shell bootstrap has valid syntax", () => {
  execFileSync("bash", ["-n", "source/scripts/install.sh"], { stdio: "pipe" })
})

test.skipIf(process.platform !== "win32")("PowerShell bootstrap and installation test have valid syntax", () => {
  execFileSync("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "tests/powershell.ps1"], { stdio: "pipe" })
})
