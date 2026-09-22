param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("mp3", "720p")]
    [string]$Mode,

    [Parameter(Mandatory=$true)]
    [string]$Url
)

$Cookies = "cookies.txt"
$Output = "%(title)s.%(ext)s"

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
