"""
Augment the 2 negative-sign samples into 20 variants each.
Copies augmented images+labels into the train split.
Run once before training.
"""
import cv2
import numpy as np
import shutil
from pathlib import Path

DATASET  = Path(r'D:\Pushpa Chains\Digital weight scale detection 2.v1i.yolo26')
TRAIN_IMG = DATASET / 'train' / 'images'
TRAIN_LBL = DATASET / 'train' / 'labels'

NEG_IMGS = [
    'WIN_20260601_11_20_30_Pro_jpg.rf.bd1f15128fc934aad501fc2de95fc78b',
    'WIN_20260601_11_20_32_Pro_jpg.rf.4c40b0424af1bd1dbf64604a3eb1c1d0',
]

def augment_image(img):
    """Return list of augmented variants."""
    variants = []
    h, w = img.shape[:2]

    # Brightness variations
    for alpha, beta in [(0.7, -20), (0.85, -10), (1.15, 10), (1.3, 20), (1.5, 40)]:
        variants.append(cv2.convertScaleAbs(img, alpha=alpha, beta=beta))

    # CLAHE
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    for clip in [2.0, 4.0]:
        lc = cv2.createCLAHE(clipLimit=clip, tileGridSize=(8,8)).apply(l)
        variants.append(cv2.cvtColor(cv2.merge([lc, a, b]), cv2.COLOR_LAB2BGR))

    # Slight rotations
    for angle in [-3, -1.5, 1.5, 3]:
        M = cv2.getRotationMatrix2D((w/2, h/2), angle, 1.0)
        variants.append(cv2.warpAffine(img, M, (w, h)))

    # Gaussian noise
    for sigma in [3, 6]:
        noise = np.random.normal(0, sigma, img.shape).astype(np.int16)
        noisy = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
        variants.append(noisy)

    # Slight blur
    variants.append(cv2.GaussianBlur(img, (3, 3), 0))

    # Sharpen
    k = np.array([[0,-1,0],[-1,5,-1],[0,-1,0]])
    variants.append(cv2.filter2D(img, -1, k))

    return variants


def run():
    created = 0
    for stem in NEG_IMGS:
        src_img = TRAIN_IMG / f'{stem}.jpg'
        src_lbl = TRAIN_LBL / f'{stem}.txt'

        if not src_img.exists():
            print(f'Missing: {src_img}')
            continue

        img = cv2.imread(str(src_img))
        lbl_text = src_lbl.read_text()
        variants = augment_image(img)

        for i, aug in enumerate(variants):
            new_stem = f'{stem}_aug{i:02d}'
            dst_img = TRAIN_IMG / f'{new_stem}.jpg'
            dst_lbl = TRAIN_LBL / f'{new_stem}.txt'

            if not dst_img.exists():
                cv2.imwrite(str(dst_img), aug)
                dst_lbl.write_text(lbl_text)
                created += 1

    print(f'Created {created} augmented negative-sign samples.')
    print(f'Total train images now: {len(list(TRAIN_IMG.glob("*.jpg")))}')


if __name__ == '__main__':
    run()
