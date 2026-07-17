"""Generate ink-wash-style PNGs for 数之岛 goods and coins.

Style: warm paper base transparent PNG, saturated flat fill with dark
ink outline and a soft highlight to feel hand-brushed. All 512x512 at 32bpp.
"""
import os, math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = r"E:\demo\wonder-isles\wonder-isles-app\assets\numbers"
GOODS = os.path.join(ROOT, "goods")
COINS = os.path.join(ROOT, "coins")
os.makedirs(GOODS, exist_ok=True)
os.makedirs(COINS, exist_ok=True)

FONT = r"C:\Windows\Fonts\STKAITI.TTF"  # 华文楷体，水墨字体感

SIZE = 512

# InkPalette colors
INK = (43, 36, 29)
INK_SOFT = (107, 90, 70)
PAPER = (246, 238, 221)
VERM = (194, 75, 51)
OCHRE = (201, 135, 61)
REED = (143, 165, 91)
DUSK = (122, 90, 130)
GLOW = (242, 197, 106)

def new_canvas():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

def with_shadow(img: Image.Image, offset=(0, 10), blur=14, alpha=90) -> Image.Image:
    # Soft ground shadow to lift shape off the paper.
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    w, h = img.size
    d.ellipse([w * 0.22, h * 0.82, w * 0.78, h * 0.94], fill=(0, 0, 0, alpha))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(shadow, offset)
    out.alpha_composite(img)
    return out

def draw_apple():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    # body
    d.ellipse([60, 120, 452, 480], fill=VERM, outline=INK, width=8)
    # top notch
    d.ellipse([200, 90, 312, 180], fill=PAPER, outline=None)
    d.ellipse([200, 90, 312, 180], outline=INK, width=8)
    # stem
    d.line([(256, 90), (280, 30)], fill=INK, width=12)
    # leaf
    leaf = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(leaf)
    ld.polygon([(285, 40), (360, 70), (330, 130), (275, 105)], fill=REED, outline=INK)
    img.alpha_composite(leaf)
    # highlight
    hl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.ellipse([120, 180, 220, 260], fill=(255, 255, 255, 110))
    hl = hl.filter(ImageFilter.GaussianBlur(12))
    img.alpha_composite(hl)
    return with_shadow(img)

def draw_pear():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    # teardrop body via composite of two ellipses
    body = Image.new("RGBA", img.size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.ellipse([120, 220, 400, 490], fill=REED)
    bd.ellipse([160, 100, 360, 320], fill=REED)
    body_smooth = body.filter(ImageFilter.GaussianBlur(1))
    img.alpha_composite(body_smooth)
    # outline (draw same shape darker on top with polygon approx)
    outline = Image.new("RGBA", img.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(outline)
    od.ellipse([120, 220, 400, 490], outline=INK, width=8)
    od.ellipse([160, 100, 360, 320], outline=INK, width=8)
    img.alpha_composite(outline)
    # stem
    d.line([(260, 100), (285, 40)], fill=INK, width=12)
    # highlight
    hl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.ellipse([160, 260, 240, 350], fill=(255, 255, 255, 110))
    hl = hl.filter(ImageFilter.GaussianBlur(12))
    img.alpha_composite(hl)
    return with_shadow(img)

def draw_jujube():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([170, 90, 342, 470], fill=VERM, outline=INK, width=8)
    d.line([(256, 90), (270, 40)], fill=INK, width=10)
    # highlight
    hl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.ellipse([200, 160, 250, 260], fill=(255, 255, 255, 110))
    hl = hl.filter(ImageFilter.GaussianBlur(10))
    img.alpha_composite(hl)
    return with_shadow(img)

def draw_peach():
    img = new_canvas()
    body = Image.new("RGBA", img.size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    # two overlapping ellipses to form the heart-top peach
    bd.ellipse([50, 140, 300, 480], fill=(230, 130, 130, 255))
    bd.ellipse([210, 140, 460, 480], fill=(230, 130, 130, 255))
    bd.ellipse([80, 240, 432, 490], fill=(230, 130, 130, 255))
    img.alpha_composite(body.filter(ImageFilter.GaussianBlur(1)))
    outline = Image.new("RGBA", img.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(outline)
    od.ellipse([50, 140, 300, 480], outline=INK, width=8)
    od.ellipse([210, 140, 460, 480], outline=INK, width=8)
    img.alpha_composite(outline)
    # cover the inner cross with body color
    cover = Image.new("RGBA", img.size, (0, 0, 0, 0))
    cd = ImageDraw.Draw(cover)
    cd.ellipse([100, 200, 412, 490], fill=(230, 130, 130, 255))
    img.alpha_composite(cover.filter(ImageFilter.GaussianBlur(1)))
    # outer big outline
    od2 = ImageDraw.Draw(img)
    od2.arc([100, 200, 412, 490], start=0, end=360, fill=INK, width=8)
    # leaf
    ld = ImageDraw.Draw(img)
    ld.polygon([(260, 140), (340, 90), (390, 170), (300, 200)], fill=REED, outline=INK)
    ld.line([(255, 135), (255, 200)], fill=INK, width=8)
    # highlight
    hl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.ellipse([120, 250, 220, 340], fill=(255, 255, 255, 120))
    hl = hl.filter(ImageFilter.GaussianBlur(12))
    img.alpha_composite(hl)
    return with_shadow(img)

def draw_candy():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    # wrapper body
    body_rect = [140, 200, 372, 340]
    d.rounded_rectangle(body_rect, radius=28, fill=DUSK, outline=INK, width=8)
    # twisted ends
    d.polygon([(140, 220), (60, 160), (60, 380), (140, 320)], fill=DUSK, outline=INK)
    d.polygon([(372, 220), (452, 160), (452, 380), (372, 320)], fill=DUSK, outline=INK)
    # stripes
    for x in (180, 240, 300):
        d.line([(x, 210), (x - 20, 330)], fill=GLOW, width=10)
    # highlight
    hl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.ellipse([160, 210, 250, 260], fill=(255, 255, 255, 110))
    hl = hl.filter(ImageFilter.GaussianBlur(10))
    img.alpha_composite(hl)
    return with_shadow(img)

def draw_coin(numeral: str, fill=OCHRE):
    img = new_canvas()
    d = ImageDraw.Draw(img)
    # coin disc
    d.ellipse([40, 40, 472, 472], fill=fill, outline=INK, width=10)
    # inner square hole (仿古币)
    d.rounded_rectangle([216, 216, 296, 296], radius=8, fill=PAPER, outline=INK, width=8)
    # numeral
    font = ImageFont.truetype(FONT, 180)
    # top-left and bottom-right of the numeral around the square hole
    d.text((256, 130), numeral, font=font, fill=INK, anchor="mm")
    d.text((256, 380), numeral, font=font, fill=INK, anchor="mm")
    # highlight
    hl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.ellipse([90, 90, 220, 200], fill=(255, 255, 255, 110))
    hl = hl.filter(ImageFilter.GaussianBlur(12))
    img.alpha_composite(hl)
    return with_shadow(img)

def main():
    apples = {
        "apple": draw_apple(),
        "pear": draw_pear(),
        "jujube": draw_jujube(),
        "peach": draw_peach(),
        "candy": draw_candy(),
    }
    for name, im in apples.items():
        p = os.path.join(GOODS, name + ".png")
        im.save(p, "PNG")
        print(f"goods/{name}.png {os.path.getsize(p)} bytes")
    coins = {
        "1": ("一", GLOW),
        "2": ("二", OCHRE),
        "5": ("五", OCHRE),
        "10": ("十", OCHRE),
    }
    for name, (ch, fill) in coins.items():
        im = draw_coin(ch, fill=fill)
        p = os.path.join(COINS, name + ".png")
        im.save(p, "PNG")
        print(f"coins/{name}.png {os.path.getsize(p)} bytes")

if __name__ == "__main__":
    main()