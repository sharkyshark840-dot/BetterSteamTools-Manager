param([switch]$Preview,[string]$CapturePath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $Preview -and -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try { Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList ('-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $PSCommandPath + '"') }
    catch { [Windows.Forms.MessageBox]::Show('Administrator access is needed to change files in the Steam folder.','BetterSteamTools Manager') | Out-Null }
    exit
}
. "$PSScriptRoot\Core.ps1"
$script:steam = Get-SteamFolder
$bg = [Drawing.ColorTranslator]::FromHtml('#10141E')
$panel = [Drawing.ColorTranslator]::FromHtml('#1B2332')
$muted = [Drawing.ColorTranslator]::FromHtml('#9BAAC0')
$cyan = [Drawing.ColorTranslator]::FromHtml('#63E3CE')
$form = New-Object Windows.Forms.Form
$form.Text = 'BetterSteamTools Manager'
$form.ClientSize = New-Object Drawing.Size(820,650)
$form.MinimumSize = New-Object Drawing.Size(836,689)
$form.MaximumSize = $form.MinimumSize
$form.StartPosition = 'CenterScreen'
$form.BackColor = $bg
$form.ForeColor = [Drawing.Color]::White
$form.Font = New-Object Drawing.Font('Segoe UI',10)
if (Test-Path "$PSScriptRoot\assets\manager.ico") { $form.Icon = New-Object Drawing.Icon("$PSScriptRoot\assets\manager.ico") }
function Label($text,$x,$y,$w,$h,$size=10,$color=[Drawing.Color]::White) {
    $c = New-Object Windows.Forms.Label
    $c.Text=$text; $c.SetBounds($x,$y,$w,$h); $c.Font=New-Object Drawing.Font('Segoe UI',$size); $c.ForeColor=$color
    $form.Controls.Add($c); return $c
}
function Button($text,$x,$y,$w,$color) {
    $b=New-Object Windows.Forms.Button
    $b.Text=$text; $b.SetBounds($x,$y,$w,42); $b.BackColor=$color; $b.ForeColor=[Drawing.Color]::White
    $b.FlatStyle='Flat'; $b.FlatAppearance.BorderSize=0; $b.Cursor='Hand'
    $form.Controls.Add($b); return $b
}
$logo=New-Object Windows.Forms.PictureBox
$logo.SetBounds(30,28,58,58); $logo.SizeMode='Zoom'
if (Test-Path "$PSScriptRoot\assets\manager.png") { $logo.Image=[Drawing.Image]::FromFile("$PSScriptRoot\assets\manager.png") }
$form.Controls.Add($logo)
$null=Label 'BetterSteamTools' 104 24 650 40 25
$null=Label 'MANAGER  /  WINDOWS' 107 68 600 25 9 $cyan
$null=Label 'Your setup. Always recoverable.' 30 112 740 32 17
$null=Label 'Remove the add-on or bring it back from a saved backup.' 30 150 750 25 10 $muted
$null=Label 'STEAM FOLDER' 30 197 400 20 9 $muted
$path=New-Object Windows.Forms.TextBox
$path.SetBounds(30,222,638,30); $path.ReadOnly=$true; $path.BackColor=$panel; $path.ForeColor=[Drawing.Color]::White; $path.BorderStyle='FixedSingle'
$form.Controls.Add($path)
$browse=Button 'Browse...' 680 217 110 $panel
$status=Label '' 30 268 750 27 11 $cyan
$uninstall=Button 'Uninstall + back up' 30 310 240 ([Drawing.ColorTranslator]::FromHtml('#4258B8'))
$open=Button 'Open Steam folder' 284 310 220 $panel
$refresh=Button 'Refresh' 518 310 130 $panel
$null=Label 'SAVED BACKUPS' 30 385 600 23 9 $muted
$list=New-Object Windows.Forms.ListBox
$list.SetBounds(30,414,760,102); $list.BackColor=$panel; $list.ForeColor=[Drawing.Color]::White; $list.BorderStyle='None'; $list.ItemHeight=25; $list.IntegralHeight=$false
$list.DisplayMember='Display'; $form.Controls.Add($list)
$restore=Button 'Restore selected backup' 30 532 250 ([Drawing.ColorTranslator]::FromHtml('#267B72'))
$null=Label 'Backups are kept after restoring.' 300 544 480 24 10 $muted
$message=Label 'Ready. Close Steam before uninstalling or restoring.' 30 596 760 40 10 $muted
function Refresh-View {
    $path.Text=$script:steam
    $installed=Test-Path -LiteralPath (Join-Path $script:steam 'OpenSteamTool.dll')
    if ($installed) { $status.Text='ADD-ON DETECTED'; $uninstall.Enabled=-not $Preview } else { $status.Text='UNINSTALLED  /  Steam is ready'; $uninstall.Enabled=$false }
    $list.Items.Clear()
    foreach ($b in Get-ToolBackups $script:steam) {
        $display=$b.Name
        if ($b.Name -match '(\d{8})-(\d{6})') {
            $date=[datetime]::ParseExact(($Matches[1]+$Matches[2]),'yyyyMMddHHmmss',[Globalization.CultureInfo]::InvariantCulture)
            $display=$date.ToString('MMM dd, yyyy  -  h:mm:ss tt') + '    |    ' + $b.Name
        }
        $null=$list.Items.Add([pscustomobject]@{ Display=$display; Path=$b.FullName })
    }
    if ($list.Items.Count) { $list.SelectedIndex=0 }
    $restore.Enabled=($list.Items.Count -gt 0 -and -not $Preview)
}
function Run-Action([scriptblock]$Action) {
    $form.UseWaitCursor=$true
    try { & $Action; Refresh-View }
    catch { $message.Text=$_.Exception.Message; [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Action could not finish','OK','Warning') | Out-Null }
    finally { $form.UseWaitCursor=$false }
}
$browse.Add_Click({
    $dialog=New-Object Windows.Forms.FolderBrowserDialog
    $dialog.Description='Choose the folder containing steam.exe'; $dialog.SelectedPath=$script:steam
    if ($dialog.ShowDialog() -eq 'OK') {
        if (Test-Path -LiteralPath (Join-Path $dialog.SelectedPath 'steam.exe')) { $script:steam=$dialog.SelectedPath; Refresh-View }
        else { $message.Text='That folder does not contain steam.exe.' }
    }
    $dialog.Dispose()
})
$refresh.Add_Click({ Refresh-View })
$open.Add_Click({ Start-Process explorer.exe -ArgumentList ('"' + $script:steam + '"') })
$uninstall.Add_Click({ Run-Action { $saved=Uninstall-Tool $script:steam; $message.Text='Uninstalled. Backup: ' + (Split-Path $saved -Leaf) } })
$restore.Add_Click({
    if ($list.SelectedItem) { Run-Action { Restore-Tool $script:steam $list.SelectedItem.Path; $message.Text='Restored successfully. Your saved backup has been kept.' } }
})
Refresh-View
if ($CapturePath -and $Preview) {
    $form.Add_Shown({
        $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height)
        $form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)))
        $bitmap.Save($CapturePath,[Drawing.Imaging.ImageFormat]::Png)
        $bitmap.Dispose()
        $form.Close()
    })
}
$null=$form.ShowDialog()
$form.Dispose()
