import cv2
import numpy as np

# Create healthy palm (skin tone)
palm = np.zeros((640, 640, 3), dtype=np.uint8)
palm[:] = (180, 200, 240) # BGR
# Add some noise
noise = np.random.randn(640, 640, 3) * 10
palm = np.clip(palm + noise, 0, 255).astype(np.uint8)
cv2.imwrite(r'e:\Skin_Cancer\backend\uploads\test_healthy_palm.jpg', palm)

# Create severe wound (bright red/crimson)
wound = np.zeros((640, 640, 3), dtype=np.uint8)
wound[:] = (180, 200, 240) # Skin background
# Add a severe red wound in the center
cv2.rectangle(wound, (200, 200), (440, 440), (20, 20, 220), -1) # BGR (mostly red)
cv2.imwrite(r'e:\Skin_Cancer\backend\uploads\test_severe_wound.jpg', wound)

print("Created synthetic test images.")
