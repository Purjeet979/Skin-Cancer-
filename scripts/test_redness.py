import cv2
import numpy as np
import os
import glob

def compute_redness(img_path):
    img = cv2.imread(img_path)
    if img is None:
        return -1
    
    img = cv2.resize(img, (640, 640))
    # Step by 8 to simulate Dart sampling
    sampled = img[::8, ::8]
    
    hsv = cv2.cvtColor(sampled, cv2.COLOR_BGR2HSV)
    
    # In OpenCV HSV, H is 0-179, S is 0-255, V is 0-255
    # Red hue is around 0-10 or 170-179.
    # We want high saturation.
    
    # Mask 1: H in [0, 10]
    lower_red1 = np.array([0, 120, 100]) # Saturation > ~47%, Value > ~39%
    upper_red1 = np.array([10, 255, 255])
    mask1 = cv2.inRange(hsv, lower_red1, upper_red1)
    
    # Mask 2: H in [170, 179]
    lower_red2 = np.array([170, 120, 100])
    upper_red2 = np.array([179, 255, 255])
    mask2 = cv2.inRange(hsv, lower_red2, upper_red2)
    
    mask = mask1 | mask2
    
    red_pixels = np.count_nonzero(mask)
    total_pixels = sampled.shape[0] * sampled.shape[1]
    
    redness_score = red_pixels / total_pixels
    return redness_score

test_images = [
    r'e:\Skin_Cancer\backend\uploads\test_suspicious_mel.jpg', # genuine lesion
    r'e:\Skin_Cancer\backend\uploads\test_severe_wound.jpg',    # real wound (if it exists, wait, do I have a real wound image?)
    r'e:\Skin_Cancer\backend\uploads\test_healthy_palm.jpg'     # healthy palm
]

print("=== Redness Score Test ===")
for path in glob.glob(r'e:\Skin_Cancer\backend\uploads\*.jpg'):
    score = compute_redness(path)
    print(f"Image: {os.path.basename(path):<30} | Redness Score: {score:.4f}")
