$Errors = $null
$Tokens = $null
$Path = Join-Path $PSScriptRoot "..\source\scripts\install.ps1"

[Management.Automation.Language.Parser]::ParseFile($Path, [ref] $Tokens, [ref] $Errors) | Out-Null

if ($Errors.Count -gt 0) {

    $Errors | ForEach-Object { Write-Error $_.Message }

    exit 1
}
