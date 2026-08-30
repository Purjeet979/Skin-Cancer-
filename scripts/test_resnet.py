import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import glob
import os

# 1. Load the ResNet18 model
model = models.resnet18(weights=None)
model.fc = torch.nn.Linear(model.fc.in_features, 7)
model.load_state_dict(torch.load(r'e:\Skin_Cancer\models\DermaMNIST_resnet18.pth', map_location='cpu'))
model.eval()

# DermaMNIST usually uses these classes in this order:
# 0: 'akiec', 1: 'bcc', 2: 'bkl', 3: 'df', 4: 'mel', 5: 'nv', 6: 'vasc'
# Note: Sometimes it's different. We'll see.
labels = ['akiec', 'bcc', 'bkl', 'df', 'mel', 'nv', 'vasc']

# DermaMNIST uses 28x28 images, but ResNet18 natively takes 224x224.
# Let's try standard ImageNet transforms.
transform = transforms.Compose([
    transforms.Resize((28, 28)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

test_images = glob.glob(r'e:\Skin_Cancer\backend\uploads\*.jpg')
print("=== PyTorch ResNet18 Inference (Raw) ===")
with torch.no_grad():
    for img_path in test_images:
        img = Image.open(img_path).convert('RGB')
        tensor = transform(img).unsqueeze(0)
        
        logits = model(tensor)
        probs = torch.nn.functional.softmax(logits, dim=1)[0]
        
        top1_idx = torch.argmax(probs).item()
        top1_name = labels[top1_idx]
        top1_conf = probs[top1_idx].item()
        
        # Format probs for easy reading
        probs_str = " ".join([f"{p:.3f}" for p in probs.numpy()])
        print(f"Image: {os.path.basename(img_path):<15} | Pred: {top1_name:<5} | Conf: {top1_conf:.3f} | Probs: [{probs_str}]")
