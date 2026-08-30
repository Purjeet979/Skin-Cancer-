from ultralytics import YOLO
import glob

# Load original PyTorch model
model = YOLO(r'e:\Skin_Cancer\model-training\result_with_aug\yolov8n\weights\best.pt')

# Run inference on the samples
test_images = glob.glob(r'e:\Skin_Cancer\model-training\sample_*.jpg')
for img_path in test_images:
    results = model(img_path, verbose=False)
    probs = results[0].probs
    top1 = probs.top1
    top1_conf = probs.top1conf.item()
    top1_name = model.names[top1]
    
    import os
    print(f"Image: {os.path.basename(img_path):<15} | Pred: {top1_name:<5} | Conf: {top1_conf:.4f}")
