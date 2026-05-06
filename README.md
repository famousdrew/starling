# Starling

Push-to-talk dictation for Windows 11. Hold **Right Ctrl**, speak, release — the transcript pastes into whatever app has focus. No cloud, no subscription.

> Named after the bird: a flock is called a *murmuration*, and starlings are remarkable vocal mimics.

Powered by [Parakeet-TDT v3](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3) (NVIDIA NeMo) running on your GPU. Streaming chunked transcription keeps latency near-instant on release even for long sessions.

## Features

- **Hold-to-talk** — hold Right Ctrl, speak, release to transcribe and paste.
- **Hands-free mode** — double-tap Right Ctrl to lock recording on; any key ends and transcribes (Escape cancels).
- **Streaming transcription** — audio is chunked at natural pauses and transcribed in the background, so release-to-paste latency is bounded by the trailing chunk.
- **Live level meter** — tray icon shows mic input as five animated bars; red tint while hands-free.
- **Stats window** — words today / 7-day / lifetime, average WPM, 30-day chart, recent sessions, test playground.
- **Custom vocabulary** — drop a `corrections.json` in `%APPDATA%\Starling\` to fix product names and jargon.
- **Launch at Login** — toggle in the Settings tab of the stats window.

## Setup

See [SETUP.md](SETUP.md) for full instructions. The short version:

```powershell
git clone https://github.com/famousdrew/starling.git
cd starling
.\setup.ps1
.\run.ps1
```

## Requirements

- Windows 10 or 11
- Python 3.12 (not 3.13/3.14)
- NVIDIA GPU with CUDA 12.8+ recommended
- ~6 GB free disk space

## Usage

| Gesture | Action |
|---|---|
| Hold Right Ctrl | Record — release to transcribe + paste |
| Double-tap Right Ctrl | Hands-free mode |
| Right Ctrl (in hands-free) | Stop + transcribe + paste |
| Escape (in hands-free) | Cancel without pasting |

Stats and session history are saved to `%APPDATA%\Starling\stats.json`.

## macOS version

The original Swift/macOS implementation (using WhisperKit + AVAudioEngine) lives on the [`macos-swift`](https://github.com/famousdrew/starling/tree/macos-swift) branch.
