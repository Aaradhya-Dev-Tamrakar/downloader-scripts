@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Always run from this script's directory
cd /d "%~dp0"

REM Ask for URL
set /p URL=Enter YouTube or YouTube Music URL: 

REM yt-dlp command (480p MP4)
yt-dlp.exe ^
  --cookies cookies.txt ^
  --yes-playlist ^
  --download-archive downloads.txt ^
  -f "bv*[ext=mp4][height<=480]+ba[ext=m4a]/b[ext=mp4][height<=480]" ^
  --merge-output-format mp4 ^
  --embed-metadata ^
  --embed-thumbnail ^
  -o "%%(playlist_title|Single)s/%%(title)s.%%(ext)s" ^
  "%URL%"

echo.
echo Done.
pause
