# Downloader Scripts

Modular PowerShell and Windows Batch automation suite for batch audio/video extraction via `yt-dlp` with automatic tag and thumbnail embedding, deduplication archives, and dedicated routing:
- **Audio / Music**: `C:\Users\Aaradhya\Music`
- **Video**: `C:\Users\Aaradhya\Videos\yt-dlp`

## Repository Structure

```text
Downloader scripts/
├── scripts/
│   ├── yt.ps1           # Parameterized CLI downloader (-Mode mp3|720p -Url <url>)
│   ├── yt-music.ps1     # Interactive YouTube Music downloader with tag/artwork embedding
│   ├── yt-video480.bat  # Fast 480p batch video download preset
│   └── yt-video720.bat  # 720p HD batch video download preset
├── sync.ps1             # Automated Git synchronizer with pre-commit secret scanning
├── README.md            # Documentation and usage guide
├── .gitignore           # Ignores credentials, archives, executables, and media
└── (Local files)        # yt-dlp.exe, cookies.txt, downloads.txt (ignored by git)
```

## Quick Start

### 1. Music Download (Interactive)
```powershell
.\scripts\yt-music.ps1
```
Prompts for a single track or playlist URL, fetches metadata, embeds thumbnails & ID3 tags, and saves directly to:
`C:\Users\Aaradhya\Music\<Playlist or Single>\<Title>.mp3`

### 2. Parameterized CLI
```powershell
.\scripts\yt.ps1 -Mode mp3 -Url "https://youtu.be/..."     # Saves to C:\Users\Aaradhya\Music
.\scripts\yt.ps1 -Mode 720p -Url "https://youtu.be/..."   # Saves to C:\Users\Aaradhya\Videos\yt-dlp
```

### 3. Fast Video Batch Presets
Double-click or run (saves to `C:\Users\Aaradhya\Videos\yt-dlp\<Playlist or Single>\<Title>.mp4`):
- `.\scripts\yt-video480.bat` (480p MP4)
- `.\scripts\yt-video720.bat` (720p MP4)

## Prerequisites

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) placed in repository root, `scripts/`, or on your system `PATH`.
- [ffmpeg](https://ffmpeg.org/) on `PATH` for audio extraction and muxing.
- `cookies.txt` placed in repository root (optional, for member-only/age-restricted content).
