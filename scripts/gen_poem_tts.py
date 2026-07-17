"""Generate per-poem TTS mp3 for 字之岛 (4 scene poems + boss).

Reads assets/data/characters.json to expand slot ids like 'ri' -> '日',
so it stays in sync with the source of truth.
"""
import asyncio, json, os
import edge_tts

ROOT = r"E:\demo\wonder-isles\wonder-isles-app"
OUT = os.path.join(ROOT, "assets", "voice")
CHARS_JSON = os.path.join(ROOT, "assets", "data", "characters.json")
os.makedirs(OUT, exist_ok=True)

VOICE = "zh-CN-XiaoxiaoNeural"
RATE = "-20%"  # slower than 数之岛 rhymes so kids can echo line-by-line

with open(CHARS_JSON, encoding="utf-8") as f:
    CHAR = {c["id"]: c["char"] for c in json.load(f)}

# (slot_id, ...) or plain string tokens per line. Mirrors lib/data/poems.dart.
SCENE_POEMS = {
    "river":   [["ri","出江上，"], ["yue","映",("shui",),"中，"], ["yu","跃",("huo",),"旁。"]],
    "forest":  [["shan","中",("mu_tree",),"深，"], ["niao","鸣",("yu_rain",),"落，"], ["抬",("mu_eye",),"望远。"]],
    "village": [["ren","在",("men",),"内，"], ["开",("kou",),"问路，"], ["shou","指",("er",),"听。"]],
    "field":   [["tian","上",("niu",),"耕，"], ["yang",("ma",),"奔走，"], ["抬",("zu",),"前行。"]],
}

# For scene poems the first list item can be either a slot id or plain text.
# We inspect CHAR to decide.

BOSS = [
    [("ri",), "出", ("shan",), "间，"],
    [("yu_rain",), "落", ("shui",), "中；"],
    [("mu_tree",), "下", ("huo",), "明，"],
    [("yu",), "跃", ("niao",), "鸣。"],
    [("niu",), ("yang",), "入", ("tian",), "，"],
    [("ma",), "行", ("men",), "东；"],
    [("ren",), "开", ("kou",), "语，"],
    [("mu_eye",), "视", ("er",), "听。"],
    [("shou",), "举", ("zu",), "行，"],
    [("yue",), "照其中。"],
]


def token_to_text(tok):
    if isinstance(tok, tuple):
        return CHAR[tok[0]]
    return tok


def render_line(line):
    return "".join(token_to_text(t) for t in line)


def scene_lines():
    result = {}
    for scene, raw_lines in SCENE_POEMS.items():
        rendered = []
        for raw in raw_lines:
            parts = []
            for t in raw:
                if isinstance(t, tuple):
                    parts.append(CHAR[t[0]])
                elif isinstance(t, str) and t in CHAR:
                    parts.append(CHAR[t])
                else:
                    parts.append(t)
            rendered.append("".join(parts))
        result[scene] = rendered
    return result


async def synth(name, lines):
    # Join lines with a short pause via full-width space so Edge TTS breathes.
    text = "。".join(l.rstrip("。，；") for l in lines) + "。"
    # Actually keep the punctuation intact for prosody:
    text = "".join(lines)
    path = os.path.join(OUT, name + ".mp3")
    com = edge_tts.Communicate(text=text, voice=VOICE, rate=RATE)
    await com.save(path)
    return path, os.path.getsize(path), text


async def main():
    scene_map = scene_lines()
    for scene, lines in scene_map.items():
        p, sz, t = await synth("poem_" + scene, lines)
        print("poem_" + scene, sz, repr(t), "->", p)
    boss_lines = [render_line(l) for l in BOSS]
    p, sz, t = await synth("poem_boss", boss_lines)
    print("poem_boss", sz, repr(t), "->", p)


if __name__ == "__main__":
    asyncio.run(main())