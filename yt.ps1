param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("mp3", "720p")]
    [string]$Mode,

    [Parameter(Mandatory=$true)]
    [string]$Url
)

# Output directory: C:\Users\Aaradhya\Music
$OutputDir = "C:\Users\Aaradhya\Music"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$Cookies = Join-Path $PSScriptRoot "cookies.txt"
$Output = "$OutputDir\%(title)s.%(ext)s"

if ($Mode -eq "mp3") {
    yt-dlp `
        --cookies $Cookies `
        -x `
        --audio-format mp3 `
        --audio-quality 0 `
        -o $Output `
        $Url
}
elseif ($Mode -eq "720p") {
    yt-dlp `
        --cookies $Cookies `
        -f "bv*[height<=720][ext=mp4]+ba[ext=m4a]/b[height<=720]" `
        --merge-output-format mp4 `
        -o $Output `
        $Url
}
