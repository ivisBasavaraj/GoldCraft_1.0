"""
Train YOLOv8s on digital weight scale dataset.

Usage:
  python train.py          # auto-detects GPU/CPU
  python train.py --fast   # CPU fast mode: 640px, 100 epochs (~1.5 hrs)
"""

import sys
import shutil
import os
import torch
from ultralytics import YOLO

DATA_YAML = r"D:\Pushpa Chains\Digital weight scale detection 2.v1i.yolo26\data.yaml"
PROJECT   = "runs/detect"
NAME      = "scale_ocr_v3"

FAST_MODE = "--fast" in sys.argv
HAS_GPU   = torch.cuda.is_available()

# Config based on hardware
if HAS_GPU:
    IMG_SIZE = 1280
    BATCH    = 8
    EPOCHS   = 300
    DEVICE   = 0
    WORKERS  = 4
    print("GPU detected — training at 1280px, 300 epochs")
elif FAST_MODE:
    IMG_SIZE = 640
    BATCH    = 4
    EPOCHS   = 100
    DEVICE   = "cpu"
    WORKERS  = 2
    print("CPU fast mode — training at 640px, 100 epochs (~1.5 hrs)")
else:
    IMG_SIZE = 1280
    BATCH    = 2
    EPOCHS   = 300
    DEVICE   = "cpu"
    WORKERS  = 2
    print("CPU full mode — training at 1280px, 300 epochs (very slow, use Colab instead)")


def train():
    model = YOLO("yolov8s.pt")
    model.train(
        data=DATA_YAML,
        epochs=EPOCHS,
        imgsz=IMG_SIZE,
        batch=BATCH,
        project=PROJECT,
        name=NAME,
        patience=60,
        device=DEVICE,
        workers=WORKERS,
        exist_ok=True,

        # Augmentation
        fliplr=0.0,
        flipud=0.0,
        degrees=3.0,
        translate=0.05,
        scale=0.2,
        shear=1.0,
        perspective=0.0,
        hsv_h=0.01,
        hsv_s=0.4,
        hsv_v=0.5,
        mosaic=0.0,
        mixup=0.0,
        erasing=0.0,
        copy_paste=0.0,

        # Optimiser
        optimizer="AdamW",
        lr0=0.0005,
        lrf=0.01,
        weight_decay=0.0005,
        warmup_epochs=5,
        cos_lr=True,
        label_smoothing=0.05,

        # Loss
        box=5.0,
        cls=2.0,
        dfl=1.5,
    )

    best = os.path.join(PROJECT, NAME, "weights", "best.pt")
    dest = os.path.join(os.path.dirname(os.path.abspath(__file__)), "best.pt")
    shutil.copy(best, dest)
    print(f"\nModel saved to {dest}")


if __name__ == "__main__":
    train()
