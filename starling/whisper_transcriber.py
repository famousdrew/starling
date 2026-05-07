import sys
import traceback

import numpy as np

from .constants import PREWARM_SAMPLES


class WhisperTranscriber:
    def __init__(self, model_size: str = "small.en") -> None:
        self._model = None
        self._model_size = model_size

    def load(self, on_status=None, on_ready=None) -> None:
        def status(msg: str) -> None:
            print(msg, file=sys.stderr, flush=True)
            if on_status:
                on_status(msg)

        try:
            status(f"Loading Whisper {self._model_size} model...")
            from faster_whisper import WhisperModel
            status("Downloading model (first run only)...")
            self._model = WhisperModel(
                self._model_size,
                device="cpu",
                compute_type="int8",
            )
            status("Warming up...")
            self.transcribe(np.zeros(PREWARM_SAMPLES, dtype=np.float32))
            print("Pre-warm complete. Ready.", file=sys.stderr, flush=True)
            if on_ready:
                on_ready()
        except Exception:
            traceback.print_exc()
            status("Model load failed - transcription disabled.")

    def transcribe(self, samples: np.ndarray) -> str:
        if self._model is None:
            return ""
        segments, _ = self._model.transcribe(
            samples,
            language="en",
            beam_size=1,
            vad_filter=True,
        )
        return " ".join(s.text.strip() for s in segments).strip()
