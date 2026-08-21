import os
import cv2
import numpy as np
from gradcam import get_gradcam_explanation

# Create sample lesion images representing distinct visual patterns
samples = [
    {"filename": "sample_nv.jpg", "color": (30, 45, 90), "bg": 220, "name": "Melanocytic Nevus (NV)"},
    {"filename": "sample_mel.jpg", "color": (15, 20, 50), "bg": 200, "name": "Melanoma (MEL)"},
    {"filename": "sample_bcc.jpg", "color": (50, 60, 160), "bg": 210, "name": "Basal Cell Carcinoma (BCC)"},
    {"filename": "sample_bkl.jpg", "color": (60, 80, 110), "bg": 215, "name": "Benign Keratosis (BKL)"},
    {"filename": "sample_akiec.jpg", "color": (40, 70, 180), "bg": 205, "name": "Actinic Keratosis (AKIEC)"}
]

print("=== Grad-CAM Multi-Sample Verification ===")
for s in samples:
    img = np.ones((400, 400, 3), dtype=np.uint8) * s["bg"]
    # Draw characteristic lesion shape & texture
    cv2.circle(img, (200, 200), 80, s["color"], -1)
    cv2.ellipse(img, (200, 200), (95, 60), 30, 0, 360, (int(s["color"][0]*0.7), int(s["color"][1]*0.7), int(s["color"][2]*0.7)), -1)
    
    cv2.imwrite(s["filename"], img)
    
    res = get_gradcam_explanation(s["filename"])
    print(f"[{s['name']}] -> Predicted: {res['class']} (ID {res['class_id']}) | Confidence: {res['confidence']*100:.2f}% | Output: {os.path.basename(res['heatmap_png_path'])}")
