import os
import shutil
import glob
from ultralytics import YOLO

def prepare_demo_images():
    model_path = r'e:\Skin_Cancer\result_real\yolov8n_ham10000\weights\best.pt'
    model = YOLO(model_path)
    class_names = model.names

    val_dir = r'e:\Skin_Cancer\dataset\val'
    out_dir = r'e:\Skin_Cancer\demo_images'
    os.makedirs(out_dir, exist_ok=True)

    target_classes = ['melanoma', 'basal_cell_carcinoma', 'melanocytic_Nevi', 'vascular_lesions', 'benign_keratosis-like_lesions']
    
    print("Finding high-confidence images for demo...")
    for cls in target_classes:
        cls_dir = os.path.join(val_dir, cls)
        images = glob.glob(os.path.join(cls_dir, '*.jpg'))
        
        best_img = None
        best_conf = 0.0
        
        # Check first 20 images to find a really good one
        for img_path in images[:20]:
            results = model(img_path, verbose=False)
            top1_idx = results[0].probs.top1
            top1_conf = results[0].probs.top1conf.item()
            pred_name = class_names[top1_idx]
            
            if pred_name == cls and top1_conf > best_conf:
                best_conf = top1_conf
                best_img = img_path
                
        if best_img:
            dest = os.path.join(out_dir, f"{cls}_{best_conf:.2f}.jpg")
            shutil.copy(best_img, dest)
            print(f"Prepared {cls}: {best_conf:.2f} confidence -> {dest}")

if __name__ == "__main__":
    prepare_demo_images()
