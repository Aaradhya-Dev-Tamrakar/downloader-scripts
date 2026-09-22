# Downloader Scripts

Modular PowerShell and Windows Batch automation suite for batch audio/video extraction via `yt-dlp` with automatic tag and thumbnail embedding, deduplication archives, dedicated routing, and single-shortcut integration:
- **Audio / Music**: `C:\Users\Aaradhya\Music`
- **Video**: `C:\Users\Aaradhya\Videos\yt-dlp`

---

## ⚡ The Single Shortcut Workflow

1. Copy any YouTube or YouTube Music URL (`Ctrl + C`).
2. Hit <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>D</kbd> (or double-click **YouTube Downloader** on your Desktop).
3. The link is **auto-pasted** into a clean, dark popup.
4. Click:
   - **🎵 Audio (MP3)** $\to$ Saves to `C:\Users\Aaradhya\Music\<Playlist|Single>\<Title>.mp3`
   - **🎬 Video (1080p MP4)** $\to$ Saves to `C:\Users\Aaradhya\Videos\yt-dlp\<Playlist|Single>\<Title>.mp4`

*Native Windows Toast Notification pings on start and completion (click to open the folder).*

### Reinstall / Repair Shortcut
```powershell
.\scripts\setup-hotkeys.ps1
```

---

## 💻 Terminal CLI

From any PowerShell window:

- `dl` — Auto-pastes clipboard and opens the Audio / Video selector popup.
- `dl "https://..."` — Opens the selector for the specified URL.

---

## Repository Structure

```text
Downloader scripts/
├── scripts/
│   ├── clipboard-downloader.ps1 # Auto-paste GUI + Toast notification download engine
│   ├── setup-hotkeys.ps1        # Desktop shortcut & hotkey installer
│   ├── yt.ps1                   # Parameterized CLI downloader (-Mode mp3|720p -Url <url>)
│   ├── yt-music.ps1             # Interactive YouTube Music downloader with tag/artwork embedding
│   ├── yt-video480.bat          # Fast 480p batch video download preset
│   └── yt-video720.bat          # 720p HD batch video download preset
├── sync.ps1                     # Automated Git synchronizer with pre-commit secret scanning
├── README.md                    # Documentation and usage guide
├── .gitignore                   # Ignores credentials, archives, executables, and media
└── (Local files)                # yt-dlp.exe, cookies.txt, downloads.txt (ignored by git)
```

## Prerequisites

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) placed in repository root, `scripts/`, or on your system `PATH`.
- [ffmpeg](https://ffmpeg.org/) on `PATH` for audio extraction and muxing.
- `cookies.txt` placed in repository root (optional, for member-only/age-restricted content).
