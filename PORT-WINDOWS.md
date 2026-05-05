# Porting Starling to Windows 11

This document is a spec, not a porting target. None of the Swift code translates — Starling's macOS implementation depends on AppKit, AVAudioEngine, CGEventTap, NSPasteboard, and WhisperKit/Core ML, all of which are Apple-only. Read the source files in `Sources/Starling/` as a reference for behavior and naming, then re-implement against Windows-native APIs.

## What Starling does

A menubar (tray) app that runs in the background. The user holds **Right Option** (macOS) / **Right Alt** (Windows) to record their voice. On release, the audio is transcribed and the resulting text is pasted via synthesized `Cmd+V` / `Ctrl+V` into whatever app currently has focus. A double-tap of the same key engages "hands-free" mode that keeps recording until any key is pressed.

Latency on long sessions is kept low by transcribing in the background while the user is still talking — chunks are split at silence boundaries between 8–25 seconds long.

The app also exposes a stats window (words today / 7-day / lifetime, average WPM, 30-day chart, recent sessions, test playground) and a "Launch at Login" toggle.

## Reference behavior (from the macOS implementation)

| Area | Behavior |
|---|---|
| Hold gesture | Press Right Alt → start recording. Release → transcribe + paste at cursor. |
| Tap | A press shorter than 250ms is a "tap" — discard the (too-short) audio. |
| Double-tap | Two taps with releases within 350ms of each other → enter hands-free mode. |
| Hands-free exit | Right Alt again → end + transcribe. Any other key → end + transcribe + swallow that key. Escape → cancel without transcribing. |
| Paste | Save current clipboard → write transcript → synthesize Ctrl+V → restore clipboard ~150ms later. |
| Tray icon | Idle: mic outline. Recording: 5-bar level meter that scales with mic peak. Hands-free: same meter tinted red. |
| Streaming | Buffer accumulates samples at 16kHz mono Float32. Background actor consumes chunks as they cross silence boundaries (peak < 0.012 over 400ms after at least 8s of audio, or hard cut at 25s). On release, drains remaining samples and concatenates transcripts. |
| Stats | One JSON record per successful transcription: `{id, timestamp, audioSeconds, wordCount, transcript}`. Persists to `%APPDATA%\Starling\stats.json`. |
| Pre-warm | Run a 1s silent buffer through the transcriber at startup so the first real hotkey press isn't slow. |

## Recommended stack

**Python + faster-whisper** if you want the fastest path to working.
**Rust + Tauri + whisper-rs (or NeMo bindings)** if you want a clean cross-platform codebase.

Below assumes Python — adapt as needed.

### Inference: Parakeet-TDT, not Whisper

For NVIDIA workstations, switch from Whisper to **Parakeet-TDT** (NVIDIA NeMo). Reasons:

- Sub-real-time streaming inference is native (Whisper has to fake it via chunking, which is what we do on Mac).
- ~10× faster than Whisper large-v3 on RTX-class GPUs.
- Often more accurate on English benchmarks (HF OpenASR leaderboard top of class).
- Open license (CC-BY-4.0).
- Models: `nvidia/parakeet-tdt-0.6b-v2` (recommended starting point) or `nvidia/parakeet-tdt-1.1b` for slightly better accuracy.

If you'd rather stay closer to the Mac version's behavior: **faster-whisper** with `large-v3-turbo`, `compute_type="float16"`, on CUDA. Still plenty fast on NVIDIA.

If you want to add diarization later (meeting-mode labeling speakers), wire in **NVIDIA Sortformer** as a second pass — it's diarization, not transcription, and runs alongside Parakeet rather than replacing it.

### Component map

| Concern | macOS (current) | Windows port |
|---|---|---|
| Global hotkey | `CGEventTap` on Right Option, suppression for hands-free terminator | `pynput.keyboard.Listener` (or `keyboard` library), or low-level via `SetWindowsHookEx` (`WH_KEYBOARD_LL`) for clean key suppression |
| Audio capture | `AVAudioEngine` 16kHz mono Float32 | `sounddevice.InputStream(samplerate=16000, channels=1, dtype='float32')` (PortAudio under the hood). NumPy buffers throughout. |
| Inference | WhisperKit `transcribe(audioArray:)` | NeMo `ASRModel.transcribe()` for Parakeet, or `WhisperModel.transcribe()` for faster-whisper. Both accept float32 numpy arrays. |
| Streaming chunker | `StreamingTranscriber` actor with VAD-based splitting | Same logic in a `threading.Thread` consuming a `queue.Queue`. NumPy slice ops instead of Swift Array ops. |
| Paste injection | Save NSPasteboard → set string → `CGEventPost(Cmd+V)` → restore | Save clipboard via `pyperclip` (or `win32clipboard`) → set transcript → `SendInput` Ctrl+V via `pyautogui`/`pynput`/`ctypes` → restore. **Restore on a 150ms delay** — the receiving app needs the clipboard intact while it processes the paste. |
| Tray icon | `NSStatusItem` + custom `NSImage` for the level meter | `pystray.Icon` with a Pillow-drawn `Image` regenerated each tick. The level-meter draw is the same 5-bar logic. |
| Stats UI | SwiftUI window via `NSHostingController` | `PySide6` (Qt) for a native window, or `tkinter` for stdlib-only. Both can render the bar chart with simple drawing. |
| Persistence | JSON at `~/Library/Application Support/Starling/stats.json` | JSON at `%APPDATA%\Starling\stats.json`. Use `pathlib.Path.home() / "AppData" / "Roaming" / "Starling"` or `os.environ["APPDATA"]`. |
| Launch at login | `SMAppService.mainApp.register()` | Registry: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`. Or `winshell` Startup folder shortcut. |
| Permissions | TCC prompts for Mic / Input Monitoring / Accessibility | Microphone privacy toggle in Windows Settings (auto-prompts on first capture). No equivalent of Input Monitoring/Accessibility — Windows lets any app register hotkeys and synthesize input without a prompt. |

### Tunables (carry these over verbatim from the Mac version)

```python
SAMPLE_RATE = 16_000
TAP_MAX_DURATION = 0.25        # seconds — press shorter than this is a "tap"
DOUBLE_TAP_WINDOW = 0.35       # seconds between two taps to count as double
MIN_CHUNK_SECONDS = 8
MAX_CHUNK_SECONDS = 25
SILENCE_WINDOW_MS = 400
SILENCE_THRESHOLD = 0.012      # peak amplitude
LEVEL_PEAK_GAIN = 6.0          # multiplier on raw peak before clamping to 1.0
LEVEL_BAR_BIAS = 0.65          # bar i lights when level >= (i+1)/N * BIAS
HOTKEY = Key.alt_r             # Right Alt
```

### Project layout suggestion (Python)

```
starling/
├── pyproject.toml
├── README.md
├── starling/
│   ├── __main__.py             # entry point: wires everything, runs tray loop
│   ├── hotkey.py               # press/tap/double-tap state machine
│   ├── audio.py                # sounddevice capture, ring buffer, peak callback
│   ├── transcriber.py          # Parakeet (or faster-whisper) wrapper
│   ├── streaming.py            # VAD-aware chunker, background worker
│   ├── inject.py               # clipboard save/paste/restore
│   ├── tray.py                 # pystray icon + level meter renderer
│   ├── stats.py                # SessionStats dataclass + JSON persistence
│   ├── stats_ui.py             # Qt or tkinter window
│   └── login_item.py           # registry write for "Launch at Login"
```

### Distribution

- **Dev**: `pip install -e .` and `python -m starling`. Easy to iterate.
- **For friends**: `pyinstaller --onefile --windowed --add-data ... starling/__main__.py` produces a `Starling.exe` (~200MB once you include the model). Ship the model separately or download on first run (the macOS version downloads ~600MB lazily — same pattern works here).
- Right-click your `Starling.exe` shortcut → "Run as administrator" is **not** needed; global hotkey + clipboard + tray work without elevation.

### Things to verify against the Mac version's behavior

When implementing, sanity-check these specifically because they bit me on the Mac side:

1. **Tap-to-exit hands-free fires both press AND release events.** The state machine has to ignore the release that pairs with the press that exited hands-free, or it starts a fresh recording. (See `HotkeyMonitor.ignoreNextRightOptionEvent` in the Swift source.)
2. **Pre-warm matters.** First inference call with a cold model takes 5–15s as Core ML / TensorRT compiles kernels. Run a silent buffer through it at startup so this happens during model load, not on the user's first hotkey press.
3. **Clipboard restore needs a delay.** Restoring the user's previous clipboard immediately after `Ctrl+V` causes the receiving app to paste *the wrong thing* (or nothing) because Windows's paste handler reads the clipboard asynchronously. ~150ms delay is enough.
4. **Chunks transcribed independently can split words at boundaries.** Silence-aware splitting (default 8s min / 25s max with 400ms silence detection) avoids this in the typical case but isn't bulletproof. If it bothers you, add 1-second overlap windows between chunks and trim duplicate text on concatenation.
5. **Sensitivity defaults are calibrated for built-in laptop mics.** Desktop USB mics often have higher gain — you may want to drop `LEVEL_PEAK_GAIN` to 3-4 to keep the meter from pinning.

### Optional: bonus features for the Windows port

Things you didn't add to the Mac version but make sense to consider on Windows:

- **Speaker diarization** — load Sortformer alongside Parakeet, label transcript segments with `Speaker 1: …`, `Speaker 2: …`. Especially nice for meeting-mode dictation.
- **GPU memory release on idle** — Whisper-class models hold ~2GB VRAM. If your workstation has shared workloads (gaming, training), unload the model after N minutes of idle and reload on next hotkey. Adds a small reload-latency tax but frees VRAM.
- **Configurable hotkey via settings UI** — the Mac version hardcodes Right Option; on Windows the keyboard convention is more varied (some people prefer Right Ctrl, some Caps Lock remapped). A settings page in the stats window is low effort.

## When you start the new session

Paste this into the new session along with a one-line "I want to port Starling to Windows 11, here's the spec." The new agent should read this document plus the macOS source as references — no need to read the entire Swift codebase, just `DictationController.swift`, `HotkeyMonitor.swift`, `StreamingTranscriber.swift`, and `SessionStats.swift` for the load-bearing logic.
