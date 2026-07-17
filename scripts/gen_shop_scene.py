"""Generate assets/scenes/shop.png for 数之岛 backdrop.

Style follows the other four scene backgrounds: warm paper base, soft ink
brush outlines, low saturation, a single readable focal shape. Designed to
sit under the NumberIslePage ListView with a paper-toned overlay on top.

1024x768 (4:3) so BoxFit.cover on a portrait phone keeps the upper cloud-sea
plus the bamboo shop centered near the horizon.
"""
import os, math, random
from PIL import Image, ImageDraw, ImageFilter

ROOT = r"E:\demo\wonder-isles\wonder-isles-app\assets\scenes"
os.makedirs(ROOT, exist_ok=True)
OUT = os.path.join(ROOT, "shop.png")

W, H = 1024, 768

# InkPalette (matches lib/app_theme.dart).
INK = (43, 36, 29)
INK_SOFT = (107, 90, 70)
PAPER = (246, 238, 221)
PAPER_DEEP = (232, 219, 189)
VERM = (194, 75, 51)
OCHRE = (201, 135, 61)
REED = (143, 165, 91)
GLOW = (242, 197, 106)
DUSK = (122, 90, 130)


def paper_base() -> Image.Image:
    """Vertical gradient PAPER (top) -> PAPER_DEEP (bottom), plus a bit of noise."""
    base = Image.new("RGB", (W, H), PAPER)
    top = PAPER
    bot = PAPER_DEEP
    px = base.load()
    for y in range(H):
        t = y / (H - 1)
        # gentle ease-in
        t = t * t * (3 - 2 * t)
        r = int(top[0] * (1 - t) + bot[0] * t)
        g = int(top[1] * (1 - t) + bot[1] * t)
        b = int(top[2] * (1 - t) + bot[2] * t)
        for x in range(W):
            px[x, y] = (r, g, b)
    # subtle paper grain
    noise = Image.effect_noise((W, H), 6).convert("L")
    grain = Image.new("RGB", (W, H), (0, 0, 0))
    grain.putalpha(noise)
    base = base.convert("RGBA")
    base.alpha_composite(Image.blend(Image.new("RGBA", (W, H), (0, 0, 0, 0)), grain.convert("RGBA"), 0.04))
    return base


def draw_clouds(img: Image.Image):
    """Soft horizontal cloud-sea bands around y = 260."""
    cloud = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(cloud)
    bands = [
        (0.34, 0.10, (255, 253, 244, 210)),
        (0.42, 0.08, (255, 253, 244, 170)),
        (0.50, 0.06, (255, 253, 244, 140)),
    ]
    for cy_ratio, h_ratio, color in bands:
        cy = int(H * cy_ratio)
        ch = int(H * h_ratio)
        random.seed(int(cy_ratio * 1000))
        # a few overlapping ellipses per band
        x = -60
        while x < W + 80:
            w = random.randint(180, 320)
            hh = ch + random.randint(-6, 14)
            d.ellipse([x, cy - hh // 2, x + w, cy + hh // 2], fill=color)
            x += w - random.randint(70, 130)
    cloud = cloud.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(cloud)


def draw_mountain(img: Image.Image):
    """A faint distant peak behind the shop, low contrast."""
    m = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(m)
    d.polygon([
        (150, 430), (330, 260), (450, 340), (560, 220),
        (720, 320), (860, 240), (1024, 360), (1024, 460), (0, 460), (0, 430),
    ], fill=(122, 108, 92, 55))
    m = m.filter(ImageFilter.GaussianBlur(3))
    img.alpha_composite(m)


def draw_shop(img: Image.Image):
    """A tiny bamboo pop-up shop centered on the horizon."""
    shop = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(shop)

    # ground shadow
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([380, 560, 700, 610], fill=(0, 0, 0, 90))
    sh = sh.filter(ImageFilter.GaussianBlur(14))
    shop.alpha_composite(sh)

    # two bamboo posts
    for x in (420, 640):
        d.line([(x, 350), (x, 560)], fill=INK, width=8)
        # bamboo joints
        for jy in range(370, 560, 46):
            d.arc([x - 12, jy - 8, x + 12, jy + 8], 20, 160, fill=INK, width=5)

    # awning: ochre trapezoid + red banner strip
    d.polygon([(380, 360), (680, 360), (720, 320), (340, 320)], fill=OCHRE, outline=INK)
    d.line([(340, 320), (720, 320)], fill=INK, width=6)
    d.line([(380, 360), (680, 360)], fill=INK, width=6)
    # awning cord
    d.line([(370, 340), (690, 340)], fill=INK, width=3)

    # red hanging banner in the middle with vertical brush strokes
    d.rectangle([500, 340, 560, 480], fill=VERM, outline=INK, width=5)
    # simple brush marks to imply text without rendering CJK glyphs
    for i, y0 in enumerate((360, 400, 440)):
        d.line([(524, y0), (536, y0 + 22)], fill=PAPER, width=5)
        d.line([(534, y0 + 4), (522, y0 + 22)], fill=PAPER, width=3)

    # counter/table
    d.rectangle([395, 500, 665, 555], fill=(235, 216, 176), outline=INK, width=6)
    d.line([(395, 520), (665, 520)], fill=INK_SOFT, width=3)

    # three small produce dots (apple / pear / candy)
    d.ellipse([420, 470, 458, 508], fill=VERM, outline=INK, width=4)
    d.ellipse([465, 468, 505, 508], fill=REED, outline=INK, width=4)
    d.ellipse([605, 470, 640, 508], fill=GLOW, outline=INK, width=4)

    img.alpha_composite(shop)


def draw_vignette(img: Image.Image):
    """Warm darker paper corners so the ListView content pops."""
    v = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(v)
    d.ellipse([-200, -200, W + 200, H + 200], fill=(0, 0, 0, 0))
    # radial darken via corner rectangles that fade
    for i, a in enumerate((70, 55, 40, 25, 12)):
        pad = i * 40
        d.rectangle([pad, pad, W - pad, H - pad], outline=(60, 44, 28, a), width=40)
    v = v.filter(ImageFilter.GaussianBlur(40))
    img.alpha_composite(v)


def main():
    img = paper_base()
    draw_mountain(img)
    draw_clouds(img)
    draw_shop(img)
    draw_vignette(img)
    img.convert("RGB").save(OUT, "PNG", optimize=True)
    print("wrote", OUT, os.path.getsize(OUT))


if __name__ == "__main__":
    main()