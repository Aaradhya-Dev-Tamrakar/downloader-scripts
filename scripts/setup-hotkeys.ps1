<#
.SYNOPSIS
    Installs global Windows shortcuts and PowerShell profile aliases for zero-click downloading.
#>

$ScriptDir = $PSScriptRoot
$RepoRoot = Split-Path -Parent $ScriptDir
$AudioScript = Join-Path $ScriptDir "clipboard-downloader.ps1"

# 1. Create Desktop / Start Menu Quick Shortcuts
$WshShell = New-Object -ComObject WScript.Shell
$DesktopPath = [System.Environment]::GetFolderPath("Desktop")

# Music Shortcut (Win + Alt + M equivalent shortcut)
$MusicShortcutPath = Join-Path $DesktopPath "Download Music (Clipboard).lnk"
$ShortcutM = $WshShell.CreateShortcut($MusicShortcutPath)
$ShortcutM.TargetPath = "powershell.exe"
$ShortcutM.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$AudioScript`" -Mode audio"
$ShortcutM.IconLocation = "shell32.dll,116" # Music / Audio note icon
$ShortcutM.Hotkey = "CTRL+ALT+M"
$ShortcutM.Description = "Download audio from YouTube URL in Clipboard to Music"
$ShortcutM.Save()

# Video Shortcut (Win + Alt + V equivalent shortcut)
$VideoShortcutPath = Join-Path $DesktopPath "Download Video (Clipboard).lnk"
$ShortcutV = $WshShell.CreateShortcut($VideoShortcutPath)
$ShortcutV.TargetPath = "powershell.exe"
$ShortcutV.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$AudioScript`" -Mode video"
$ShortcutV.IconLocation = "shell32.dll,115" # Film / Video reel icon
$ShortcutV.Hotkey = "CTRL+ALT+V"
$ShortcutV.Description = "Download 1080p/720p video from YouTube URL in Clipboard to Videos\yt-dlp"
$ShortcutV.Save()

# 2. Add helper aliases to PowerShell $PROFILE
$ProfileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

$ProfileSnippet = @"

# --- Downloader Scripts Zero-Click Integration ---
function dlm { & "$AudioScript" -Mode audio @args }
function dlv { & "$AudioScript" -Mode video @args }
# -------------------------------------------------
"@

if (Test-Path $PROFILE) {
    $existing = Get-Content $PROFILE -Raw
    if ($existing -notmatch "Downloader Scripts Zero-Click Integration") {
        Add-Content -Path $PROFILE -Value $ProfileSnippet
    }
} else {
    Set-Content -Path $PROFILE -Value $ProfileSnippet
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  ZERO-CLICK DOWNLOADER CONFIGURED SUCCESSFULLY" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Desktop Shortcuts Created with Global Hotkeys:" -ForegroundColor Yellow
Write-Host "  [Ctrl + Alt + M] -> Download Audio from Clipboard to C:\Users\Aaradhya\Music"
Write-Host "  [Ctrl + Alt + V] -> Download Video from Clipboard to C:\Users\Aaradhya\Videos\yt-dlp"
Write-Host ""
Write-Host "PowerShell Terminal Aliases (active in new terminal sessions):" -ForegroundColor Yellow
Write-Host "  dlm   -> Downloads music from clipboard (or URL)"
Write-Host "  dlv   -> Downloads video from clipboard (or URL)"
Write-Host "==========================================================" -ForegroundColor Green
