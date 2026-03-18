import os
from PIL import Image
import torch
import onnxruntime as ort
from torchvision import transforms


class Onelink_Captcha_Code:

    def __init__(self):

        self.img_height = 50
        self.img_width = 200
        current_dir = os.path.dirname(os.path.abspath(__file__))
        model_path = os.path.join(current_dir, "genesysV81.onnx")
        self.model_weights = [1.0]
        self.ort_session = ort.InferenceSession(model_path)

    def check_pred_onnx(self, path, if_centercrop=False, if_flip=False):

        if if_centercrop:
            transform = transforms.Compose([
                transforms.Grayscale(num_output_channels=1),
                transforms.CenterCrop((self.img_height, self.img_width - 20)),
                transforms.ToTensor(),
                transforms.Normalize((0.5,), (0.5,)),
                transforms.Resize((self.img_height, self.img_width)),
            ])
        else:
            transform = transforms.Compose([
                transforms.Grayscale(num_output_channels=1),
                transforms.ToTensor(),
                transforms.Normalize((0.5,), (0.5,)),
                transforms.Resize((self.img_height, self.img_width)),
            ])

        img = Image.open(path).convert("RGB")
        img = transform(img)

        if if_flip:
            img = torch.flip(img, dims=[2])

        img = img.unsqueeze(0)

        input_name = self.ort_session.get_inputs()[0].name
        output_names = [output.name for output in self.ort_session.get_outputs()]

        ort_inputs = {input_name: img.numpy()}

        logits = self.ort_session.run(output_names, ort_inputs)

        logits = [torch.from_numpy(logit) for logit in logits]

        if if_flip:
            return logits[::-1]
        else:
            return logits

    def check_pred_onnx_tta(self, path, do_tta=True):

        if do_tta:
            check_pred_calls = [
                (path, True, False),
                (path, False, False),
            ]
        else:
            check_pred_calls = [
                (path, False, False)
            ]

        logits_list = [self.check_pred_onnx(*args) for args in check_pred_calls]

        if len(logits_list) > 1:

            aggregated_logits = []

            for logit_set in zip(*logits_list):
                logits_stack = torch.stack(logit_set, dim=0)
                combined_logits = torch.sum(logits_stack, dim=0) / len(logit_set)
                aggregated_logits.append(combined_logits)

        else:
            aggregated_logits = logits_list[0]

        with torch.no_grad():

            processed_logits = [
                logits.argmax(dim=1).numpy().reshape(-1)
                for logits in aggregated_logits
            ]

            prediction = "".join(str(logits[0]) for logits in processed_logits)
        return prediction

    def onelink_captcha(self, image_path):
        captcha_code = self.check_pred_onnx_tta(image_path, do_tta=True)
        print(f"Captcha Code: {captcha_code}")
        return captcha_code