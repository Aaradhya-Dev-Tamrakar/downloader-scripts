# Downloader Scripts Hub

Modular PowerShell and Windows Batch automation suite for batch audio/video extraction via `yt-dlp` with automatic tag and thumbnail embedding, deduplication archives, dedicated routing, and a modern zero-click dark card UI:
- **Audio / Music**: `C:\Users\Aaradhya\Music`
- **Video**: `C:\Users\Aaradhya\Videos\yt-dlp`

---

## ⚡ The Zero-Click Desktop Workflow

1. Copy any YouTube or YouTube Music URL (`Ctrl + C`).
2. Hit <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>D</kbd> (or double-click **`download.bat`** on your Desktop).
3. The URL is **automatically pasted** into a floating dark-mode card modal with a dedicated "Paste" button.
4. Choose your stream:
   - **🎵 Audio Card**: Format dropdown (`MP3` *default*, `FLAC`, `M4A`, `OPUS`, `WAV`) $\to$ Click **Download Music** to save with album artwork and ID3 tags to `C:\Users\Aaradhya\Music`.
   - **🎬 Video Card**: Quality dropdown (`1080p` *default*, `4K / Max`, `720p`, `480p`, `360p`) $\to$ Click **Download Video** to save MP4 to `C:\Users\Aaradhya\Videos\yt-dlp`.

*Native Windows Toast Notification pings on start and completion (click to open the folder).*

### Reinstall / Repair Shortcut
```powershell
.\scripts\setup-hotkeys.ps1
```

---

## 💻 Terminal CLI & Automation

From any PowerShell window:

- `dl` — Auto-pastes clipboard and opens the Audio / Video selector popup.
- `dl "https://..."` — Opens the selector for the specified URL.
- `dlm` — Instant headless audio extraction to `Music`.
- `dlv` — Instant headless video download to `Videos\yt-dlp`.

---

## Repository Structure

```text
Downloader scripts/
├── scripts/
│   ├── clipboard-downloader.ps1 # Frameless WPF Dark UI + Toast notification download engine
│   ├── setup-hotkeys.ps1        # Desktop shortcut & hotkey installer
│   ├── yt.ps1                   # Parameterized CLI downloader (-Mode mp3|720p -Url <url>)
│   ├── yt-music.ps1             # Interactive YouTube Music downloader with tag/artwork embedding
│   ├── yt-video480.bat          # Fast 480p batch video download preset
│   └── yt-video720.bat          # 720p HD batch video download preset
├── download.bat                 # 1-click silent root launcher
├── sync.ps1                     # Automated Git synchronizer with pre-commit secret scanning
├── README.md                    # Documentation and usage guide
├── .gitignore                   # Ignores credentials, archives, executables, and media
└── (Local files)                # yt-dlp.exe, cookies.txt, downloads.txt (ignored by git)
```

## Prerequisites

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) placed in repository root, `scripts/`, or on your system `PATH`.
- [ffmpeg](https://ffmpeg.org/) on `PATH` for audio extraction and muxing.
- `cookies.txt` placed in repository root (optional, for member-only/age-restricted content).
