"""Peach v2: clean single-circle body with heart-top notch drawn as two arcs."""
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = r"E:\demo\wonder-isles\wonder-isles-app\assets\numbers\goods"
INK = (43, 36, 29); REED = (143, 165, 91)
SIZE = 512

def with_shadow(img, offset=(0, 10), blur=14, alpha=90):
    shadow = Image.new("RGBA", img.size, (0,0,0,0))
    d = ImageDraw.Draw(shadow)
    w, h = img.size
    d.ellipse([w*0.22, h*0.82, w*0.78, h*0.94], fill=(0,0,0,alpha))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    out = Image.new("RGBA", img.size, (0,0,0,0))
    out.alpha_composite(shadow, offset)
    out.alpha_composite(img)
    return out

img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
d = ImageDraw.Draw(img)
peach_fill = (232, 138, 138, 255)
# body
d.ellipse([70, 160, 442, 486], fill=peach_fill, outline=INK, width=8)
# heart-top notch: two small arcs going down to form the M of a heart
d.arc([170, 130, 300, 260], start=180, end=360, fill=INK, width=8)
d.arc([220, 130, 350, 260], start=180, end=360, fill=INK, width=8)
# fill the notch highlights
for cx, cy in [(235, 195), (285, 195)]:
    d.ellipse([cx-30, cy-30, cx+30, cy+30], fill=peach_fill)
# leaf
d.polygon([(295, 145), (380, 105), (400, 195), (310, 210)], fill=REED, outline=INK)
d.line([(255, 160), (255, 230)], fill=INK, width=6)
# highlight
hl = Image.new("RGBA", img.size, (0,0,0,0))
hd = ImageDraw.Draw(hl)
hd.ellipse([140, 260, 240, 360], fill=(255,255,255,120))
hl = hl.filter(ImageFilter.GaussianBlur(12))
img.alpha_composite(hl)
out = with_shadow(img)
out.save(os.path.join(ROOT, "peach.png"), "PNG")
print("peach v2 saved", os.path.getsize(os.path.join(ROOT, "peach.png")))