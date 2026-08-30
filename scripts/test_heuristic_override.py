import cv2
import numpy as np
import urllib.request
import os

def test_image(image_url, name):
    print(f"\\n--- Testing Scenario: {name} ---")
    try:
        req = urllib.request.urlopen(image_url)
        arr = np.asarray(bytearray(req.read()), dtype=np.uint8)
        img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    except Exception as e:
        print(f"Failed to load image: {e}")
        return

    # Resize to 640x640 like Dart
    img = cv2.resize(img, (640, 640))
    
    # Convert BGR (OpenCV) to RGB
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    
    totalLuma = 0.0
    minCr = 255.0
    maxCr = 0.0
    
    step = 8
    pixels_sampled = 0
    
    # Fast vectorized calculation to match Dart's loop perfectly
    # Dart: Luma = 0.299 * r + 0.587 * g + 0.114 * b
    # Dart: Cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b
    
    sampled_img = img[0:640:step, 0:640:step]
    
    R = sampled_img[:,:,0].astype(np.float32)
    G = sampled_img[:,:,1].astype(np.float32)
    B = sampled_img[:,:,2].astype(np.float32)
    
    Luma = 0.299 * R + 0.587 * G + 0.114 * B
    Cr = 128 + 0.5 * R - 0.418688 * G - 0.081312 * B
    
    avgLuma = np.mean(Luma)
    minCr = np.min(Cr)
    maxCr = np.max(Cr)
    crRange = maxCr - minCr
    
    # Heatmap Targeting Logic (Darkest Spot)
    score_matrix = avgLuma - Luma
    max_score = np.max(score_matrix)
    max_idx = np.unravel_index(np.argmax(score_matrix, axis=None), score_matrix.shape)
    spotY = max_idx[0] * step
    spotX = max_idx[1] * step
    
    # Calculate old score for comparison (Reddest Spot)
    old_score_matrix = Cr - (Luma * 0.5)
    old_max_idx = np.unravel_index(np.argmax(old_score_matrix, axis=None), old_score_matrix.shape)
    oldSpotY = old_max_idx[0] * step
    oldSpotX = old_max_idx[1] * step

    print(f"Luma Avg: {avgLuma:.1f}")
    print(f"Cr Min: {minCr:.1f}, Cr Max: {maxCr:.1f}")
    print(f"Cr Range: {crRange:.1f}")
    
    if crRange > 32.0 and maxCr > 158.0:
        print("OLD HEURISTIC: [FAIL] Would have incorrectly overridden to Severe Inflammation!")
    else:
        print("OLD HEURISTIC: [PASS] Would have sent to TFLite model safely.")
        
    if crRange > 80.0 and maxCr > 190.0:
        print("NEW OPTION B: [TRIGGERED] Severe Inflammation / Ulcerated Lesion Detected (Risk: HIGH)")
    else:
        print("NEW OPTION B: [BYPASSED] Sending to HAM10000 TFLite Model... -> (Will output normal classification)")
        
    print(f"OLD Heatmap Target (Reddest): X={oldSpotX}, Y={oldSpotY}")
    print(f"NEW Heatmap Target (Darkest): X={spotX}, Y={spotY}")

# 1. Warm-lit lesion (reproducing the bug case)
# Using a typical warm-lit melanoma/nevus from ISIC archive
test_image("https://upload.wikimedia.org/wikipedia/commons/2/23/Melanoma.jpg", "Warm-Lit Genuine Lesion")

# 2. Genuine HAM10000 image - Benign Keratosis
test_image("https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Seborrheic_keratosis.jpg/640px-Seborrheic_keratosis.jpg", "Genuine Lesion (Benign Keratosis)")

# 3. Genuine HAM10000 image - Basal Cell Carcinoma
test_image("https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Basal_cell_carcinoma.jpg/640px-Basal_cell_carcinoma.jpg", "Genuine Lesion (Basal Cell Carcinoma)")

# 4. Genuinely red/bloody wound (Scraped knee or open ulcer)
test_image("https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Skin_abrasion.JPG/640px-Skin_abrasion.JPG", "Open Bleeding Wound (Scraped Knee)")
