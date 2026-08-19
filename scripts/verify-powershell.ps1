$Paths = @(

    (Join-Path $PSScriptRoot "..\source\scripts\install.ps1"),

    (Join-Path $PSScriptRoot "verify-windows-install.ps1")
)

foreach ($Path in $Paths) {

    $Errors = $null

    $Tokens = $null

    [Management.Automation.Language.Parser]::ParseFile($Path, [ref] $Tokens, [ref] $Errors) | Out-Null

    if ($Errors.Count -gt 0) {

        $Errors | ForEach-Object { Write-Error $_.Message }

        exit 1
    }
}
