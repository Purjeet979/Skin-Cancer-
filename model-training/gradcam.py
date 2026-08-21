import os
import cv2
import numpy as np
import torch
import torch.nn.functional as F
from ultralytics import YOLO

class YOLOv8GradCAM:
    def __init__(self, model_path=None):
        if model_path is None or not os.path.exists(str(model_path)):
            base_dir = os.path.dirname(os.path.abspath(__file__))
            cand1 = os.path.join(base_dir, "result", "yolov8n", "weights", "best.pt")
            cand2 = os.path.join(base_dir, "result_with_aug", "yolov8n", "weights", "best.pt")
            if os.path.exists(cand1):
                model_path = cand1
            elif os.path.exists(cand2):
                model_path = cand2
            else:
                model_path = "yolov8n-cls.pt"
        
        self.yolo = YOLO(model_path)
        self.model = self.yolo.model.eval()
        
        # HAM10000 7-class mapping fallback
        self.ham_names = {0: 'akiec', 1: 'bcc', 2: 'bkl', 3: 'df', 4: 'mel', 5: 'nv', 6: 'vasc'}
        if len(self.yolo.names) == 1000:
            self.names = self.ham_names
        else:
            self.names = self.yolo.names

        # Find target feature layer for Grad-CAM (last Conv2d before classification head)
        self.target_layer = None
        for m in reversed(list(self.model.modules())):
            if isinstance(m, torch.nn.Conv2d):
                self.target_layer = m
                break

    def generate_heatmap(self, image_path, target_class=None):
        img_raw = cv2.imread(image_path)
        if img_raw is None:
            raise ValueError(f"Could not load image from {image_path}")
        h, w, _ = img_raw.shape

        for p in self.model.parameters():
            p.requires_grad = True

        # Preprocess for YOLO classification (resize 640x640, normalize with ImageNet stats)
        img_resized = cv2.resize(img_raw, (640, 640))
        img_rgb = cv2.cvtColor(img_resized, cv2.COLOR_BGR2RGB)
        tensor = torch.from_numpy(img_rgb).permute(2, 0, 1).unsqueeze(0).float() / 255.0
        
        # ImageNet normalization used by YOLO classification models
        mean = torch.tensor([0.485, 0.456, 0.406]).view(1, 3, 1, 1)
        std = torch.tensor([0.229, 0.224, 0.225]).view(1, 3, 1, 1)
        tensor = (tensor - mean) / std
        tensor = tensor.requires_grad_(True)

        activations = []
        gradients = []

        def forward_hook(module, input, output):
            activations.append(output)

        def backward_hook(module, grad_in, grad_out):
            gradients.append(grad_out[0])

        h1 = self.target_layer.register_forward_hook(forward_hook)
        h2 = self.target_layer.register_full_backward_hook(backward_hook)

        # Forward pass
        self.model.zero_grad()
        output = self.model(tensor)
        if isinstance(output, (tuple, list)):
            output = output[0]

        # If output is already probabilities (sums to ~1 and all >= 0), use directly without double softmax
        if output.min() >= 0 and torch.isclose(output.sum(dim=1), torch.tensor([1.0]), atol=1e-2):
            probs = output
        else:
            probs = F.softmax(output, dim=1)
        conf, pred_class = torch.max(probs, dim=1)
        pred_class_id = int(pred_class.item())
        confidence_val = float(round(conf.item(), 4))

        if target_class is None:
            target_class = pred_class_id

        # Backward pass on target class score
        score = output[0, target_class]
        score.backward()

        h1.remove()
        h2.remove()

        act = activations[0].squeeze(0).detach().cpu().numpy()
        grad = gradients[0].squeeze(0).detach().cpu().numpy()

        weights = np.mean(grad, axis=(1, 2))
        cam = np.zeros(act.shape[1:], dtype=np.float32)
        for i, w_val in enumerate(weights):
            cam += w_val * act[i]

        cam = np.maximum(cam, 0)
        if cam.max() > 0:
            cam = cam / cam.max()

        cam_resized = cv2.resize(cam, (w, h))
        heatmap = cv2.applyColorMap(np.uint8(255 * cam_resized), cv2.COLORMAP_JET)

        # Overlay heatmap on raw image
        overlay = cv2.addWeighted(img_raw, 0.6, heatmap, 0.4, 0)
        
        class_name = self.names.get(pred_class_id, f"Class {pred_class_id}")

        return {
            "class_id": pred_class_id,
            "class": class_name,
            "confidence": confidence_val,
            "overlay": overlay,
            "heatmap": heatmap
        }


def get_gradcam_explanation(image_path, model_path=None, output_path=None):
    explainer = YOLOv8GradCAM(model_path=model_path)
    res = explainer.generate_heatmap(image_path)

    if output_path is None:
        base, ext = os.path.splitext(image_path)
        output_path = f"{base}_gradcam.png"

    cv2.imwrite(output_path, res["overlay"])

    return {
        "class_id": res["class_id"],
        "class": res["class"],
        "confidence": res["confidence"],
        "heatmap_png_path": os.path.abspath(output_path)
    }

if __name__ == "__main__":
    import sys
    test_img = sys.argv[1] if len(sys.argv) > 1 else "sample_lesion.jpg"
    if not os.path.exists(test_img):
        # Create a sample synthetic lesion image for verification if none provided
        img = np.ones((400, 400, 3), dtype=np.uint8) * 210
        cv2.circle(img, (200, 200), 70, (40, 30, 100), -1)
        cv2.imwrite(test_img, img)

    result = get_gradcam_explanation(test_img)
    print("Grad-CAM Result:", result)
