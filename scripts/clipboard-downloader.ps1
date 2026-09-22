<#
.SYNOPSIS
    Single-action clipboard downloader with native Windows toast notification.

.DESCRIPTION
    Reads YouTube or YouTube Music URL directly from Windows Clipboard,
    downloads audio (MP3 + tags + cover) or video (MP4) to designated folders,
    and shows a native Windows toast notification upon completion.

.PARAMETER Mode
    'audio' (default) -> C:\Users\Aaradhya\Music
    'video'           -> C:\Users\Aaradhya\Videos\yt-dlp
#>

[CmdletBinding()]
param (
    [ValidateSet("audio", "video", "mp3", "720p", "1080p")]
    [string]$Mode = "audio",

    [string]$Url
)

# Normalize Mode
if ($Mode -eq "mp3") { $Mode = "audio" }
if ($Mode -eq "720p" -or $Mode -eq "1080p") { $Mode = "video" }

# 1. Read URL from Clipboard if not provided via parameter
if ([string]::IsNullOrWhiteSpace($Url)) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $Url = [System.Windows.Forms.Clipboard]::GetText().Trim()
    } catch {
        $Url = (Get-Clipboard 2>$null)
        if ($Url) { $Url = $Url.Trim() }
    }
}

function Show-Notification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$TargetFolder
    )
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        $template = @"
<toast activationType="protocol" launch="file:///$($TargetFolder -replace '\\', '/')">
    <visual>
        <binding template="ToastGeneric">
            <text>$Title</text>
            <text>$Message</text>
        </binding>
    </visual>
</toast>
"@
        $xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
        $xml.LoadXml($template)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("DownloaderScripts").Show($toast)
    } catch {
        # Fallback to standard tray notification if WinRT XML fails
        Add-Type -AssemblyName System.Windows.Forms
        $balloon = New-Object System.Windows.Forms.NotifyIcon
        $balloon.Icon = [System.Drawing.SystemIcons]::Information
        $balloon.BalloonTipTitle = $Title
        $balloon.BalloonTipText = $Message
        $balloon.Visible = $true
        $balloon.ShowBalloonTip(4000)
    }
}

# Validate URL pattern
if ([string]::IsNullOrWhiteSpace($Url) -or ($Url -notmatch "https?://(www\.|music\.)?(youtube\.com|youtu\.be)/.+")) {
    Show-Notification -Title "Downloader: No Valid URL" -Message "Clipboard does not contain a YouTube URL." -TargetFolder "C:\Users\Aaradhya\Music"
    Write-Warning "Clipboard does not contain a valid YouTube or YouTube Music URL."
    exit 1
}

# Resolve paths
$ScriptDir = $PSScriptRoot
$RepoRoot = Split-Path -Parent $ScriptDir

$YtDlp = "yt-dlp"
if (Test-Path (Join-Path $ScriptDir "yt-dlp.exe")) {
    $YtDlp = Join-Path $ScriptDir "yt-dlp.exe"
} elseif (Test-Path (Join-Path $RepoRoot "yt-dlp.exe")) {
    $YtDlp = Join-Path $RepoRoot "yt-dlp.exe"
}

$Cookies = Join-Path $RepoRoot "cookies.txt"
if (-not (Test-Path $Cookies)) { $Cookies = Join-Path $ScriptDir "cookies.txt" }

$DownloadsArchive = Join-Path $RepoRoot "downloads.txt"
if (-not (Test-Path $DownloadsArchive)) { $DownloadsArchive = Join-Path $ScriptDir "downloads.txt" }

# Destination config
if ($Mode -eq "audio") {
    $TargetFolder = "C:\Users\Aaradhya\Music"
    if (-not (Test-Path $TargetFolder)) { New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null }

    Show-Notification -Title "Downloading Audio..." -Message "Fetching audio stream and embedding ID3 tags..." -TargetFolder $TargetFolder

    $argsList = @(
        "--cookies", $Cookies,
        "--yes-playlist",
        "--download-archive", $DownloadsArchive,
        "-f", "ba[ext=m4a]/ba",
        "-x",
        "--audio-format", "mp3",
        "--audio-quality", "0",
        "--embed-metadata",
        "--embed-thumbnail",
        "-o", "$TargetFolder\%(playlist_title|Single)s\%(title)s.%(ext)s",
        $Url
    )
} else {
    $TargetFolder = "C:\Users\Aaradhya\Videos\yt-dlp"
    if (-not (Test-Path $TargetFolder)) { New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null }

    Show-Notification -Title "Downloading Video..." -Message "Fetching 1080p/720p video stream..." -TargetFolder $TargetFolder

    $argsList = @(
        "--cookies", $Cookies,
        "--yes-playlist",
        "--download-archive", $DownloadsArchive,
        "-f", "bv*[ext=mp4][height<=1080]+ba[ext=m4a]/b[ext=mp4][height<=1080]/b",
        "--merge-output-format", "mp4",
        "--embed-metadata",
        "--embed-thumbnail",
        "-o", "$TargetFolder\%(playlist_title|Single)s\%(title)s.%(ext)s",
        $Url
    )
}

& $YtDlp @argsList

if ($LASTEXITCODE -eq 0) {
    Show-Notification -Title "Download Complete!" -Message "Saved to $TargetFolder. Click to open." -TargetFolder $TargetFolder
} else {
    Show-Notification -Title "Download Failed" -Message "yt-dlp exited with error code $LASTEXITCODE." -TargetFolder $TargetFolder
}
