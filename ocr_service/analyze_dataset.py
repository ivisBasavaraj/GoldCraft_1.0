"""Analyze dataset: class distribution, negative samples, box sizes."""
from pathlib import Path
from collections import Counter

CLASS_MAP = {0:'-',1:'0',2:'1',3:'2',4:'3',5:'4',6:'5',7:'6',8:'7',9:'8',10:'9',11:'.'}
DATASET = Path(r'D:\Pushpa Chains\Digital weight scale detection 2.v1i.yolo26')

total_cls = Counter()
neg_files = []
box_widths = []
box_heights = []

for split in ['train', 'valid', 'test']:
    lbl_dir = DATASET / split / 'labels'
    img_dir = DATASET / split / 'images'
    imgs = list(img_dir.glob('*.jpg'))
    print(f"\n{split}: {len(imgs)} images")

    for lbl in lbl_dir.glob('*.txt'):
        lines = lbl.read_text().strip().splitlines()
        has_neg = False
        for line in lines:
            p = line.split()
            cls = int(p[0])
            w, h = float(p[3]), float(p[4])
            total_cls[cls] += 1
            box_widths.append(w)
            box_heights.append(h)
            if cls == 0:
                has_neg = True
        if has_neg:
            neg_files.append(f"{split}/{lbl.name}")

print(f"\nClass distribution (all splits):")
for cls_id in sorted(total_cls):
    print(f"  class {cls_id} ({CLASS_MAP[cls_id]}): {total_cls[cls_id]} instances")

print(f"\nNegative sign (-ve) samples: {len(neg_files)}")
for f in neg_files:
    print(f"  {f}")

import statistics
print(f"\nBox width  (normalized): min={min(box_widths):.4f} max={max(box_widths):.4f} median={statistics.median(box_widths):.4f}")
print(f"Box height (normalized): min={min(box_heights):.4f} max={max(box_heights):.4f} median={statistics.median(box_heights):.4f}")
print(f"\nAt 320x320px:")
print(f"  digit width  median = {statistics.median(box_widths)*320:.1f}px")
print(f"  digit height median = {statistics.median(box_heights)*320:.1f}px")
print(f"At 1280x1280px:")
print(f"  digit width  median = {statistics.median(box_widths)*1280:.1f}px")
print(f"  digit height median = {statistics.median(box_heights)*1280:.1f}px")
