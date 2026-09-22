# Ensure the script runs from its own directory
Set-Location $PSScriptRoot

Write-Host "Updating yt-dlp to nightly..." -ForegroundColor Cyan
.\yt-dlp.exe --update-to nightly
Write-Host ""

$URL = Read-Host "Enter YouTube or YouTube Music URL"

$Arguments = @(
    "--cookies", "cookies.txt",
    "--yes-playlist",
    "--download-archive", "downloads.txt",
    "-f", "ba[ext=m4a]/ba",
    "-x",
    "--audio-format", "mp3",
    "--audio-quality", "0",
    "--embed-metadata",
    "--embed-thumbnail",
    "-o", "%(playlist_title|Single)s/%(title)s.%(ext)s",
    $URL
)

.\yt-dlp.exe @Arguments

Write-Host ""
Read-Host "Done. Press Enter to exit..."