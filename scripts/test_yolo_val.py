import os
import random
import glob
from ultralytics import YOLO

def test_yolo_validation():
    model_path = r'e:\Skin_Cancer\result_real\yolov8n_ham10000\weights\best.pt'
    if not os.path.exists(model_path):
        print(f"Model not found at {model_path}")
        return

    print("Loading YOLOv8n-cls trained on authentic HAM10000 data...")
    model = YOLO(model_path)
    class_names = model.names

    val_dir = r'e:\Skin_Cancer\dataset\val'
    if not os.path.exists(val_dir):
        print(f"Validation directory {val_dir} not found.")
        return

    print("\n=== YOLOv8n-cls (Authentic HAM10000) Validation Set Inference ===")
    
    # Pick one image from each class in the validation set
    classes = os.listdir(val_dir)
    for cls in classes:
        cls_dir = os.path.join(val_dir, cls)
        if not os.path.isdir(cls_dir):
            continue
            
        images = glob.glob(os.path.join(cls_dir, '*.jpg'))
        if not images:
            continue
            
        test_img = random.choice(images)
        
        try:
            results = model(test_img, verbose=False)
            
            for r in results:
                top1_idx = r.probs.top1
                top1_conf = r.probs.top1conf.item()
                top1_name = class_names[top1_idx]
                
                print(f"True Class: {cls:<25} | Pred: {top1_name:<25} | Conf: {top1_conf:.3f}")
                
        except Exception as e:
            print(f"Error processing {test_img}: {e}")

if __name__ == "__main__":
    test_yolo_validation()
