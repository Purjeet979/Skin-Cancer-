import os
import random
import numpy as np
from PIL import Image
import tensorflow as tf

def find_demo_images():
    print("Loading Keras model...")
    model_path = r"e:\Skin_Cancer\models\skin_cancer_model.h5"
    if not os.path.exists(model_path):
        print("Model not found.")
        return
        
    model = tf.keras.models.load_model(model_path)
    target_size = (224, 224)
    labels = ['akiec', 'bcc', 'bkl', 'df', 'mel', 'nv', 'vasc']
    
    dataset_dir = r"e:\Skin_Cancer\dataset\train"
    if not os.path.exists(dataset_dir):
        print(f"Dataset dir {dataset_dir} not found.")
        return
        
    print("Searching for images that DO NOT predict 'nv'...")
    
    # We specifically want to find a good 'mel' (Melanoma) and a good 'bcc' or 'bkl'
    target_classes = ['mel', 'bcc', 'bkl', 'akiec', 'df', 'vasc']
    
    found_images = []
    
    for cls in target_classes:
        cls_dir = os.path.join(dataset_dir, cls)
        if not os.path.exists(cls_dir):
            continue
            
        images = [f for f in os.listdir(cls_dir) if f.endswith('.jpg')]
        random.shuffle(images)
        
        print(f"Testing {cls} images...")
        count = 0
        success = 0
        
        for img_name in images:
            if count > 50: # test max 50 per class to save time
                break
            count += 1
            
            img_path = os.path.join(cls_dir, img_name)
            try:
                img = Image.open(img_path).convert('RGB')
                img_resized = img.resize(target_size)
                
                img_array = np.array(img_resized)
                img_array = np.expand_dims(img_array, axis=0)
                img_array = tf.keras.applications.mobilenet_v2.preprocess_input(img_array)
                
                preds = model.predict(img_array, verbose=0)[0]
                top1_idx = np.argmax(preds)
                top1_name = labels[top1_idx]
                
                # If the model correctly predicts the class (and it's not nv!)
                if top1_name == cls:
                    print(f"SUCCESS! Found a {cls} image that actually predicts {cls}! ({img_name}, Conf: {preds[top1_idx]:.2f})")
                    found_images.append(img_path)
                    success += 1
                    
                    # Copy it to backend/uploads for the user to use
                    import shutil
                    os.makedirs(r"e:\Skin_Cancer\backend\uploads\demo_ready", exist_ok=True)
                    shutil.copy(img_path, os.path.join(r"e:\Skin_Cancer\backend\uploads\demo_ready", f"demo_ready_{cls}_{img_name}"))
                    
                    if success >= 2: # Find 2 good ones per class
                        break
                        
            except Exception as e:
                pass

    print(f"\nDone! Found {len(found_images)} non-NV images for the demo.")

if __name__ == "__main__":
    find_demo_images()
