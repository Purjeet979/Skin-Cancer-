import os
import glob
from ultralytics import YOLO
import torch

def test_yolo_model():
    model_path = r'e:\Skin_Cancer\result_real\yolov8n_ham10000\weights\best.pt'
    if not os.path.exists(model_path):
        print(f"Model not found at {model_path}")
        return

    print("Loading YOLOv8n-cls trained on authentic HAM10000 data...")
    model = YOLO(model_path)
    
    # YOLO automatically maps class indices to names from its training data metadata
    class_names = model.names
    print(f"Model classes: {class_names}")

    test_images = glob.glob(r'e:\Skin_Cancer\backend\uploads\*.jpg')
    print("\n=== YOLOv8n-cls (Authentic HAM10000) Inference (Raw) ===")
    
    for img_path in test_images:
        try:
            # verbose=False to keep output clean
            results = model(img_path, verbose=False)
            
            for r in results:
                probs_tensor = r.probs.data
                top1_idx = r.probs.top1
                top1_conf = r.probs.top1conf.item()
                top1_name = class_names[top1_idx]
                
                probs_list = probs_tensor.cpu().numpy().tolist()
                probs_str = " ".join([f"{p:.3f}" for p in probs_list])
                
                print(f"Image: {os.path.basename(img_path):<30} | Pred: {top1_name:<5} | Conf: {top1_conf:.3f} | Probs: [{probs_str}]")
                
        except Exception as e:
            print(f"Error processing {img_path}: {e}")

if __name__ == "__main__":
    test_yolo_model()
