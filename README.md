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
- [Repository Structure](#-repository-structure)
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
| 2 | **Grad-CAM Explainability** | Visual heatmap overlay highlighting the feature regions the network evaluated during lesion analysis. |
| 3 | **Offline Referral Queueing & Auto-Sync** | Local SQLite DB (`sqflite`) queues high-risk referrals when offline (`QUEUED_OFFLINE`) and auto-syncs to `/referral` once connectivity returns (`SYNCED`). |
| 4 | **Bilingual Voice Guidance (Hindi & English)** | `flutter_tts`-powered real-time audio instructions (e.g. *"कृपया त्वचा के घाव को कैमरे के केंद्र में रखें"*) with instant language toggle. |
| 5 | **Dermatologist Referral Engine** | FastAPI backend matching high-risk/suspicious cases with the nearest top specialist physicians. |
| 6 | **Smart Skin Validation (YCbCr)** | Rejects non-skin objects (laptops, rooms, etc.) before inference using YCbCr chrominance filtering. |
| 7 | **Anomaly & Severe Inflammation Detection** | `CrRange` algorithms distinguish palm creases and benign skin from ulcerated/bleeding wounds — false-positive-free High Risk overrides. |
| 8 | **Market-Ready Patient Landing Page** | Clean entry screen collecting Patient Name and Contact before scanning; hides technical complexity from end-users. |
| 9 | **Dynamic Network Status** | UI toggles instantly between Live Sync and Offline Mode, tracking airplane-mode changes with no restart required. |
| 10 | **Web Landing Page & Direct APK Download** | Responsive HTML/CSS landing page (`website/`) with SkinVision-style aesthetics, hosting the 74 MB production APK for direct Android download. |

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
│   ├── split_dataset.py           # Stratified dataset splitter (70/15/15)
│   ├── train.py                   # EfficientNet / YOLOv8 training script
│   ├── test.py                    # Evaluation & metrics (Accuracy, F1)
│   └── gradcam.py                 # Grad-CAM heatmap generator
├── website/                       # Responsive Landing Page (HTML/CSS)
│   ├── index.html
│   ├── styles.css
│   └── DermaScanAI.apk            # Pre-built release APK (74.4 MB)
├── test_app_execution_evidence.py # Verification & test suite
└── README.md
```

---

## 🔬 Model Performance & Quantization

**Dataset:** HAM10000 (ISIC 2018 Task 3) — 7 lesion classes: `mel`, `nv`, `bcc`, `akiec`, `bkl`, `df`, `vasc`

| Metric | Value |
|--------|-------|
| Test Accuracy | **78.43%** |
| Macro F1-Score | **0.7290** |
| Full Precision (FP32) | 5.55 MB |
| Quantized (INT8) | **1.43 MB** (74% smaller, no latency impact) |

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

Build a debug APK:

```bash
cd mobile_app
flutter build apk --debug
```

Output: `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`

---

## 🧪 Running Automated Tests

```bash
cd mobile_app
flutter test
```

---

## 📄 Citation & Acknowledgments

- **Dataset:** HAM10000 Dataset 
- **Frameworks:** Flutter, TensorFlow Lite, PyTorch, FastAPI, SQLite

---

<div align="center">

Made with ❤️ for accessible healthcare

</div>
