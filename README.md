# Downloader Scripts

Modular PowerShell and Windows Batch automation suite for batch audio/video extraction via `yt-dlp` with automatic tag and thumbnail embedding, deduplication archives, dedicated routing, and zero-click global hotkey integration:
- **Audio / Music**: `C:\Users\Aaradhya\Music`
- **Video**: `C:\Users\Aaradhya\Videos\yt-dlp`

---

## ⚡ Option 1: Zero-Click Global Hotkeys (Recommended)

Simply copy any YouTube or YouTube Music URL in your browser (`Ctrl + C`), then press:

| Hotkey | Action | Destination |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>D</kbd> | ⚡ **Popup Selector**: 1-click choose Audio vs Video | Prompts popup |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>M</kbd> | 🎵 **Instant Audio** (MP3 + Cover + ID3 Tags) | `C:\Users\Aaradhya\Music\<Playlist|Single>\<Title>.mp3` |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>V</kbd> | 🎬 **Instant Video** (1080p/720p HD MP4) | `C:\Users\Aaradhya\Videos\yt-dlp\<Playlist|Single>\<Title>.mp4` |

*Sends a native Windows Toast Notification when downloading starts and when complete (with click-to-open).*

### Reinstall / Setup Hotkeys
```powershell
.\scripts\setup-hotkeys.ps1
```

---

## 💻 Terminal CLI & Profile Shortcuts

Once configured, you can download from any PowerShell window without changing directories:

- `dl`  — Reads clipboard and opens 1-click format selector popup
- `dlm` — Downloads audio directly from clipboard (or pass URL: `dlm "https://..."`)
- `dlv` — Downloads video directly from clipboard (or pass URL: `dlv "https://..."`)

---

## Repository Structure

```text
Downloader scripts/
├── scripts/
│   ├── clipboard-downloader.ps1 # Core zero-click engine with Toast notifications
│   ├── setup-hotkeys.ps1        # Global hotkey & profile shortcut installer
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
