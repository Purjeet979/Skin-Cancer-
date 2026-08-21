import os
import time
import numpy as np
from ultralytics import YOLO

def export_yolov8_to_tflite(model_path=None, int8=True):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    if model_path is None or not os.path.exists(str(model_path)):
        cand1 = os.path.join(base_dir, "result", "yolov8n", "weights", "best.pt")
        cand2 = os.path.join(base_dir, "result_with_aug", "yolov8n", "weights", "best.pt")
        if os.path.exists(cand1):
            model_path = cand1
        elif os.path.exists(cand2):
            model_path = cand2
        else:
            model_path = "yolov8n-cls.pt"

    expected_tflite = os.path.join(base_dir, "result_with_aug", "yolov8n", "weights", "best_saved_model", "best_int8.tflite")
    if os.path.exists(expected_tflite):
        file_size_mb = os.path.getsize(expected_tflite) / (1024 * 1024)
        print(f"[M3 Export Success] TFLite model already exists at: {expected_tflite}")
        print(f"[M3 Export Info] Model File Size: {file_size_mb:.2f} MB")
        return expected_tflite

    print(f"[M3 Export] Loading PyTorch model from: {model_path}")
    model = YOLO(model_path)
    
    # Export model to TFLite
    print("[M3 Export] Exporting model to TFLite format (int8 quantization)...")
    try:
        tflite_path = model.export(format="tflite", int8=int8)
    except Exception as e:
        print(f"[M3 Export Warning] INT8 export notice: {e}, falling back to standard TFLite export...")
        tflite_path = model.export(format="tflite")

    if not os.path.isabs(tflite_path):
        tflite_path = os.path.abspath(tflite_path)

    file_size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
    print(f"[M3 Export Success] TFLite model generated at: {tflite_path}")
    print(f"[M3 Export Info] Model File Size: {file_size_mb:.2f} MB")
    
    return tflite_path

def verify_tflite_parity(pytorch_model_path, tflite_model_path, num_samples=10):
    print(f"\n=== Verifying PyTorch vs TFLite Prediction Parity ({num_samples} samples) ===")
    py_model = YOLO(pytorch_model_path)
    
    # Create sample synthetic lesion inputs to test parity
    matches = 0
    total_time_ms = 0
    
    for i in range(num_samples):
        # Generate varied input images
        img = np.random.randint(150, 240, (640, 640, 3), dtype=np.uint8)
        cv2_circle = np.random.randint(20, 100)
        img[250:250+cv2_circle, 250:250+cv2_circle] = np.random.randint(10, 80, (cv2_circle, cv2_circle, 3))
        
        # Save temp image
        tmp_img_path = f"tmp_sanity_{i}.jpg"
        import cv2
        cv2.imwrite(tmp_img_path, img)

        # PyTorch inference
        t0 = time.time()
        py_res = py_model(tmp_img_path, verbose=False)[0]
        py_class = py_res.probs.top1
        
        # TFLite inference using Ultralytics TFLite runner
        tf_model = YOLO(tflite_model_path, task='classify')
        tf_res = tf_model(tmp_img_path, verbose=False)[0]
        tf_class = tf_res.probs.top1
        t1 = time.time()

        latency_ms = (t1 - t0) * 1000
        total_time_ms += latency_ms

        match = (py_class == tf_class)
        if match:
            matches += 1
        print(f"Sample {i+1:02d}: PyTorch Top1={py_class} | TFLite Top1={tf_class} | Match: {match} | Latency: {latency_ms:.1f}ms")
        
        if os.path.exists(tmp_img_path):
            os.remove(tmp_img_path)

    parity_pct = (matches / num_samples) * 100
    avg_latency = total_time_ms / num_samples
    print(f"\n[Parity Result] Prediction Match: {matches}/{num_samples} ({parity_pct:.1f}%)")
    print(f"[Performance] Average Inference Latency: {avg_latency:.1f} ms")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    cand1 = os.path.join(base_dir, "result", "yolov8n", "weights", "best.pt")
    cand2 = os.path.join(base_dir, "result_with_aug", "yolov8n", "weights", "best.pt")
    model_path = cand1 if os.path.exists(cand1) else (cand2 if os.path.exists(cand2) else "yolov8n-cls.pt")

    tflite_path = export_yolov8_to_tflite(model_path)
    verify_tflite_parity(model_path, tflite_path, num_samples=10)
