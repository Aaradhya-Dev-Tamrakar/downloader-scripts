<#
.SYNOPSIS
    Smart clipboard downloader with native mini prompt dialog or hotkey modes.

.DESCRIPTION
    Reads YouTube / YouTube Music URL from clipboard.
    If mode is not specified (e.g. single hotkey Ctrl+Alt+D), pops a native,
    dark-themed 1-click modal to choose [🎵 Audio (MP3)] or [🎬 Video (MP4)].
    If mode is specified (-Mode audio | video), proceeds immediately with zero clicks.
#>

[CmdletBinding()]
param (
    [ValidateSet("prompt", "audio", "video", "mp3", "720p", "1080p")]
    [string]$Mode = "prompt",

    [string]$Url
)

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

# If Mode is "prompt", show modern lightweight WPF selector dialog
if ($Mode -eq "prompt") {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="yt-dlp Quick Downloader" Height="220" Width="430"
        WindowStartupLocation="CenterScreen" WindowStyle="ToolWindow" ResizeMode="NoResize"
        Background="#18181b" Foreground="#f4f4f5" Topmost="True">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="Choose Download Format" FontSize="16" FontWeight="SemiBold" Foreground="#ffffff"/>
        <TextBlock Grid.Row="1" Text="$([System.Security.SecurityElement]::Escape($Url))" FontSize="11" Foreground="#a1a1aa" TextTrimming="CharacterEllipsis" Margin="0,4,0,16"/>
        
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center">
            <Button Name="BtnAudio" Content="🎵 Audio (MP3 + Tags)" Width="175" Height="42" Margin="0,0,12,0"
                    Background="#2563eb" Foreground="#ffffff" FontSize="13" FontWeight="Medium" Cursor="Hand" BorderThickness="0">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="6"/>
                    </Style>
                </Button.Resources>
            </Button>
            <Button Name="BtnVideo" Content="🎬 Video (1080p MP4)" Width="175" Height="42"
                    Background="#059669" Foreground="#ffffff" FontSize="13" FontWeight="Medium" Cursor="Hand" BorderThickness="0">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="6"/>
                    </Style>
                </Button.Resources>
            </Button>
        </StackPanel>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    $chosenMode = $null
    $btnAudio = $window.FindName("BtnAudio")
    $btnVideo = $window.FindName("BtnVideo")

    $btnAudio.Add_Click({
        $script:chosenMode = "audio"
        $window.Close()
    })

    $btnVideo.Add_Click({
        $script:chosenMode = "video"
        $window.Close()
    })

    $window.ShowDialog() | Out-Null

    if (-not $chosenMode) {
        # User closed window / cancelled
        exit 0
    }
    $Mode = $chosenMode
}

# Normalize Mode
if ($Mode -eq "mp3") { $Mode = "audio" }
if ($Mode -eq "720p" -or $Mode -eq "1080p") { $Mode = "video" }

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
