# DermaScan AI — On-Device Skin Cancer Screening & Referral System

DermaScan AI is an offline-first skin lesion screening solution that combines deep learning classification (HAM10000 dataset), Grad-CAM visual explainability, INT8 on-device model quantization, a referral backend service, and a Flutter mobile application designed for low-connectivity environments.

---

## 🌟 Key Features

1. **On-Device TFLite Inference (Zero Internet Needed)**:
   - Quantized **1.43 MB INT8 TFLite model** (`assets/model/best_int8.tflite`) bundled directly inside the mobile app.
   - 100% local classification running in under 35 ms per scan with zero server latency or network transmission.

2. **Grad-CAM Explainability Heatmaps**:
   - Visual heatmap overlay highlighting key feature regions evaluated by the neural network during lesion analysis.

3. **Offline Referral Queueing & Auto-Sync**:
   - Local SQLite database (`sqflite`) queues high-risk patient referrals when offline (`QUEUED_OFFLINE`).
   - Automatically synchronizes queued appointments to the backend API (`/referral`) when network connectivity is restored (`SYNCED`).

4. **Hindi Voice Guidance**:
   - Integrated Text-to-Speech (`flutter_tts`) providing real-time Hindi audio instructions (*"कृपया त्वचा के घाव को कैमरे के केंद्र में रखें"*) during capture.

5. **Dermatologist Referral Engine (FastAPI)**:
   - Backend service matching high-risk / suspicious cases with the top nearest specialist physicians.

---

## 📂 Repository Structure

```text
Skin_Cancer/
├── mobile_app/                  # Flutter Mobile Application
│   ├── assets/
│   │   ├── model/best_int8.tflite # Bundled INT8 Quantized TFLite Model (1.43 MB)
│   │   └── labels.txt           # 7 HAM10000 Class Labels
│   ├── lib/
│   │   ├── main.dart            # Flutter App Entry point
│   │   ├── screens/             # CaptureScreen, ResultScreen, ReferralScreen
│   │   └── services/            # TfliteClassifier, OfflineQueueService, TtsService
│   └── test/                    # Automated Unit Tests
├── backend/                     # FastAPI Referral Backend
│   ├── main.py                  # FastAPI server endpoints (/screen, /referral, /dermatologists)
│   ├── database.py              # SQLite database setup & seed dermatologist data
│   └── mock_dermatologists.json # Seed specialist directory
├── model-training/              # ML Model Training & Evaluation
│   ├── split_dataset.py         # Stratified dataset splitter (70/15/15)
│   ├── train.py                 # EfficientNet / YOLOv8 model training script
│   ├── test.py                  # Evaluation & metric generation (Accuracy, F1 score)
│   └── gradcam.py               # Grad-CAM heatmap generator
├── test_app_execution_evidence.py # Verification & test suite
└── README.md
```

---

## 🔬 Model Performance & Quantization

- **Dataset**: HAM10000 (ISIC2018 Task 3) — 7 Lesion Classes (`mel`, `nv`, `bcc`, `akiec`, `bkl`, `df`, `vasc`).
- **Test Accuracy**: **78.43%**
- **Macro F1-Score**: **0.7290**
- **Quantization**:
  - Full Precision Model (FP32): 5.55 MB
  - **Quantized Model (INT8)**: **1.43 MB** (74% size reduction with zero latency impact).

---

## 🚀 Quick Start Guide

### 1. Backend Server Setup
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install fastapi uvicorn pydantic sqlite3
python backend/main.py
```
Backend server runs at `http://127.0.0.1:8000`.

### 2. Flutter Mobile Application Setup
```bash
cd mobile_app
flutter pub get
flutter run
```

To build the debug APK:
```bash
cd mobile_app
flutter build apk --debug
```
Output APK file is generated at `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`.

### 3. Running Automated Tests
```bash
cd mobile_app
flutter test
```

---

## 📄 Citation & Acknowledgments
- **Dataset**: HAM10000 Dataset / ISIC 2018 Challenge.
- **Frameworks**: Flutter, TensorFlow Lite, PyTorch, FastAPI, SQLite.
