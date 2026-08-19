$ErrorActionPreference = "Stop"

$Install = Join-Path $PSScriptRoot "..\source\scripts\install.ps1"
$Launcher = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "PhreshOS\bin\phresh.cmd"

try {

    & $Install

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Launcher -PathType Leaf)) {

        throw "The Windows bootstrap did not install the Phresh CLI"
    }

    $Status = (& $Launcher system status 2>&1 | Out-String)

    if ($LASTEXITCODE -ne 0) {

        throw "The installed PhreshOS System did not report its status"
    }

    foreach ($Expected in @("desktop", "http://localhost:4300", "service", "ready", "startup", "enabled")) {

        if (-not $Status.Contains($Expected)) throw "The installed PhreshOS System status is incomplete: $Status"
    }

    $Desktop = Invoke-WebRequest -Uri "http://localhost:4300/" -UseBasicParsing

    if ($Desktop.StatusCode -ne 200 -or -not $Desktop.Content.Contains("<html")) {

        throw "The installed PhreshOS desktop is not available"
    }

    Write-Host "Verified a clean Windows PhreshOS installation"
}

finally {

    if (Test-Path -LiteralPath $Launcher -PathType Leaf) {

        & $Launcher system uninstall
    }
}
