# AgroLens Samegrelo — Demo Checklist

Run through this before presenting. The app is offline; no network is required.

## One-time setup

```powershell
cd mobile
flutter pub get
flutter run            # Android/iOS device or emulator (TFLite needs native)
```

The nut-quality model is already bundled at `mobile/assets/nut_quality_model.tflite`.
Web preview runs the UI but not TFLite inference (use a device for inference).

## Live demo steps

- [ ] **App opens** to the AgroLens home screen.
- [ ] **Model loads** — "Trained model verified • 94.79% single-view test accuracy"
      appears under *Inspect Nut Quality*. (If it instead shows a demo notice,
      the integrity check failed — re-run `export_nut_quality_tflite.py`.)
- [ ] **Single-image mode works** — *Inspect Nut Quality (single image)* →
      pick/take a nut photo → Analyze → result screen shows class + confidence.
- [ ] **Decision states show** — a clear nut gives *Confident*; a blurry/low-confidence
      photo gives *Uncertain — retake photo*; a quality nut with visible damage gives
      *Possible damage — manual inspection recommended*.
- [ ] **Multi-view mode works** — *Multi-view Nut Inspection* → add 5–10 photos of
      one nut → Analyze → averaged prediction, probability bars, and "X/10 views agree".
- [ ] **Result screen shows recommendation** — Georgian guidance + safety warning.
- [ ] **History saves** — save a result, open *Diagnosis History*, see it listed.
- [ ] **About screen explains limitations** — scope statement + single-view risk.
- [ ] **Model card exists** — `docs/MODEL_CARD_NUT_QUALITY.md`.
- [ ] **Dataset card exists** — `docs/DATASET_CARD_NUT_QUALITY.md`.

## Talking points

- One canonical label system everywhere: `quality_nuts`, `nuts_kernel`, `damaged_nuts`.
- 94.79% single-image / 98.74% physical-nut (multi-view) accuracy; macro F1 ≈ 0.9874.
- Leakage-safe split by physical nut; audited 0 corrupt / 0 duplicate / 0 leakage.
- Main risk: in single-view mode a damaged nut can read as quality — multi-view fixes most of it.
- Scope: close-up quality grading only — not leaf disease, fungal spot, stink-bug, or fruit rot.
