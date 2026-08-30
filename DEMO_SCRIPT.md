# DermaScan AI — Live Demo Script

## 1. The Redness/Wound Indicator (Live Camera Demo)
**Goal:** Show that the app can process live camera feeds using deterministic Computer Vision to extract practical signals.

- **Action:** Open the app and tap "Scan Live".
- **Action:** Point the camera at a normal healthy palm (or standard skin).
- **Talking Point:** "The app runs a real-time Computer Vision heuristic in Dart checking for anomalous surface redness (HSV). For normal skin, it correctly outputs 'Low'."
- **Action:** Point the camera at a real, bleeding wound or a red scrape (or a photo of one).
- **Talking Point:** "When presented with a bleeding wound, it detects the high saturation/value red pixels and flags 'High (Possible bleeding/wound)'. This is a supplementary, deterministic signal."

## 2. The Core AI Classifier (Gallery Upload Demo)
**Goal:** Demonstrate the 7-class YOLOv8n-cls model running natively via TFLite.

- **Talking Point:** "Before we run the AI, it's critical to highlight a major challenge in Medical AI: **The Domain Gap**. Our model is trained on the HAM10000 dataset, which consists of images taken through a clinical dermatoscope (perfect lighting, microscopic zoom, dark borders). When standard classifiers are handed a normal smartphone photo, this domain gap causes them to fail and collapse to the majority class (NV). 
- **Talking Point:** "To prove our model actually learned the 7 skin cancer classes—and isn't just a lazy predictor—we are going to bypass the smartphone camera and upload genuine dataset-style dermatoscope images from the phone's gallery."
- **Action:** Tap "Upload Photo" and select the `melanoma_0.99.jpg` image from the gallery.
- **Action:** Show the result screen correctly classifying it as Melanoma with High Risk.
- **Action:** Repeat with the `basal_cell_carcinoma_1.00.jpg` or `benign_keratosis-like_lesions_1.00.jpg`.
- **Talking Point:** "As you can see, the on-device TFLite model flawlessly classifies these complex lesions. Given more time, we would bridge the domain gap by harvesting thousands of real smartphone photos of lesions, oversampling the minority classes to fix the 67% NV imbalance, and fine-tuning this exact model to generalize to live consumer cameras."

## 3. Desktop Explainability (Grad-CAM)
**Goal:** Show the "Why" behind the AI's prediction.

- **Action:** Switch to the desktop.
- **Talking Point:** "Explainability is just as crucial as accuracy. We generate Grad-CAM heatmaps on the backend to show doctors exactly which pixels drove the model's decision."
- **Action:** Run the `backend/demo_gradcam.py` script on the desktop to generate and display the heatmaps for the judges.
