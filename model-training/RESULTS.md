# DermaScan AI — Model Training Results (M1 Baseline)

## Model Configuration
- **Architecture**: YOLOv8n-cls (Nano Classification)
- **Parameters**: 1,447,255 (~1.4M)
- **Input Size**: 640x640
- **Epochs**: 30
- **Classes**: 7 categories (ISIC2018 Task3 / HAM10000)
  - `akiec`: Actinic keratoses and intraepithelial carcinoma
  - `bcc`: Basal cell carcinoma
  - `bkl`: Benign keratosis-like lesions
  - `df`: Dermatofibroma
  - `mel`: Melanoma
  - `nv`: Melanocytic nevi
  - `vasc`: Vascular lesions

## Benchmark Metrics

> [!WARNING]
> **Important Context regarding the M1 Baseline (84.13%)**: The original training run in M1 was inadvertently performed on a procedurally generated synthetic dataset (MS Paint-style brown/red circles on a grey background), rather than the real HAM10000 dataset. While the training logs did genuinely reach **84.13% Top-1 Accuracy**, this metric measured the model's ability to distinguish synthetic colored circles, meaning it had zero real-world validity. 
> 
> *A subsequent attempt to train on the authentic HAM10000 dataset was aborted due to CPU compute limits (estimated >3 hours). For the live demo, the mobile app serves as a frontend UI shell while real Grad-CAM inference is demonstrated on the desktop backend.*

| Model Metric | Value (Synthetic M1 Baseline) |
| --- | --- |
| **Top-1 Accuracy** | **84.13%** (0.841) |
| **Top-5 Accuracy** | **99.80%** (0.998) |
| **Validation Loss** | 1.3365 |
| **Training Loss** | 0.2037 |
| **Model File Size (PyTorch)** | ~5.3 MB |

## Training & Evaluation Logs Summary
- Training log stored at `model-training/train_with_aug.log`
- Results CSV stored at `model-training/result_with_aug/yolov8n/results.csv`
- Confusion matrix visual stored at `model-training/result_with_aug/yolov8n/confusion_matrix.png`
