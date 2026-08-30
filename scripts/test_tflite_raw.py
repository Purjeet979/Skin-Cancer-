import numpy as np
import tensorflow as tf
from PIL import Image
import cv2

# Load the model
model_path = r'e:\Skin_Cancer\model-training\result_with_aug\yolov8n\weights\best_saved_model\best_float32.tflite'
interpreter = tf.lite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"Input details: {input_details[0]['shape']}, dtype: {input_details[0]['dtype']}")

# Create 5 dummy images
images = {
    'Solid Red (Blood/Wound)': np.full((640, 640, 3), [255, 0, 0], dtype=np.uint8),
    'Solid Green (Random)': np.full((640, 640, 3), [0, 255, 0], dtype=np.uint8),
    'Solid Blue (Random)': np.full((640, 640, 3), [0, 0, 255], dtype=np.uint8),
    'Solid White (Blank)': np.full((640, 640, 3), [255, 255, 255], dtype=np.uint8),
    'Solid Black (Shadow)': np.full((640, 640, 3), [0, 0, 0], dtype=np.uint8),
}

def softmax(x):
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum(axis=1, keepdims=True)

def run_inference(img, use_mean_std=True):
    # Preprocess
    img = img.astype(np.float32) / 255.0
    if use_mean_std:
        mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
        std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
        img = (img - mean) / std
    
    img = np.expand_dims(img, axis=0) # [1, 640, 640, 3]
    
    # Int8 quantization requires setting the tensor manually if it's float model taking int8
    # Let's check the input type
    if input_details[0]['dtype'] == np.int8:
        scale, zero_point = input_details[0]['quantization']
        img = (img / scale + zero_point).astype(np.int8)
    
    interpreter.set_tensor(input_details[0]['index'], img)
    interpreter.invoke()
    
    output = interpreter.get_tensor(output_details[0]['index'])
    if output_details[0]['dtype'] == np.int8:
        scale, zero_point = output_details[0]['quantization']
        output = (output.astype(np.float32) - zero_point) * scale
        
    probs = softmax(output)[0]
    return probs

labels = ['akiec', 'bcc', 'bkl', 'df', 'mel', 'nv', 'vasc']

print("\n--- TEST 1: Using Mean/Std Normalization (Current Dart Code) ---")
for name, img in images.items():
    probs = run_inference(img, use_mean_std=True)
    max_idx = np.argmax(probs)
    print(f"{name:<25}: Label={labels[max_idx]:<5} | Probs={np.round(probs, 4)}")

print("\n--- TEST 2: NO Mean/Std (Just / 255.0) ---")
for name, img in images.items():
    probs = run_inference(img, use_mean_std=False)
    max_idx = np.argmax(probs)
    print(f"{name:<25}: Label={labels[max_idx]:<5} | Probs={np.round(probs, 4)}")
