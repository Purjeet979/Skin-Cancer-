from ultralytics import YOLO
import os
import shutil

def train_model():
    # Load a pretrained YOLOv8n-cls model (ImageNet pretrained weights)
    model = YOLO("yolov8n-cls.pt")
    
    # Clean previous result_real directory if it exists
    if os.path.exists('./result_real'):
        shutil.rmtree('./result_real')
        
    data_path = os.path.abspath(r'e:\Skin_Cancer\dataset')
    
    print(f"Starting training on REAL dataset at {data_path}...")
    print("This will take up to 45 minutes limit.")
    
    # Train the model for 20 epochs (as requested 15-20)
    # The default imgsz for YOLO-cls is usually 224, but earlier it was trained on 640.
    # To save time and because HAM10000 images are 600x450, we'll use imgsz=224 for speed,
    # or 416 to keep some detail while being fast. Let's use 224 since it's standard for cls and very fast.
    results = model.train(
        data=data_path, 
        epochs=15, 
        imgsz=640, 
        project='./result_real', 
        name='yolov8n_ham10000',
        pretrained=True
    )
    
    print("Training complete! Model saved to result_real/yolov8n_ham10000/weights/best.pt")
    
if __name__ == "__main__":
    train_model()
