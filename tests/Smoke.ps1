$ErrorActionPreference='Stop'
. "$PSScriptRoot\..\Core.ps1"
function Assert-SteamClosed { }
$testParent=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$root=Join-Path $testParent ('bst-manager-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    New-Item -ItemType Directory -Path "$root\config\stplug-in" -Force | Out-Null
    New-Item -ItemType Directory -Path "$root\opensteamtool" | Out-Null
    Set-Content "$root\OpenSteamTool.dll" 'test fixture BetterSteamTools'
    Set-Content "$root\dwmapi.dll" 'test loader'
    Set-Content "$root\config\stplug-in\test.lua" 'test config'
    Set-Content "$root\opensteamtool\test.txt" 'test data'
    $backup=Uninstall-Tool $root
    if (Test-Path "$root\OpenSteamTool.dll") { throw 'Uninstall did not remove main file.' }
    if (-not (Test-Path "$backup\stplug-in\test.lua")) { throw 'Configuration was not backed up.' }
    Restore-Tool $root $backup
    if (-not (Test-Path "$root\config\stplug-in\test.lua")) { throw 'Configuration was not restored.' }
    if (-not (Test-Path "$backup\OpenSteamTool.dll")) { throw 'Restore did not retain backup.' }
    $blocked=$false
    try { Restore-Tool $root $backup } catch { $blocked=$true }
    if (-not $blocked) { throw 'Restore allowed an overwrite.' }
    $blocked=$false
    try { Get-ComponentPath $root '..\outside' } catch { $blocked=$true }
    if (-not $blocked) { throw 'Path traversal was allowed.' }
    Write-Host 'PASS: uninstall, timestamped backup, nested restore, backup retention, overwrite protection, path validation.'
} finally {
    if ($root.StartsWith($testParent.TrimEnd('\') + '\bst-manager-test-')) { Remove-Item -LiteralPath $root -Recurse -Force }
}
