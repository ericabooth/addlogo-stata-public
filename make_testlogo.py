#!/usr/bin/env python3
"""Make a throwaway transparent-PNG logo so addlogo has something to stamp.
Replace the output with your real brand logo for production use."""
import sys
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else "testlogo.png"

W, H = 720, 220
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))          # transparent canvas
d = ImageDraw.Draw(img)

navy = (11, 45, 92, 255)
gold = (196, 154, 63, 255)

# rounded-rectangle badge
d.rounded_rectangle([4, 4, W - 4, H - 4], radius=44, fill=navy)
d.rounded_rectangle([4, 4, W - 4, H - 4], radius=44, outline=gold, width=8)


def font(size):
    for p in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf",
              "/System/Library/Fonts/Helvetica.ttc",
              "/Library/Fonts/Arial.ttf"):
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            continue
    return ImageFont.load_default()


def centered(text, fnt, cx, cy, fill):
    l, t, r, b = d.textbbox((0, 0), text, font=fnt)
    d.text((cx - (r - l) / 2 - l, cy - (b - t) / 2 - t), text, font=fnt, fill=fill)


# small gold roundel as a mark, then wordmark
d.ellipse([64, H / 2 - 42, 148, H / 2 + 42], fill=gold)
centered("DEMO", font(100), W / 2 + 34, H / 2 - 18, (255, 255, 255, 255))
centered("placeholder logo", font(34), W / 2 + 34, H / 2 + 64, gold)

img.save(OUT)
print("wrote", OUT, img.size)
