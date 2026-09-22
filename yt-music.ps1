# Ensure the script runs from its own directory
Set-Location $PSScriptRoot

Write-Host "Updating yt-dlp to nightly..." -ForegroundColor Cyan
.\yt-dlp.exe --update-to nightly
Write-Host ""

$URL = Read-Host "Enter YouTube or YouTube Music URL"

$MusicRoot = "C:\Users\Aaradhya\Music"
if (-not (Test-Path $MusicRoot)) {
    New-Item -ItemType Directory -Path $MusicRoot -Force | Out-Null
}

$Arguments = @(
    "--cookies", (Join-Path $PSScriptRoot "cookies.txt"),
    "--yes-playlist",
    "--download-archive", (Join-Path $PSScriptRoot "downloads.txt"),
    "-f", "ba[ext=m4a]/ba",
    "-x",
    "--audio-format", "mp3",
    "--audio-quality", "0",
    "--embed-metadata",
    "--embed-thumbnail",
    "-o", "$MusicRoot\%(playlist_title|Single)s\%(title)s.%(ext)s",
    $URL
)

.\yt-dlp.exe @Arguments

Write-Host ""
Read-Host "Done. Press Enter to exit..."