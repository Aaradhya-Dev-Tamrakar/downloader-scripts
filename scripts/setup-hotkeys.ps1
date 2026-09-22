<#
.SYNOPSIS
    Installs global Windows shortcuts and PowerShell profile aliases for zero-click downloading.
#>

$ScriptDir = $PSScriptRoot
$RepoRoot = Split-Path -Parent $ScriptDir
$DownloaderScript = Join-Path $ScriptDir "clipboard-downloader.ps1"

# 1. Create Desktop Quick Shortcuts
$WshShell = New-Object -ComObject WScript.Shell
$DesktopPath = [System.Environment]::GetFolderPath("Desktop")

# Quick Prompt Shortcut: [Ctrl + Alt + D] -> Pops up 1-click Choice Window (Audio vs Video)
$PromptShortcutPath = Join-Path $DesktopPath "Download from Clipboard.lnk"
$ShortcutD = $WshShell.CreateShortcut($PromptShortcutPath)
$ShortcutD.TargetPath = "powershell.exe"
$ShortcutD.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$DownloaderScript`" -Mode prompt"
$ShortcutD.IconLocation = "shell32.dll,264" # Download / transfer icon
$ShortcutD.Hotkey = "CTRL+ALT+D"
$ShortcutD.Description = "Ask Audio vs Video for YouTube link in clipboard"
$ShortcutD.Save()

# Direct Audio Shortcut: [Ctrl + Alt + M] -> Immediate MP3 Download
$MusicShortcutPath = Join-Path $DesktopPath "Download Music (Clipboard).lnk"
$ShortcutM = $WshShell.CreateShortcut($MusicShortcutPath)
$ShortcutM.TargetPath = "powershell.exe"
$ShortcutM.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$DownloaderScript`" -Mode audio"
$ShortcutM.IconLocation = "shell32.dll,116" # Audio note icon
$ShortcutM.Hotkey = "CTRL+ALT+M"
$ShortcutM.Description = "Download audio from YouTube URL in Clipboard to Music"
$ShortcutM.Save()

# Direct Video Shortcut: [Ctrl + Alt + V] -> Immediate Video Download
$VideoShortcutPath = Join-Path $DesktopPath "Download Video (Clipboard).lnk"
$ShortcutV = $WshShell.CreateShortcut($VideoShortcutPath)
$ShortcutV.TargetPath = "powershell.exe"
$ShortcutV.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$DownloaderScript`" -Mode video"
$ShortcutV.IconLocation = "shell32.dll,115" # Video reel icon
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
function dl  { & "$DownloaderScript" -Mode prompt @args }
function dlm { & "$DownloaderScript" -Mode audio @args }
function dlv { & "$DownloaderScript" -Mode video @args }
# -------------------------------------------------
"@

if (Test-Path $PROFILE) {
    $existing = Get-Content $PROFILE -Raw
    if ($existing -match "# --- Downloader Scripts Zero-Click Integration ---") {
        # Update snippet
        $updated = $existing -replace '(?s)# --- Downloader Scripts Zero-Click Integration ---.*?# -------------------------------------------------', $ProfileSnippet.Trim()
        Set-Content -Path $PROFILE -Value $updated
    } else {
        Add-Content -Path $PROFILE -Value $ProfileSnippet
    }
} else {
    Set-Content -Path $PROFILE -Value $ProfileSnippet
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  SMART DOWNLOADER CONFIGURED SUCCESSFULLY" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Global Hotkeys (Press anywhere in Windows after copying link):" -ForegroundColor Yellow
Write-Host "  [Ctrl + Alt + D] -> ⚡ Popup Selector: 1-click choose Audio vs Video"
Write-Host "  [Ctrl + Alt + M] -> 🎵 Instant Audio: Downloads directly to Music"
Write-Host "  [Ctrl + Alt + V] -> 🎬 Instant Video: Downloads directly to Videos\yt-dlp"
Write-Host ""
Write-Host "PowerShell Terminal Aliases:" -ForegroundColor Yellow
Write-Host "  dl    -> Pops format choice for clipboard URL"
Write-Host "  dlm   -> Direct audio download from clipboard (or URL)"
Write-Host "  dlv   -> Direct video download from clipboard (or URL)"
Write-Host "==========================================================" -ForegroundColor Green
