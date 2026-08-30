import os
import numpy as np
from PIL import Image
import glob
from huggingface_hub import hf_hub_download
import tensorflow as tf

def test_keras_model():
    print("Downloading syaha/skin_cancer_detection_model...")
    try:
        model_path = hf_hub_download(
            repo_id="syaha/skin_cancer_detection_model", 
            filename="skin_cancer_model.h5", 
            local_dir=r"e:\Skin_Cancer\models"
        )
        print(f"Model downloaded to {model_path}")
    except Exception as e:
        print(f"Error downloading model: {e}")
        return

    print("Loading model...")
    try:
        model = tf.keras.models.load_model(model_path)
    except Exception as e:
        print(f"Error loading model: {e}")
        return

    # Check model input shape
    input_shape = model.input_shape
    print(f"Model expected input shape: {input_shape}")
    
    # Typically image size for this model might be 224x224 or 299x299. Let's assume input_shape[1:3]
    target_size = (input_shape[1], input_shape[2]) if input_shape[1] is not None else (224, 224)
    print(f"Using target size: {target_size}")

    test_images = glob.glob(r'e:\Skin_Cancer\backend\uploads\*.jpg')
    print("=== Keras Model Inference (Raw) ===")
    
    labels = ['akiec', 'bcc', 'bkl', 'df', 'mel', 'nv', 'vasc']
    
    for img_path in test_images:
        try:
            img = Image.open(img_path).convert('RGB')
            img = img.resize(target_size)
            
            # Normalization might be /255.0, let's just do /255.0 as default for Keras
            img_array = np.array(img) / 255.0
            img_array = np.expand_dims(img_array, axis=0)
            
            preds = model.predict(img_array, verbose=0)[0]
            
            top1_idx = np.argmax(preds)
            top1_name = labels[top1_idx] if top1_idx < len(labels) else str(top1_idx)
            top1_conf = preds[top1_idx]
            
            probs_str = " ".join([f"{p:.3f}" for p in preds])
            print(f"Image: {os.path.basename(img_path):<30} | Pred: {top1_name:<5} | Conf: {top1_conf:.3f} | Probs: [{probs_str}]")
        except Exception as e:
            print(f"Error processing {img_path}: {e}")

if __name__ == "__main__":
    test_keras_model()
