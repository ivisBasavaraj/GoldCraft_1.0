"""
Train YOLOv8n on the digital weight scale dataset.
Run once: python train.py
Output: runs/detect/scale_ocr/weights/best.pt  → copy to ocr_service/best.pt
"""

from ultralytics import YOLO
import shutil, os

DATA_YAML = r"D:\Pushpa Chains\Digital weight scale detection 2.v1i.yolo26\data.yaml"
EPOCHS    = 30
IMG_SIZE  = 416
BATCH     = 8
PROJECT   = "runs/detect"
NAME      = "scale_ocr"

def train():
    model = YOLO("yolov8n.pt")          # nano — fast, accurate enough for digits
    model.train(
        data=DATA_YAML,
        epochs=EPOCHS,
        imgsz=IMG_SIZE,
        batch=BATCH,
        project=PROJECT,
        name=NAME,
        patience=20,
        device="cpu",                   # change to 0 if GPU available
        workers=2,
        exist_ok=True,
    )

    best = os.path.join(PROJECT, NAME, "weights", "best.pt")
    dest = os.path.join(os.path.dirname(__file__), "best.pt")
    shutil.copy(best, dest)
    print(f"\n✅  Model saved to {dest}")

if __name__ == "__main__":
    train()
