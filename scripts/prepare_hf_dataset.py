import os
os.environ["HF_HUB_ENABLE_HF_TRANSFER"] = "0"
from datasets import load_dataset
from PIL import Image

def prepare_dataset():
    print("Loading dataset 'marmal88/skin_cancer'...")
    ds = load_dataset("marmal88/skin_cancer")
    
    # Check the splits and features
    print("Dataset structure:")
    print(ds)
    
    # Typically, image classification datasets have 'image' and 'label' columns
    # We need to map integer labels to string class names if available
    train_ds = ds.get('train')
    if not train_ds:
        print("No 'train' split found!")
        return
        
    features = train_ds.features
    print("Features:", features)
    
    label_feature = features.get('label')
    class_names = None
    if hasattr(label_feature, 'names'):
        class_names = label_feature.names
        print("Class names found:", class_names)
    else:
        # Fallback to standard HAM10000 mapping if not explicitly defined
        # Sometimes it's ['akiec', 'bcc', 'bkl', 'df', 'mel', 'nv', 'vasc']
        # Let's hope it's standard or it has names
        print("Warning: no explicit class names found in feature.")
        
    output_dir = r"e:\Skin_Cancer\dataset"
    os.makedirs(output_dir, exist_ok=True)
    
    # Process train split
    os.makedirs(os.path.join(output_dir, "train"), exist_ok=True)
    
    print(f"Processing {len(train_ds)} training images...")
    for i, item in enumerate(train_ds):
        img = item['image']
        class_name = item['dx']
        
        class_dir = os.path.join(output_dir, "train", class_name)
        os.makedirs(class_dir, exist_ok=True)
        
        img_path = os.path.join(class_dir, f"img_{i}.jpg")
        # Save image (converting to RGB just in case)
        if not os.path.exists(img_path):
            img.convert('RGB').save(img_path)
            
        if i > 0 and i % 500 == 0:
            print(f"Saved {i} train images...")
            
    # Process val/test split if exists, otherwise take a subset of train
    val_ds = ds.get('validation') or ds.get('test')
    if val_ds:
        os.makedirs(os.path.join(output_dir, "val"), exist_ok=True)
        print(f"Processing {len(val_ds)} validation images...")
        for i, item in enumerate(val_ds):
            img = item['image']
            class_name = item['dx']
            
            class_dir = os.path.join(output_dir, "val", class_name)
            os.makedirs(class_dir, exist_ok=True)
            
            img_path = os.path.join(class_dir, f"img_{i}.jpg")
            if not os.path.exists(img_path):
                img.convert('RGB').save(img_path)
                
            if i > 0 and i % 500 == 0:
                print(f"Saved {i} val images...")
    else:
        print("No validation split found in dataset. YOLOv8 will use train set for val or we need to split it manually.")

if __name__ == "__main__":
    prepare_dataset()
    print("Dataset preparation complete.")
