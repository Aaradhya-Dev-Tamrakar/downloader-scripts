<#
.SYNOPSIS
    Smart clipboard downloader with native 1-click format selection dialog.

.DESCRIPTION
    Auto-detects and auto-pastes the YouTube or YouTube Music URL from the clipboard.
    Shows an editable URL box (so you can review or paste a different link),
    and gives you two 1-click buttons:
      [🎵 Download Audio (MP3)] -> C:\Users\Aaradhya\Music
      [🎬 Download Video (MP4)] -> C:\Users\Aaradhya\Videos\yt-dlp
    Sends a native toast notification upon completion.
#>

[CmdletBinding()]
param (
    [ValidateSet("prompt", "audio", "video", "mp3", "720p", "1080p")]
    [string]$Mode = "prompt",

    [string]$Url
)

# Read clipboard
$clipboardText = ""
try {
    Add-Type -AssemblyName System.Windows.Forms
    $clipboardText = [System.Windows.Forms.Clipboard]::GetText().Trim()
} catch {
    $clipboardText = (Get-Clipboard 2>$null)
    if ($clipboardText) { $clipboardText = $clipboardText.Trim() }
}

if ([string]::IsNullOrWhiteSpace($Url)) {
    $Url = $clipboardText
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

# If Mode is prompt, show dialog with auto-pasted link and 1-click format buttons
if ($Mode -eq "prompt") {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Downloader (yt-dlp)" Height="230" Width="460"
        WindowStartupLocation="CenterScreen" WindowStyle="ToolWindow" ResizeMode="NoResize"
        Background="#18181b" Foreground="#f4f4f5" Topmost="True">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row="0" Text="Download from YouTube" FontSize="16" FontWeight="SemiBold" Foreground="#ffffff" Margin="0,0,0,6"/>
        
        <TextBox Name="TxtUrl" Grid.Row="1" Height="32" FontSize="12" Padding="6,4"
                 Background="#27272a" Foreground="#ffffff" BorderBrush="#3f3f46" BorderThickness="1" Margin="0,0,0,16">
            <TextBox.Resources>
                <Style TargetType="Border">
                    <Setter Property="CornerRadius" Value="4"/>
                </Style>
            </TextBox.Resources>
        </TextBox>
        
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center">
            <Button Name="BtnAudio" Content="🎵 Audio (MP3)" Width="195" Height="44" Margin="0,0,12,0"
                    Background="#2563eb" Foreground="#ffffff" FontSize="13" FontWeight="SemiBold" Cursor="Hand" BorderThickness="0">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="6"/>
                    </Style>
                </Button.Resources>
            </Button>
            <Button Name="BtnVideo" Content="🎬 Video (1080p MP4)" Width="195" Height="44"
                    Background="#059669" Foreground="#ffffff" FontSize="13" FontWeight="SemiBold" Cursor="Hand" BorderThickness="0">
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

    $txtUrl = $window.FindName("TxtUrl")
    $txtUrl.Text = $Url

    $chosenMode = $null
    $btnAudio = $window.FindName("BtnAudio")
    $btnVideo = $window.FindName("BtnVideo")

    $btnAudio.Add_Click({
        $script:chosenMode = "audio"
        $script:Url = $txtUrl.Text.Trim()
        $window.Close()
    })

    $btnVideo.Add_Click({
        $script:chosenMode = "video"
        $script:Url = $txtUrl.Text.Trim()
        $window.Close()
    })

    $window.ShowDialog() | Out-Null

    if (-not $chosenMode) {
        exit 0
    }
    $Mode = $chosenMode
}

# Validate URL pattern
if ([string]::IsNullOrWhiteSpace($Url) -or ($Url -notmatch "https?://(www\.|music\.)?(youtube\.com|youtu\.be)/.+")) {
    Show-Notification -Title "Downloader: Invalid URL" -Message "Please enter or copy a valid YouTube URL." -TargetFolder "C:\Users\Aaradhya\Music"
    Write-Warning "Not a valid YouTube URL: $Url"
    exit 1
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

    Show-Notification -Title "Downloading Audio..." -Message "Extracting MP3 and embedding album art/tags..." -TargetFolder $TargetFolder

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
