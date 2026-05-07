import os
import sys
import traceback

import numpy as np

from .constants import MODEL_ID, PREWARM_SAMPLES


class ParakeetTranscriber:
    def __init__(self) -> None:
        self._model = None

    def load(self, on_status=None, on_ready=None) -> None:
        def status(msg: str) -> None:
            print(msg, file=sys.stderr, flush=True)
            if on_status:
                on_status(msg)

        try:
            status("Loading model...")
            import nemo.collections.asr as nemo_asr
            status("Downloading model (first run only)...")
            self._model = nemo_asr.models.ASRModel.from_pretrained(MODEL_ID)
            self._model.eval()
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
        # NeMo ASRModel.transcribe accepts a list of numpy arrays or file paths.
        results = self._model.transcribe([samples])
        if not results:
            return ""
        r = results[0]
        text = r.text if hasattr(r, "text") else str(r)
        return text.strip()
