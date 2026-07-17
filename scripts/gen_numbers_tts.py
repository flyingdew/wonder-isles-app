import asyncio, os
import edge_tts

VOICE = "zh-CN-XiaoxiaoNeural"
RATE = "-10%"
OUT = r"E:\demo\wonder-isles\wonder-isles-app\assets\voice"
os.makedirs(OUT, exist_ok=True)

CUES = [
    ("num_one",   "一只小雀落枝头，独自轻轻叫一声。"),
    ("num_two",   "两只黄鹂鸣翠柳，你一言来我一语。"),
    ("num_three", "三只小鸭排成排，一二三，走得开。"),
    ("num_four",  "四扇窗户四扇门，风一吹，都开门。"),
    ("num_five",  "五个指头一只手，握一握，拳头有。"),
    ("num_boss",  "一叶落，二鸟啼，三月里，四时新，五指连心，掌心生光。"),
]

async def one(name, text):
    path = os.path.join(OUT, name + ".mp3")
    com = edge_tts.Communicate(text=text, voice=VOICE, rate=RATE)
    await com.save(path)
    return path, os.path.getsize(path)

async def main():
    for name, text in CUES:
        p, sz = await one(name, text)
        print(f"{name}: {sz} bytes -> {p}")

asyncio.run(main())