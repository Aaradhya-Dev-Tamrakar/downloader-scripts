[CmdletBinding()]
param (
    [ValidateSet("prompt", "audio", "video", "mp3", "720p", "1080p")]
    [string]$Mode = "prompt",

    [string]$AudioFormat = "mp3",

    [string]$Quality = "1080p",

    [string]$Url
)

# Robust clipboard reading function
function Get-ClipboardUrl {
    $text = ""
    # Method 1: Windows Forms STA
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $text = [System.Windows.Forms.Clipboard]::GetText()
    } catch {}

    # Method 2: WPF Clipboard
    if ([string]::IsNullOrWhiteSpace($text)) {
        try {
            Add-Type -AssemblyName PresentationCore
            $text = [System.Windows.Clipboard]::GetText()
        } catch {}
    }

    # Method 3: PowerShell 5+ Get-Clipboard
    if ([string]::IsNullOrWhiteSpace($text)) {
        try {
            $text = (Get-Clipboard 2>$null)
            if ($text -is [array]) { $text = $text -join "`n" }
        } catch {}
    }

    if ($text) { return $text.Trim() }
    return ""
}

if ([string]::IsNullOrWhiteSpace($Url)) {
    $Url = Get-ClipboardUrl
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
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $balloon = New-Object System.Windows.Forms.NotifyIcon
            $balloon.Icon = [System.Drawing.SystemIcons]::Information
            $balloon.BalloonTipTitle = $Title
            $balloon.BalloonTipText = $Message
            $balloon.Visible = $true
            $balloon.ShowBalloonTip(4000)
        } catch {}
    }
}

# If Mode is prompt, show dialog with split-button dropdowns directly attached to Audio and Video actions
if ($Mode -eq "prompt") {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    if ([string]::IsNullOrWhiteSpace($Url)) {
        $Url = Get-ClipboardUrl
    }

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Downloader (yt-dlp)" Height="240" Width="520"
        WindowStartupLocation="CenterScreen" WindowStyle="ToolWindow" ResizeMode="NoResize"
        Background="#18181b" Foreground="#f4f4f5" Topmost="True">
    <Grid Margin="22">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row="0" Text="Download from YouTube" FontSize="16" FontWeight="SemiBold" Foreground="#ffffff" Margin="0,0,0,6"/>
        
        <TextBox Name="TxtUrl" Grid.Row="1" Height="34" FontSize="12" Padding="8,6"
                 Background="#27272a" Foreground="#ffffff" BorderBrush="#3f3f46" BorderThickness="1" Margin="0,0,0,18">
            <TextBox.Resources>
                <Style TargetType="Border">
                    <Setter Property="CornerRadius" Value="4"/>
                </Style>
            </TextBox.Resources>
        </TextBox>

        <!-- Two Action Columns with Integrated Split Dropdowns -->
        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="14"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Audio Split Control (Blue) -->
            <Border Grid.Column="0" Background="#2563eb" CornerRadius="6" Height="46">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="1"/>
                        <ColumnDefinition Width="80"/>
                    </Grid.ColumnDefinitions>

                    <Button Name="BtnAudio" Grid.Column="0" Content="[Audio]" Background="Transparent" Foreground="#ffffff"
                            FontSize="14" FontWeight="SemiBold" Cursor="Hand" BorderThickness="0"/>

                    <Rectangle Grid.Column="1" Fill="#3b82f6" Width="1"/>

                    <ComboBox Name="CmbAudio" Grid.Column="2" SelectedIndex="0" VerticalContentAlignment="Center"
                              Background="#1d4ed8" Foreground="#ffffff" BorderThickness="0" Cursor="Hand" Padding="6,0,0,0">
                        <ComboBoxItem Content="MP3"/>
                        <ComboBoxItem Content="FLAC"/>
                        <ComboBoxItem Content="M4A"/>
                        <ComboBoxItem Content="OPUS"/>
                        <ComboBoxItem Content="WAV"/>
                    </ComboBox>
                </Grid>
            </Border>

            <!-- Video Split Control (Emerald Green) -->
            <Border Grid.Column="2" Background="#059669" CornerRadius="6" Height="46">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="1"/>
                        <ColumnDefinition Width="90"/>
                    </Grid.ColumnDefinitions>

                    <Button Name="BtnVideo" Grid.Column="0" Content="[Video]" Background="Transparent" Foreground="#ffffff"
                            FontSize="14" FontWeight="SemiBold" Cursor="Hand" BorderThickness="0"/>

                    <Rectangle Grid.Column="1" Fill="#10b981" Width="1"/>

                    <ComboBox Name="CmbVideo" Grid.Column="2" SelectedIndex="0" VerticalContentAlignment="Center"
                              Background="#047857" Foreground="#ffffff" BorderThickness="0" Cursor="Hand" Padding="6,0,0,0">
                        <ComboBoxItem Content="1080p"/>
                        <ComboBoxItem Content="4K / Max"/>
                        <ComboBoxItem Content="720p"/>
                        <ComboBoxItem Content="480p"/>
                        <ComboBoxItem Content="360p"/>
                    </ComboBox>
                </Grid>
            </Border>
        </Grid>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    $txtUrl = $window.FindName("TxtUrl")
    $txtUrl.Text = $Url
    if (-not [string]::IsNullOrWhiteSpace($Url)) {
        $txtUrl.SelectAll()
    }

    $cmbAudio = $window.FindName("CmbAudio")
    $cmbVideo = $window.FindName("CmbVideo")

    # Focus text box on load
    $window.Add_Loaded({
        $txtUrl.Focus()
        if ([string]::IsNullOrWhiteSpace($txtUrl.Text)) {
            $latest = Get-ClipboardUrl
            if ($latest) { $txtUrl.Text = $latest }
        }
    })

    $chosenMode = $null
    $chosenAudioFormat = "mp3"
    $chosenQuality = "1080p"

    $btnAudio = $window.FindName("BtnAudio")
    $btnVideo = $window.FindName("BtnVideo")

    $btnAudio.Add_Click({
        $script:chosenMode = "audio"
        $script:Url = $txtUrl.Text.Trim()
        $selectedAudio = $cmbAudio.SelectedItem.Content.ToString().ToLower()
        $script:chosenAudioFormat = $selectedAudio
        $window.Close()
    })

    $btnVideo.Add_Click({
        $script:chosenMode = "video"
        $script:Url = $txtUrl.Text.Trim()
        $selectedVideo = $cmbVideo.SelectedItem.Content.ToString()
        if ($selectedVideo -match "4K|Max") {
            $script:chosenQuality = "best"
        } elseif ($selectedVideo -match "720p") {
            $script:chosenQuality = "720p"
        } elseif ($selectedVideo -match "480p") {
            $script:chosenQuality = "480p"
        } elseif ($selectedVideo -match "360p") {
            $script:chosenQuality = "360p"
        } else {
            $script:chosenQuality = "1080p"
        }
        $window.Close()
    })

    $window.ShowDialog() | Out-Null

    if (-not $chosenMode) {
        exit 0
    }
    $Mode = $chosenMode
    $AudioFormat = $chosenAudioFormat
    $Quality = $chosenQuality
}

# Validate URL pattern
if ([string]::IsNullOrWhiteSpace($Url) -or ($Url -notmatch "https?://(www\.|music\.)?(youtube\.com|youtu\.be)/.+")) {
    Show-Notification -Title "Downloader: Invalid URL" -Message "Please copy or enter a valid YouTube URL." -TargetFolder "C:\Users\Aaradhya\Music"
    Write-Warning "Not a valid YouTube URL: $Url"
    exit 1
}

# Normalize Mode
if ($Mode -eq "mp3") { $Mode = "audio"; $AudioFormat = "mp3" }
if ($Mode -eq "720p") { $Mode = "video"; $Quality = "720p" }
if ($Mode -eq "1080p") { $Mode = "video"; $Quality = "1080p" }

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

    Show-Notification -Title "Downloading Audio ($AudioFormat)..." -Message "Extracting $AudioFormat and embedding metadata/artwork..." -TargetFolder $TargetFolder

    $argsList = @(
        "--cookies", $Cookies,
        "--yes-playlist",
        "--download-archive", $DownloadsArchive,
        "-f", "ba[ext=m4a]/ba",
        "-x",
        "--audio-format", $AudioFormat,
        "--audio-quality", "0",
        "--embed-metadata",
        "--embed-thumbnail",
        "-o", "$TargetFolder\%(playlist_title|Single)s\%(title)s.%(ext)s",
        $Url
    )
} else {
    $TargetFolder = "C:\Users\Aaradhya\Videos\yt-dlp"
    if (-not (Test-Path $TargetFolder)) { New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null }

    $videoFormat = switch ($Quality) {
        "best"  { "bv*+ba/b" }
        "720p"  { "bv*[ext=mp4][height<=720]+ba[ext=m4a]/b[ext=mp4][height<=720]/b" }
        "480p"  { "bv*[ext=mp4][height<=480]+ba[ext=m4a]/b[ext=mp4][height<=480]/b" }
        "360p"  { "bv*[ext=mp4][height<=360]+ba[ext=m4a]/b[ext=mp4][height<=360]/b" }
        default { "bv*[ext=mp4][height<=1080]+ba[ext=m4a]/b[ext=mp4][height<=1080]/b" }
    }

    Show-Notification -Title "Downloading Video ($Quality)..." -Message "Fetching video stream..." -TargetFolder $TargetFolder

    $argsList = @(
        "--cookies", $Cookies,
        "--yes-playlist",
        "--download-archive", $DownloadsArchive,
        "-f", $videoFormat,
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
