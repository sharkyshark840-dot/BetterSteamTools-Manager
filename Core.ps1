$ErrorActionPreference = 'Stop'
$script:Components = @('OpenSteamTool.dll','opensteamtool.toml','dwmapi.dll','xinput1_4.dll','opensteamtool','config\stplug-in')
function Get-SteamFolder {
    $reg = Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
    if ($reg.SteamPath -and (Test-Path -LiteralPath (Join-Path $reg.SteamPath 'steam.exe'))) { return [IO.Path]::GetFullPath($reg.SteamPath) }
    return 'C:\Program Files (x86)\Steam'
}
function Get-ComponentPath([string]$Root,[string]$Name) {
    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $path = [IO.Path]::GetFullPath((Join-Path $rootPath $Name))
    if (-not $path.StartsWith($rootPath + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid component path.' }
    return $path
}
function Assert-NoLinks([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked paths are not supported: $Path" }
    if ($item.PSIsContainer) {
        foreach ($child in Get-ChildItem -LiteralPath $Path -Force) { Assert-NoLinks $child.FullName }
    }
}
function Assert-SteamClosed {
    if (Get-Process steam -ErrorAction SilentlyContinue) { throw 'Please exit Steam, then try again.' }
}
function Assert-Parent([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    while ($item) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked parent paths are not supported: $($item.FullName)" }
        $item = $item.Parent
    }
}
function Assert-Tool([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'The BetterSteamTools main file is missing.' }
    $text = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($Path))
    if ($text -notmatch 'BetterSteamTools') { throw 'The main file could not be identified as BetterSteamTools.' }
}
function Get-ToolBackups([string]$Root) {
    @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^BetterSteamTools-(uninstalled|backup)-' } | Sort-Object Name -Descending)
}
function Uninstall-Tool([string]$Root) {
    Assert-SteamClosed
    Assert-Parent $Root
    Assert-Tool (Get-ComponentPath $Root 'OpenSteamTool.dll')
    $backup = Get-ComponentPath $Root ('BetterSteamTools-uninstalled-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    $moved = New-Object System.Collections.Generic.List[string]
    foreach ($name in $script:Components) {
        $source = Get-ComponentPath $Root $name
        if (Test-Path -LiteralPath $source) { Assert-Parent (Split-Path $source -Parent); Assert-NoLinks $source }
    }
    New-Item -ItemType Directory -Path $backup | Out-Null
    try {
        foreach ($name in $script:Components) {
            $source = Get-ComponentPath $Root $name
            if (Test-Path -LiteralPath $source) {
                Move-Item -LiteralPath $source -Destination (Join-Path $backup (Split-Path $name -Leaf))
                $moved.Add($name)
            }
        }
    } catch {
        $failure = $_
        foreach ($name in $moved) {
            Move-Item -LiteralPath (Join-Path $backup (Split-Path $name -Leaf)) -Destination (Get-ComponentPath $Root $name)
        }
        throw $failure
    }
    return $backup
}
function Restore-Tool([string]$Root,[string]$Backup) {
    Assert-SteamClosed
    $valid = @(Get-ToolBackups $Root | Where-Object { $_.FullName -eq [IO.Path]::GetFullPath($Backup) })
    if ($valid.Count -ne 1) { throw 'Choose a backup from this Steam folder.' }
    Assert-NoLinks $Backup
    Assert-Tool (Join-Path $Backup 'OpenSteamTool.dll')
    $available = @($script:Components | Where-Object { Test-Path -LiteralPath (Join-Path $Backup (Split-Path $_ -Leaf)) })
    foreach ($name in $available) {
        $target = Get-ComponentPath $Root $name
        if (Test-Path -LiteralPath $target) { throw "$name already exists. Uninstall the current copy before restoring." }
        $parent = Split-Path $target -Parent
        Assert-Parent $parent
    }
    $copied = New-Object System.Collections.Generic.List[string]
    try {
        foreach ($name in $available) {
            $target = Get-ComponentPath $Root $name
            $copied.Add($name)
            Copy-Item -LiteralPath (Join-Path $Backup (Split-Path $name -Leaf)) -Destination $target -Recurse
        }
    } catch {
        $failure = $_
        foreach ($name in $copied) {
            $target = Get-ComponentPath $Root $name
            if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        }
        throw $failure
    }
}
