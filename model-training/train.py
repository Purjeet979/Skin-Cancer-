from ultralytics import YOLO



import os

models = ["n"]
data_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "data"))

for x in models:
    # Load a model
    model = YOLO(f"yolov8{x}-cls.pt")  # load a pretrained model (recommended for training)
    
    # Train the model
    results = model.train(data=data_path, epochs=30, imgsz=640, project='./result', name=f'yolov8{x}')
    