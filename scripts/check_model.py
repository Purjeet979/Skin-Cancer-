import torch
model_path = r'e:\Skin_Cancer\models\DermaMNIST_resnet18.pth'
data = torch.load(model_path, map_location='cpu')
print("FC weight shape:", data['fc.weight'].shape)
print("FC bias shape:", data['fc.bias'].shape)
