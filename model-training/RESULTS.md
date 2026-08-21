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

| Model Metric | Value |
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
