# Starling Voice Dictation

**Free, offline, push-to-talk voice dictation for Windows and macOS.** Hold a key, speak, release. Your words appear instantly at the cursor -- in any app, on any screen. No cloud. No subscription. No audio ever leaves your machine.

[![Platform: Windows](https://img.shields.io/badge/platform-Windows%2010%2F11-blue?logo=windows)](#windows)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey?logo=apple)](#macos)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](#license)
[![Model: Parakeet-TDT v3](https://img.shields.io/badge/model-Parakeet--TDT%20v3-76b900?logo=nvidia)](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3)

---

## Download and install

### Windows -- one click, no setup required

**[Download Starling-Setup.zip](https://github.com/famousdrew/starling-voice-dictation/releases/latest/download/Starling-Setup.zip)**

Double-click the file. The installer handles everything: Python, all dependencies, the AI model, and shortcuts on your Desktop and Start Menu. No terminal. No prior software required.

> First run downloads about 4 GB of dependencies (PyTorch and the Parakeet model). After that, Starling launches in seconds.

### macOS

The macOS version is a native Swift app on the [`macos-swift`](https://github.com/famousdrew/starling-voice-dictation/tree/macos-swift) branch. See the [macOS section](#macos-1) below.

---

## Why Starling?

Most dictation tools are cloud services. Your voice travels to a server, gets transcribed, and comes back. That means latency, a monthly bill, and someone else's infrastructure in the middle of your workflow.

Starling runs entirely on your hardware using NVIDIA's [Parakeet-TDT v3](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3) model. On a modern GPU it transcribes faster than real-time, with accuracy that rivals or beats cloud alternatives on English. It works in every app -- your browser, your IDE, your email client, your chat tools. It pastes at the cursor just like you typed it.

**Free, open source, and always private.**

---

## Features

- **Hold-to-talk:** hold Right Ctrl, speak naturally, release to paste. Works in any focused window.
- **Hands-free mode:** double-tap the hotkey to lock recording on. Any key ends and transcribes; Escape cancels.
- **Streaming transcription:** audio is chunked at natural silences and transcribed in the background while you talk, so release-to-paste latency stays tight even on long sessions.
- **Launch splash screen:** shows model loading progress on startup so you know exactly when the app is live.
- **Live level meter:** the system tray icon animates with your mic input so you always know when you are being heard.
- **Stats window:** words today, last 7 days, and lifetime; average speaking WPM; 30-day chart; full session history.
- **Custom vocabulary:** teach Starling your product names and jargon through a built-in UI or a plain JSON file. Changes apply instantly.
- **Launch at login:** one toggle in Settings and Starling starts automatically with Windows.
- **Fully offline:** audio never leaves your machine.

---

## Platform support

| | Windows 10/11 | macOS 14+ (Sonoma) |
|---|---|---|
| **Branch** | `main` | [`macos-swift`](https://github.com/famousdrew/starling-voice-dictation/tree/macos-swift) |
| **Language** | Python | Swift |
| **Model** | Parakeet-TDT v3 (NVIDIA NeMo) | Whisper large-v3-turbo (WhisperKit) |
| **Hotkey** | Right Ctrl | Right Option |
| **GPU** | NVIDIA CUDA | Apple Neural Engine |

---

## Windows

### Installation

**[Download Starling-Setup.zip](https://github.com/famousdrew/starling-voice-dictation/releases/latest/download/Starling-Setup.zip)** and double-click it. That is all.

The installer will:

1. Install Python 3.12 automatically if not already present
2. Download the Starling source from GitHub
3. Install PyTorch with CUDA support (~2.5 GB)
4. Install the NeMo toolkit and all other dependencies (~1 GB)
5. Place a shortcut on your Desktop and in the Start Menu

The [Parakeet-TDT v3](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3) model (~2.5 GB) downloads automatically on first launch and is cached locally.

**System requirements:**
- Windows 10 or 11
- NVIDIA GPU with CUDA 12.8+ strongly recommended. CPU fallback works but is too slow for comfortable real-time use.
- ~8 GB free disk space

### First run

A splash screen appears while the model loads and warms up. When it reads **"Ready to dictate!"** the app is live and the splash closes on its own.

### Usage

| Action | Result |
|---|---|
| Hold **Right Ctrl** | Record while held, release to transcribe and paste |
| **Double-tap** Right Ctrl | Hands-free mode -- keeps recording until you stop it |
| Right Ctrl *(in hands-free)* | Stop, transcribe, and paste |
| Any other key *(in hands-free)* | Stop, transcribe, paste, then send the key normally |
| **Escape** *(in hands-free)* | Cancel without pasting |

Right-click the tray icon for Stats, Dictionary, Settings, and Quit.

### Custom vocabulary

Open the **Dictionary** tab from the tray icon to add corrections through the built-in UI. Or edit the file directly:

```
%APPDATA%\Starling\corrections.json
```

```json
{
  "you attend": "uAttend",
  "work well": "Workwell",
  "my product": "MyProduct"
}
```

The key is what the model hears (lowercase); the value is what gets pasted. Changes take effect immediately.

### Updating

Re-run `StarlingSetup.bat` at any time. It detects the existing installation, re-downloads the latest source, and skips the large dependency downloads since they are already installed.

### Advanced: install from source

For developers or users who prefer Git:

```powershell
git clone https://github.com/famousdrew/starling-voice-dictation.git
cd starling-voice-dictation
.\setup.ps1
.\run.ps1
```

### Direct downloads

| What | Link |
|---|---|
| Starling installer | [Starling-Setup.zip](https://github.com/famousdrew/starling-voice-dictation/releases/latest/download/Starling-Setup.zip) |
| Python 3.12 (if needed) | [python.org/downloads/release/python-3129](https://www.python.org/downloads/release/python-3129/) |
| NVIDIA driver 520+ | [nvidia.com/drivers](https://www.nvidia.com/en-us/drivers/) |
| CUDA 12.8 Toolkit (optional) | [developer.nvidia.com/cuda-12-8-0-download-archive](https://developer.nvidia.com/cuda-12-8-0-download-archive) |

---

## macOS

The macOS version lives on the [`macos-swift`](https://github.com/famousdrew/starling-voice-dictation/tree/macos-swift) branch. It is a native Swift app built on AVAudioEngine and [WhisperKit](https://github.com/argmaxinc/WhisperKit), optimised for Apple Silicon.

### Requirements

- macOS 14 Sonoma or later
- Xcode Command Line Tools (`xcode-select --install`)
- Apple Silicon recommended (Intel works, transcription is slower)
- ~700 MB disk for the Whisper model

### Quick start

```sh
git clone -b macos-swift https://github.com/famousdrew/starling-voice-dictation.git
cd starling-voice-dictation
./build-app.sh
open Starling.app
```

The Whisper `large-v3-turbo` model (~600 MB) downloads on first run.

### Permissions

macOS will prompt for three permissions on first use:

| Permission | Used for |
|---|---|
| Microphone | Audio capture |
| Input Monitoring | Global hotkey via `CGEventTap` |
| Accessibility | Synthesizing `Cmd+V` to paste |

All three are required. Grant them in **System Settings > Privacy & Security** if the prompts do not appear automatically.

### Usage

| Action | Result |
|---|---|
| Hold **Right Option** | Record, then release to transcribe and paste |
| Double-tap Right Option | Hands-free mode |
| Right Option *(in hands-free)* | Stop and paste |
| Escape *(in hands-free)* | Cancel |

---

## How it works

Starling buffers microphone audio at 16 kHz mono Float32. While you are recording, a background thread scans for silence boundaries (peak amplitude below 0.012 over 400ms) to split audio into 8-25 second chunks, which are transcribed as they complete. When you release the hotkey, any remaining audio is drained and all partial transcripts are joined. The result is saved to clipboard, `Ctrl+V` is synthesised, and your previous clipboard is restored 150ms later.

This chunked streaming approach means a 60-second dictation does not make you wait 60 seconds. Most of the transcript is ready before you even let go of the key.

---

## Privacy

- Audio is processed entirely on-device. Nothing is sent to any server.
- Session statistics are stored locally at `%APPDATA%\Starling\stats.json` (Windows) or `~/Library/Application Support/Starling/stats.json` (macOS).
- No telemetry, no analytics, no accounts.

---

## License

MIT. Use it, fork it, ship it to your team.

---

> *Named after the bird: a flock of starlings is called a murmuration, and starlings are remarkable vocal mimics.*
