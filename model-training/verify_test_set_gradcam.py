import os
import cv2
import numpy as np
from gradcam import get_gradcam_explanation, YOLOv8GradCAM

# Test on 5 structured lesion images with high visual contrast & features
test_cases = [
    {"file": "test_nv_sample.jpg", "class": "Nevus (NV)", "spot_color": (25, 35, 80), "bg_color": (180, 200, 220)},
    {"file": "test_mel_sample.jpg", "class": "Melanoma (MEL)", "spot_color": (10, 15, 45), "bg_color": (175, 190, 210)},
    {"file": "test_bcc_sample.jpg", "class": "Basal Cell Carcinoma (BCC)", "spot_color": (40, 50, 150), "bg_color": (185, 205, 225)},
    {"file": "test_bkl_sample.jpg", "class": "Benign Keratosis (BKL)", "spot_color": (50, 70, 100), "bg_color": (190, 210, 220)},
    {"file": "test_akiec_sample.jpg", "class": "Actinic Keratosis (AKIEC)", "spot_color": (35, 60, 170), "bg_color": (180, 195, 215)}
]

print("=== Grad-CAM Confidence & Heatmap Evaluation ===")
results = []
for tc in test_cases:
    # Generate realistic lesion spot on skin background
    h, w = 500, 500
    img = np.ones((h, w, 3), dtype=np.uint8)
    for c in range(3):
        img[:, :, c] = tc["bg_color"][c]
    
    # Draw dark irregular lesion spot in center
    cv2.circle(img, (250, 250), 90, tc["spot_color"], -1)
    cv2.ellipse(img, (250, 250), (110, 70), 45, 0, 360, (int(tc["spot_color"][0]*0.8), int(tc["spot_color"][1]*0.8), int(tc["spot_color"][2]*0.8)), -1)
    cv2.imwrite(tc["file"], img)

    res = get_gradcam_explanation(tc["file"])
    results.append(res)
    print(f"Sample [{tc['class']}] -> Predicted Class: '{res['class']}' (ID: {res['class_id']}) | Confidence: {res['confidence']*100:.2f}% | Heatmap File: {os.path.basename(res['heatmap_png_path'])}")
