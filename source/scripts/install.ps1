$ErrorActionPreference = "Stop"

$NodeChannel = "https://nodejs.org/dist/latest-v24.x"
$CliPackage = "@phreshos/cli@latest"

if ([Environment]::Is64BitOperatingSystem -ne $true) {

    throw "PhreshOS requires a 64-bit Windows installation"
}

$NodeArchitecture = switch ($env:PROCESSOR_ARCHITECTURE) {

    "AMD64" { "x64" }

    "ARM64" { "arm64" }

    default { throw "PhreshOS does not support this processor architecture" }
}

$UserHome = [Environment]::GetFolderPath("UserProfile")
$LocalData = [Environment]::GetFolderPath("LocalApplicationData")

if ([string]::IsNullOrWhiteSpace($UserHome) -or [string]::IsNullOrWhiteSpace($LocalData)) {

    throw "The current Windows user directories could not be resolved"
}

$InstallRoot = Join-Path $LocalData "PhreshOS\Bootstrap"
$TemporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("phreshos-install-" + [Guid]::NewGuid().ToString("N"))

New-Item -ItemType Directory -Path $TemporaryDirectory | Out-Null

try {

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $Checksums = Invoke-RestMethod -Uri "$NodeChannel/SHASUMS256.txt" -UseBasicParsing

    $Suffix = "-win-$NodeArchitecture.zip"

    $Match = [regex]::Match($Checksums, "(?m)^([a-f0-9]{64})\s+(node-v[0-9]+\.[0-9]+\.[0-9]+-win-$NodeArchitecture\.zip)$")

    if (-not $Match.Success -or -not $Match.Groups[2].Value.EndsWith($Suffix)) {

        throw "Node.js did not publish a compatible runtime"
    }

    $ExpectedDigest = $Match.Groups[1].Value.ToLowerInvariant()
    $ArchiveName = $Match.Groups[2].Value
    $RuntimeName = $ArchiveName.Substring(0, $ArchiveName.Length - 4)
    $RuntimeParent = Join-Path $InstallRoot "node"
    $RuntimeRoot = Join-Path $RuntimeParent $RuntimeName

    if (-not (Test-Path -LiteralPath (Join-Path $RuntimeRoot "node.exe") -PathType Leaf)) {

        $Archive = Join-Path $TemporaryDirectory $ArchiveName

        Invoke-WebRequest -Uri "$NodeChannel/$ArchiveName" -OutFile $Archive -UseBasicParsing

        $ActualDigest = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()

        if ($ActualDigest -ne $ExpectedDigest) {

            throw "The downloaded Node.js runtime failed verification"
        }

        $Extracted = Join-Path $TemporaryDirectory "extracted"

        New-Item -ItemType Directory -Path $Extracted | Out-Null

        Expand-Archive -LiteralPath $Archive -DestinationPath $Extracted

        $ExtractedRuntime = Join-Path $Extracted $RuntimeName

        if (-not (Test-Path -LiteralPath (Join-Path $ExtractedRuntime "node.exe") -PathType Leaf)) {

            throw "The Node.js runtime archive is invalid"
        }

        New-Item -ItemType Directory -Path $RuntimeParent -Force | Out-Null

        if (-not (Test-Path -LiteralPath $RuntimeRoot)) {

            Move-Item -LiteralPath $ExtractedRuntime -Destination $RuntimeRoot
        }
    }

    $Node = Join-Path $RuntimeRoot "node.exe"
    $Npm = Join-Path $RuntimeRoot "node_modules\npm\bin\npm-cli.js"
    $CliRoot = Join-Path $InstallRoot "cli"

    if (-not (Test-Path -LiteralPath $Node -PathType Leaf) -or -not (Test-Path -LiteralPath $Npm -PathType Leaf)) {

        throw "The installed Node.js runtime is invalid"
    }

    & $Node $Npm install --global --prefix $CliRoot --no-audit --no-fund --loglevel=error $CliPackage

    if ($LASTEXITCODE -ne 0) {

        throw "The published Phresh CLI could not be installed"
    }

    $CliEntry = Join-Path $CliRoot "node_modules\@phreshos\cli\dist\cli.js"

    if (-not (Test-Path -LiteralPath $CliEntry -PathType Leaf)) {

        throw "The published Phresh CLI is invalid"
    }

    $LauncherDirectory = Join-Path $LocalData "PhreshOS\bin"
    $Launcher = Join-Path $LauncherDirectory "phresh.cmd"

    New-Item -ItemType Directory -Path $LauncherDirectory -Force | Out-Null

    $LauncherContent = "@echo off`r`n`"$Node`" `"$CliEntry`" %*`r`n"

    Set-Content -LiteralPath $Launcher -Value $LauncherContent -Encoding Ascii

    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $PathParts = @($UserPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    if ($PathParts -notcontains $LauncherDirectory) {

        $UpdatedPath = (@($PathParts) + $LauncherDirectory) -join ";"

        [Environment]::SetEnvironmentVariable("Path", $UpdatedPath, "User")
    }

    & $Launcher system install

    if ($LASTEXITCODE -ne 0) {

        throw "PhreshOS System installation failed"
    }
}

finally {

    Remove-Item -LiteralPath $TemporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
}
