import onnx
import torch
from PIL import Image
import onnxruntime as rt
import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from tokenizer_base import Tokenizer
from torchvision import transforms as T


class captcha_handling():
    def get_transform(self, img_size):
        transforms = []
        transforms.extend([
            T.Resize(img_size, T.InterpolationMode.BICUBIC),
            T.ToTensor(),
            # T.Normalize(0.5, 0.5)
            T.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
        ])
        return T.Compose(transforms)

    def to_numpy(self, tensor):
        return tensor.detach().cpu().numpy() if tensor.requires_grad else tensor.cpu().numpy()

    def initialize_model(self, model_file, img_size):
        transform = self.get_transform(img_size)
        print("I n 1")
        onnx_model = onnx.load(model_file)
        # print(onnx_model, "I n 3")
        # try:
        #     onnx.checker.check_model(onnx_model)
        # except onnx.checker.ValidationError as e:
        #     print("ONNX model validation failed:", e)
        # print("I n 2")
        ort_session = rt.InferenceSession(model_file)
        return transform, ort_session

    def get_img_text(self, img_org, transform, ort_session, tokenizer_base):
        x = transform(img_org.convert('RGB')).unsqueeze(0)
        ort_inputs = {ort_session.get_inputs()[0].name: self.to_numpy(x)}
        logits = ort_session.run(None, ort_inputs)[0]
        probs = torch.tensor(logits).softmax(-1)
        preds, probs = tokenizer_base.decode(probs)
        preds = preds[0]
        return preds

    def get_captcha_text(self, file_path):
        img_size = (32, 128)
        charset = r"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
        tokenizer_base = Tokenizer(charset)
        # print("I am here1")
        transform, ort_session = self.initialize_model('C:\\Users\\MuhammadHassaanPAM\\Documents\\workspace\\Jazz Service Desk\\captcha.onnx', img_size)
        print(transform)
        img_org = Image.open(file_path).convert("L"
        )
        # print("I am here")
        res = self.get_img_text(img_org, transform, ort_session, tokenizer_base)
        return res


a = captcha_handling()
file_path = "C:\\Users\\MuhammadHassaanPAM\\Documents\\workspace\\One Link Code\\OneLinkCaptcha.png"
text = a.get_captcha_text(file_path)
print(text)
