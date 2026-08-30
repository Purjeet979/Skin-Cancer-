import numpy as np
import tensorflow as tf
from PIL import Image
import os
import glob

def softmax(x):
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum(axis=1, keepdims=True)

def run_test(model_path, images, use_mean_std=False):
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    labels = ['akiec', 'bcc', 'bkl', 'df', 'mel', 'nv', 'vasc']
    print(f"\n=====================================")
    print(f"Testing Model: {os.path.basename(model_path)}")
    print(f"Preprocessing: {'Mean/Std Normalization' if use_mean_std else 'Only / 255.0'}")
    print(f"=====================================")
    
    for true_cls, img_path in images:
        img = Image.open(img_path).convert('RGB')
        img = img.resize((640, 640))
        img = np.array(img, dtype=np.float32) / 255.0
        
        if use_mean_std:
            mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
            std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
            img = (img - mean) / std
            
        img = np.expand_dims(img, axis=0)
        
        # If model expects INT8 input (like Edge TPU quantized models)
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
        pred = labels[np.argmax(probs)]
        print(f"Image: {true_cls:<5} | Pred: {pred:<5} | Probs: {np.round(probs, 3)}")

# Images to test
test_images = [
    ('akiec', r'e:\Skin_Cancer\model-training\sample_akiec.jpg'),
    ('bcc',   r'e:\Skin_Cancer\model-training\sample_bcc.jpg'),
    ('mel',   r'e:\Skin_Cancer\model-training\sample_mel.jpg'),
    ('nv',    r'e:\Skin_Cancer\model-training\sample_nv.jpg'),
]

int8_model = r'e:\Skin_Cancer\mobile_app\assets\model\best_int8.tflite'
float32_model = r'e:\Skin_Cancer\model-training\result_with_aug\yolov8n\weights\best_saved_model\best_float32.tflite'

# Test INT8 model
run_test(int8_model, test_images, use_mean_std=True)
run_test(int8_model, test_images, use_mean_std=False)

# Test FLOAT32 model
run_test(float32_model, test_images, use_mean_std=True)
run_test(float32_model, test_images, use_mean_std=False)
