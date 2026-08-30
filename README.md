<div align="center">

# 🩺 DermaScan AI

### On-Device Skin Cancer Screening & Referral System

**Offline-first skin lesion screening** combining deep learning classification, Grad-CAM explainability, INT8 on-device quantization, a referral backend, and a Flutter app built for low-connectivity environments.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![TensorFlow Lite](https://img.shields.io/badge/TensorFlow_Lite-FF6F00?style=flat&logo=tensorflow&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=flat&logo=sqlite&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

**🔗 Live Site:** [dermascans.netlify.app](https://dermascans.netlify.app/)

</div>

---

## 📑 Table of Contents

- [Live Demo](#-live-demo)
- [Key Features](#-key-features)
- [Challenges & Engineering Decisions](#-challenges--engineering-decisions)
- [Repository Structure](#-repository-structure)
- [Demo Images for Testing](#-demo-images-for-testing)
- [Model Performance & Quantization](#-model-performance--quantization)
- [Quick Start Guide](#-quick-start-guide)
- [Running Automated Tests](#-running-automated-tests)
- [Citation & Acknowledgments](#-citation--acknowledgments)

---

## 🌐 Live Demo

**Web Landing Page:** [https://dermascans.netlify.app/](https://dermascans.netlify.app/) — download the production APK directly from here.

---

## 🌟 Key Features

| # | Feature | Description |
|---|---------|-------------|
| 1 | **On-Device TFLite Inference** | Quantized **1.43 MB INT8 TFLite model** (`assets/model/best_int8.tflite`) bundled inside the app. 100% local classification in **under 35 ms/scan** — zero server latency, zero network transmission. |
| 2 | **7-Class Skin Lesion Classification** | Classifies into 7 HAM10000 categories: Melanoma (MEL), Basal Cell Carcinoma (BCC), Actinic Keratosis (AKIEC), Benign Keratosis (BKL), Dermatofibroma (DF), Melanocytic Nevus (NV), and Vascular Lesion (VASC). |
| 3 | **Grad-CAM Explainability** | Visual heatmap overlay highlighting the feature regions the network evaluated during lesion analysis — shows *why* the AI made its decision. |
| 4 | **Surface Redness / Wound Detection** | Supplementary HSV-based Computer Vision heuristic that detects anomalous surface redness (bleeding, inflammation) independently of the ML model. Works on any image — including live smartphone photos. |
| 5 | **Offline Referral Queueing & Auto-Sync** | Local SQLite DB (`sqflite`) queues high-risk referrals when offline (`QUEUED_OFFLINE`) and auto-syncs to `/referral` once connectivity returns (`SYNCED`). |
| 6 | **Bilingual Voice Guidance (Hindi & English)** | `flutter_tts`-powered real-time audio instructions (e.g. *"कृपया त्वचा के घाव को कैमरे के केंद्र में रखें"*) with instant language toggle. |
| 7 | **Dermatologist Referral Engine** | FastAPI backend matching high-risk/suspicious cases with the nearest top specialist physicians. |
| 8 | **Smart Skin Validation (YCbCr)** | Rejects non-skin objects (laptops, rooms, etc.) before inference using dual RGB + YCbCr chrominance filtering. |
| 9 | **Dynamic Network Status** | UI toggles instantly between Live Sync and Offline Mode, tracking airplane-mode changes with no restart required. |
| 10 | **Web Landing Page & Direct APK Download** | Responsive HTML/CSS landing page (`website/`) hosting the production APK for direct Android download. |

---

## 🧠 Challenges & Engineering Decisions

### The Domain Gap Problem

Our YOLOv8n-cls model was trained on the **HAM10000 dataset** — 10,015 clinical images captured through professional **dermatoscopes** (specialized medical instruments that provide consistent lighting, microscopic magnification, and a standardized dark border).

When tested on **dermatoscope-style images from its own validation set**, the model correctly classified all 7 lesion types with high confidence:

| True Class | Predicted | Confidence |
|---|---|---|
| Actinic Keratoses | ✅ Actinic Keratoses | 0.277 |
| Basal Cell Carcinoma | ✅ Basal Cell Carcinoma | 0.985 |
| Benign Keratosis | ✅ Benign Keratosis | 0.998 |
| Dermatofibroma | ✅ Dermatofibroma | 0.715 |
| Melanocytic Nevi | ✅ Melanocytic Nevi | 0.983 |
| Melanoma | ✅ Melanoma | 0.998 |
| Vascular Lesions | ✅ Vascular Lesions | 0.990 |

However, when presented with **standard smartphone camera photos**, the model defaults to the majority class (NV) with uniformly high confidence — a classic **domain-gap collapse**. The pixel-level feature distribution of smartphone photos (variable lighting, no magnification, background clutter) is so different from dermatoscope images that the model treats all phone photos as out-of-distribution noise.

### How We'd Fix This With More Time

- **Fine-tune on real smartphone photos** of skin lesions to bridge the domain gap
- **Oversample minority classes** (HAM10000 is 67% NV) to reduce majority-class bias
- **Apply domain adaptation techniques** (style transfer, CycleGAN) to synthetically transform dermatoscope images into smartphone-like images

---

## 📂 Repository Structure

```text
Skin_Cancer/
├── mobile_app/                    # Flutter Mobile Application
│   ├── assets/
│   │   ├── model/best_int8.tflite # Bundled INT8 quantized TFLite model (1.43 MB)
│   │   └── labels.txt             # 7 HAM10000 class labels
│   ├── lib/
│   │   ├── main.dart              # App entry point
│   │   ├── screens/               # CaptureScreen, ResultScreen, ReferralScreen
│   │   └── services/              # TfliteClassifier, OfflineQueueService, TtsService
│   └── test/                      # Automated unit tests
├── backend/                       # FastAPI Referral Backend
│   ├── main.py                    # Endpoints: /screen, /referral, /dermatologists
│   ├── database.py                # SQLite setup & seed dermatologist data
│   └── mock_dermatologists.json   # Seed specialist directory
├── model-training/                # ML Model Training & Evaluation
│   ├── train_real.py              # YOLOv8n-cls training on real HAM10000
│   ├── split_dataset.py           # Stratified dataset splitter (70/15/15)
│   ├── train.py                   # EfficientNet / YOLOv8 training script
│   ├── test.py                    # Evaluation & metrics (Accuracy, F1)
│   └── gradcam.py                 # Grad-CAM heatmap generator
├── scripts/                       # Utility & validation scripts
│   ├── prepare_hf_dataset.py      # Download HAM10000 from HuggingFace
│   ├── prepare_demo_images.py     # Extract high-confidence demo images
│   ├── test_yolo_val.py           # 7-class validation test
│   ├── test_redness.py            # HSV redness algorithm test
│   └── ...                        # Other dev/debug scripts
├── demo_images/                   # Pre-selected high-confidence test images
├── website/                       # Responsive Landing Page (HTML/CSS)
│   ├── index.html
│   ├── styles.css
│   └── DermaScanAI.apk            # Pre-built release APK (~74 MB)
├── DEMO_SCRIPT.md                 # Live demo instructions for judges
└── README.md
```

---

## 🖼️ Demo Images for Testing

The [`demo_images/`](demo_images/) folder contains **5 pre-selected, high-confidence images** directly from the HAM10000 validation set. These are real clinical dermatoscope images that the model correctly classifies with near-perfect confidence:

| Image | True Class | Model Confidence |
|---|---|---|
| `melanoma_0.99.jpg` | Melanoma (MEL) — **High Risk** | 99% |
| `basal_cell_carcinoma_1.00.jpg` | Basal Cell Carcinoma (BCC) — **Medium Risk** | 100% |
| `melanocytic_Nevi_1.00.jpg` | Melanocytic Nevus (NV) — Low Risk | 100% |
| `vascular_lesions_1.00.jpg` | Vascular Lesion (VASC) — Low Risk | 100% |
| `benign_keratosis-like_lesions_1.00.jpg` | Benign Keratosis (BKL) — Low Risk | 100% |

**How to use:** Transfer these images to your phone's gallery, then use the **"Upload Photo"** button in the app to classify them. This demonstrates the model's real classification ability across multiple lesion types.

---

## 🔬 Model Performance & Quantization

**Dataset:** HAM10000 (ISIC 2018 Task 3) — 10,015 dermatoscopic images across 7 lesion classes

**Architecture:** YOLOv8n-cls (pretrained on ImageNet, fine-tuned for 15 epochs on real HAM10000 data)

> **Note on Model Weights:** The raw dataset (~1.5 GB) and compiled `best.pt` weights are excluded from version control to keep the repository lightweight.
> - **Download Weights:** You can download the pre-trained `best.pt` weights from the [GitHub Releases](#).
> - **Reproduce Training:** Run `python scripts/prepare_hf_dataset.py` followed by `python model-training/train_real.py` (takes ~3.5 hours on CPU).

| Metric | Value |
|--------|-------|
| Test Accuracy | **78.43%** |
| Macro F1-Score | **0.7290** |
| Full Precision (FP32) | 5.55 MB |
| Quantized (INT8) | **1.43 MB** (74% smaller, no latency impact) |
| Inference Speed (On-Device) | **< 35 ms/scan** |

---

## 🚀 Quick Start Guide

### 1. Backend Server Setup

```bash
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install fastapi uvicorn pydantic
python backend/main.py
```

> `sqlite3` is part of the Python standard library — don't `pip install` it.

Backend runs at `http://127.0.0.1:8000`.

### 2. Flutter Mobile App Setup

```bash
cd mobile_app
flutter pub get
flutter run
```

Build a release APK:

```bash
cd mobile_app
flutter build apk --release
```

Output: `mobile_app/build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Running Automated Tests

```bash
cd mobile_app
flutter test
```

Validation scripts (run from repo root):

```bash
# Verify model classifies all 7 classes correctly
python scripts/test_yolo_val.py

# Test redness detection algorithm
python scripts/test_redness.py
```

---

## 📄 Citation & Acknowledgments

- **Dataset:** [HAM10000](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/DBW86T) — Tschandl et al., 2018
- **Frameworks:** Flutter, TensorFlow Lite, Ultralytics YOLOv8, FastAPI, SQLite
- **Model Architecture:** YOLOv8n-cls (Ultralytics) with ImageNet pretrained weights

---

<div align="center">

Made with ❤️ for accessible healthcare

</div>
