$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
& $compiler /nologo /target:winexe /optimize+ /reference:System.Windows.Forms.dll "/win32icon:$root\assets\manager.ico" "/out:$root\BetterSteamTools-Manager.exe" "$PSScriptRoot\Launcher.cs"
if ($LASTEXITCODE -ne 0) { throw 'Launcher build failed.' }
$process = Start-Process -FilePath "$root\BetterSteamTools-Manager.exe" -ArgumentList '--check' -PassThru -Wait
if ($process.ExitCode -ne 0) { throw 'Launcher dependency check failed.' }
Write-Host 'Built BetterSteamTools-Manager.exe; dependency check passed.'
