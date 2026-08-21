# TASK.md — DermaScan AI
### Smartphone-Based Skin Cancer Screening + Referral (Omni_BioTech_12)

> **Agent instructions:** Work through the milestones below **in order**. Each milestone has an explicit **Definition of Done (DoD)**. Do not skip ahead to a later milestone until the current one's DoD is met. Ask for clarification only if a required credential/API key is missing — otherwise use the stated defaults/mocks and keep moving.

---

## 0. Context

**Base repo (clone as-is, do not rewrite from scratch):**
`https://github.com/uts58/yolov8-ham10000.git`

This repo already gives us:
- `data_processing.py` — organizes ISIC2018/HAM10000 into YOLOv8 classification folder structure
- `train.py` — trains YOLOv8n/s/m/l/x classification models on the lesion dataset
- `test.py` — generates classification reports + confusion matrices

**Why we are NOT building the model from zero:** dozens of public repos already do "photo → CNN → benign/malignant" classification on HAM10000 (see research notes below). That alone will not differentiate us in judging. **We reuse this repo purely as the training baseline** and spend our actual build time on the three things almost no public repo has, listed in section 1.

**Known similar public work (for reference / to explicitly avoid duplicating):**
- Flutter + MobileNetV2 HAM10000 apps (classification-only, no referral/offline/explainability combined)
- ResNeXt101 / EfficientNetB1 / ResNet50 HAM10000 classifiers (Kaggle notebooks, no app layer)
- This exact repo's YOLOv8 approach, published as Saha et al., IEEE HealthCom 2024 (classification benchmark only, no product layer)
- LMS-ViT (2024–25) — vision transformer, smartphone real-time, ~90% accuracy (research only, not shipped as an app)

---

## 1. Our USP (the actual hackathon differentiation — build these three, non-negotiable)

| # | USP | Why it matters | What almost no repo has |
|---|-----|-----------------|--------------------------|
| 1 | **Referral workflow** | Problem statement explicitly asks for "flag AND refer," not just classify | Nearest-dermatologist lookup + booking flow, end-to-end from scan to appointment |
| 2 | **Grad-CAM explainability** | Builds trust for non-specialist users/health workers; judges love visual proof the model isn't a black box | Heatmap overlay showing *where* the model looked |
| 3 | **Offline-first native mobile app + regional language** | Target users are rural/low-connectivity; most existing repos are web-only or Colab notebooks | On-device TFLite inference (no internet needed) + voice guidance in a regional language for capture |

---

## 2. Milestones

### M1 — Baseline setup (reuse existing repo)
- [ ] Clone `uts58/yolov8-ham10000` into `/model-training`
- [ ] `pip install ultralytics scikit-learn matplotlib seaborn pandas`
- [ ] Run `data_processing.py` against the ISIC2018/HAM10000 dataset
- [ ] Run `train.py` — but **override to train only YOLOv8n (nano)**, not all 5 sizes (nano is the only one small enough for on-device mobile inference; training s/m/l/x wastes hackathon time)
- [ ] Run `test.py`, confirm a classification report + confusion matrix is generated

**DoD:** A trained `yolov8n-cls` weights file (`best.pt`) exists, with a documented accuracy/F1 in `/model-training/RESULTS.md`.

---

### M2 — Grad-CAM explainability layer
- [ ] Add `gradcam.py` in `/model-training` that hooks into the last conv layer of the trained YOLOv8n classifier
- [ ] Given an input image + `best.pt`, output a heatmap overlay (use `pytorch-grad-cam` library, works with Ultralytics models via a wrapper — do not hand-roll Grad-CAM math)
- [ ] Save overlay as PNG alongside the raw prediction (class + confidence)
- [ ] Unit-test on 5 sample images from the test set — confirm heatmap visibly concentrates on the lesion region, not background skin

**DoD:** Given any image path, one function call returns `{class, confidence, heatmap_png_path}`.

---

### M3 — Export for on-device / offline inference
- [ ] Export trained `best.pt` → `.tflite` (Ultralytics supports `model.export(format="tflite")`)
- [ ] Quantize to INT8 if size/latency requires it (target: <15MB model file, <500ms inference on a mid-range phone)
- [ ] Verify exported model produces the same top-1 class as the PyTorch model on 10 held-out test images (sanity check, not full re-validation)

**DoD:** A `.tflite` file exists and is confirmed to produce matching predictions to the PyTorch baseline.

---

### M4 — Referral workflow (backend)
- [ ] Build a small **FastAPI** service (`/backend`) with:
  - `POST /screen` — accepts image, runs inference (M1+M2), returns `{risk_level, confidence, heatmap_url}`
  - `GET /dermatologists?lat=&lng=` — returns nearest dermatologists from a **mock/seed dataset** (10–15 fake or public-directory entries with name, distance, phone, next available slot — do not scrape real clinic data without permission)
  - `POST /referral` — creates a referral record (patient info + screening result + selected dermatologist) and returns a booking confirmation with a reference ID
- [ ] Store referral records in SQLite/PostgreSQL (SQLite is fine for hackathon demo)
- [ ] If `risk_level == "suspicious"` → API response must include a `referral_recommended: true` flag and the top 3 nearest dermatologists automatically

**DoD:** A suspicious-case image, when POSTed to `/screen`, results in a referral-ready response with dermatologist options — demonstrable via curl/Postman even before the app UI is done.

---

### M5 — Mobile app (Flutter, native, offline-capable)
- [ ] Scaffold a Flutter app (`/app`) with three screens:
  1. **Capture** — camera view with on-screen guidance (framing box + "hold steady" cue)
  2. **Result** — shows risk level, confidence, Grad-CAM heatmap overlay on the photo
  3. **Referral** — if suspicious: list of nearby dermatologists + "Book" button; if low-risk: "Re-screen in 3 months" reminder option
- [ ] Bundle the `.tflite` model **inside the app** (use `tflite_flutter` package) so classification works with **zero internet connectivity**
- [ ] Referral screen calls the FastAPI backend **only when online**; if offline, queue the referral request locally and sync when connectivity returns
- [ ] Add regional-language voice guidance during capture (start with **Hindi**, using on-device TTS — `flutter_tts` — reading out capture instructions; make the language list configurable so more languages can be added later)

**DoD:** APK builds and runs on an emulator/device; a photo can be classified with **airplane mode on**; referral screen correctly shows "queued for sync" when offline.

---

### M6 — Integration polish + demo script
- [ ] Wire M4 (backend) and M5 (app) together end-to-end
- [ ] Write `/DEMO_SCRIPT.md`: a 3–4 minute walkthrough — capture → offline classification → Grad-CAM shown → (toggle wifi on) → referral booked
- [ ] Add a top-level `README.md` explaining: problem statement, architecture diagram (ASCII or image), setup steps, and the 3 USPs called out explicitly

**DoD:** A cold-start reviewer can read `README.md` + `DEMO_SCRIPT.md` and reproduce the demo without asking questions.

---

## 3. Explicit non-goals (do not build these — out of scope for hackathon timeframe)

- Do NOT pursue real regulatory/medical-device certification claims — this is a **screening aid**, always label it as such in UI copy
- Do NOT train all 5 YOLOv8 sizes — nano only (mobile constraint)
- Do NOT scrape real dermatologist directories/PII — use clearly-marked mock data
- Do NOT attempt multi-language voice support beyond Hindi for the hackathon demo — architect it to be extensible, but only ship one language

---

## 4. Tech stack summary

| Layer | Choice |
|---|---|
| Model training | Ultralytics YOLOv8n-cls (from base repo) |
| Explainability | pytorch-grad-cam |
| On-device inference | TFLite (INT8 quantized) via `tflite_flutter` |
| Mobile app | Flutter (Android first, iOS optional) |
| Backend | FastAPI + SQLite |
| Voice guidance | `flutter_tts` (Hindi) |
| Dataset | HAM10000 / ISIC2018 |

---

## 5. Suggested repo structure

```
dermascan-ai/
├── model-training/        # cloned base repo + gradcam.py + export script + RESULTS.md
├── backend/                # FastAPI service
├── app/                     # Flutter app
├── DEMO_SCRIPT.md
└── README.md
```
