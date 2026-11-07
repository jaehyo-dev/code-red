#!/usr/bin/env python3
"""v0.1.0 스프라이트·타일 생성기 (Pillow 필요).

모든 그림은 "도트 1칸 = 화면 3픽셀" 격자로 그린다: 작은 해상도(도트)로 그린 뒤 3배 확대(최근접).
- 슬라임: 확정 도안 assets/concept/evolution_v2.png 의 1단계를 잘라 도트 격자로 줄이고 팔레트에 맞춤
- 나머지(적, 수정, 버섯, 돌더미, 뼈, 항아리, 모닥불, 타일): 코드로 직접 그림 (시드 고정)
사용: python3 tools/make_sprites.py   (저장소 루트에서)
"""
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "sprites"
TILES = ROOT / "assets" / "tiles"
SCALE = 3  # 도트 1칸 = 3픽셀

# 슬라임 팔레트 (진화 도안 기준)
SLIME_PAL = {
    "outline": (0x2E, 0x08, 0x42), "dark": (0x4A, 0x0A, 0x6E), "body": (0x72, 0x01, 0x9C),
    "light": (0xBF, 0x1F, 0xFF), "high": (0xE0, 0x70, 0xFF), "white": (0xFF, 0xFF, 0xFF),
}


def save(img: Image.Image, path: Path) -> None:
    """도트 단위 그림을 3배 확대해 저장."""
    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST).save(path)


def outline(img: Image.Image, color) -> Image.Image:
    """불투명 부분 바깥에 1도트 외곽선을 두른다 (캔버스가 1도트씩 커짐)."""
    big = Image.new("RGBA", (img.width + 2, img.height + 2), (0, 0, 0, 0))
    big.paste(img, (1, 1))
    a = np.array(big)
    solid = a[:, :, 3] > 0
    grown = solid.copy()
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        grown |= np.roll(np.roll(solid, dy, 0), dx, 1)
    ring = grown & ~solid
    a[ring] = (*color, 255)
    return Image.fromarray(a)


def make_slime() -> None:
    src = Image.open(ROOT / "assets/concept/evolution_v2.png").convert("RGB").crop((20, 640, 280, 970))
    a = np.array(src).astype(int)
    key = (a[:, :, 1] > 140) & (a[:, :, 0] < 140) & (a[:, :, 2] < 140)
    ys, xs = np.where(~key)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    rgb = src.crop(box)
    mask = Image.fromarray(((~key)[box[1]:box[3], box[0]:box[2]] * 255).astype(np.uint8))
    w = 26
    h = round(rgb.height * w / rgb.width)
    rgb = rgb.resize((w, h), Image.BOX)
    mask = mask.resize((w, h), Image.BOX)
    pal = np.array(list(SLIME_PAL.values()))
    px = np.array(rgb).astype(int)
    out = np.zeros((h, w, 4), np.uint8)
    for y in range(h):
        for x in range(w):
            if mask.getpixel((x, y)) < 160:
                continue
            d = ((pal - px[y, x]) ** 2).sum(axis=1)
            out[y, x] = (*pal[d.argmin()], 255)
    split_slime(out)


# 슬라임 분리 레이어 (도트 좌표). 눈·입은 몸통과 따로 움직이고, 머리 곡선은 관성으로 끌려온다.
EYES_BOX = (6, 16, 20, 20)    # x0, y0, x1, y1 (끝 제외)
MOUTH_BOX = (9, 20, 17, 24)
CREST_ROWS = 8                # 위쪽 8줄이 머리 곡선


def split_slime(full: np.ndarray) -> None:
    """합쳐진 슬라임을 몸통(눈·입·곡선 없음), 머리 곡선, 눈, 작은 눈, 입으로 나눠 저장."""
    body_col = np.array([*SLIME_PAL["body"], 255], np.uint8)
    body = full.copy()
    eyes = np.zeros_like(full)
    mouth = np.zeros_like(full)
    for box, layer in ((EYES_BOX, eyes), (MOUTH_BOX, mouth)):
        x0, y0, x1, y1 = box
        layer[y0:y1, x0:x1] = full[y0:y1, x0:x1]
        body[y0:y1, x0:x1] = body_col  # 몸통 색으로 메움 (몸 밖 투명 칸은 눈·입 상자에 없음)
    crest = np.zeros_like(body)
    crest[:CREST_ROWS] = body[:CREST_ROWS]
    body[:CREST_ROWS] = 0
    crest[CREST_ROWS, 18:] = full[CREST_ROWS, 18:]  # 곡선 끝에 매달린 점도 곡선 쪽으로
    body[CREST_ROWS, 18:] = 0
    small = np.zeros_like(full)  # 위를 볼 때: 눈이 작아짐 (눈마다 2x2 흰색)
    for x in (7, 17):
        small[17:19, x:x + 2] = (*SLIME_PAL["white"], 255)
    for name, arr in (("slime_body", body), ("slime_crest", crest), ("slime_eyes", eyes),
                      ("slime_eyes_small", small), ("slime_mouth", mouth)):
        save(Image.fromarray(arr), OUT / f"{name}.png")


# 한 입에 삼키기 프레임 (v0.1.5): 오른쪽을 보는 기준 그림. 왼쪽은 좌우 뒤집기, 위·아래·대각은 게임에서 회전한다.
BITE = 56  # 프레임 한 변 (도트). 몸 중심이 (28, 28)
MOUTH_DARK = (0x14, 0x03, 0x1F, 255)
TONGUE = (0xC0, 0x40, 0x8F, 255)


def _bite_canvas(parts, cavity=None, teeth=(), eyes=(), window=None, drips=()):
    """parts: 몸을 이루는 타원 상자들. cavity: 입 안(어두운 타원). teeth: 이빨 삼각형 점 3개씩. eyes: 눈 위치."""
    pal = {k: (*v, 255) for k, v in SLIME_PAL.items()}
    solid = Image.new("L", (BITE, BITE), 0)
    d = ImageDraw.Draw(solid)
    for box in parts:
        d.ellipse(box, fill=255)
    for x, y, h in drips:  # 아래로 흘러내리는 점액
        d.rectangle((x, y, x + 1, y + h), fill=255)
    if cavity:
        d.ellipse(cavity, fill=0)
    img = Image.new("RGBA", (BITE, BITE), (0, 0, 0, 0))
    img.paste(Image.new("RGBA", (BITE, BITE), pal["body"]), mask=solid)
    di = ImageDraw.Draw(img)
    if cavity:
        # 입 안: 몸 안쪽 경계는 살려 두려고 몸 마스크와 겹치는 곳만 칠하지 않고, 어두운 안쪽을 따로 칠한다
        inner = Image.new("L", (BITE, BITE), 0)
        ImageDraw.Draw(inner).ellipse(cavity, fill=255)
        img.paste(Image.new("RGBA", (BITE, BITE), MOUTH_DARK), mask=inner)
        cx0, cy0, cx1, cy1 = cavity
        di.ellipse((cx0 + 4, cy1 - 9, cx1 - 6, cy1 + 1), fill=TONGUE)  # 혀
        for tri in teeth:
            di.polygon(tri, fill=pal["white"])
    # 하이라이트(왼쪽 위)와 어두운 아랫면
    a = np.array(img)
    ys, xs = np.where(a[:, :, 3] > 0)
    top, left = ys.min(), xs.min()
    for y, x in zip(ys, xs):
        if tuple(a[y, x][:3]) == SLIME_PAL["body"] and ((x - left) + (y - top) < 9):
            a[y, x] = (*SLIME_PAL["light"], 255)
    img = Image.fromarray(a)
    di = ImageDraw.Draw(img)
    if window:  # 감싼 몸 안의 비치는 창 (적이 보이는 곳)
        di.ellipse(window, fill=(*SLIME_PAL["dark"], 255))
    for x, y in eyes:  # 눈: 흰색 + 모양
        di.rectangle((x, y + 1, x + 2, y + 1), fill=pal["white"])
        di.rectangle((x + 1, y, x + 1, y + 2), fill=pal["white"])
    out = outline(img, SLIME_PAL["outline"])
    canvas = Image.new("RGBA", (BITE, BITE), (0, 0, 0, 0))
    canvas.paste(out, (-1, -1))
    return canvas


def make_bite_frames() -> None:
    # 1) 솟으며 입이 벌어지기 시작: 앞쪽이 갈라지는 좁은 입
    a = _bite_canvas(
        parts=[(15, 8, 41, 46), (28, 11, 46, 25), (28, 29, 46, 43)],
        cavity=(30, 21, 46, 34),
        teeth=[((32, 21), (35, 21), (33, 25)), ((38, 21), (41, 21), (39, 25)),
               ((33, 34), (36, 34), (35, 30)), ((39, 34), (42, 34), (40, 30))],
        eyes=[(19, 14), (26, 12)])
    save(a, OUT / "slime_bite_a.png")
    # 2) 입이 크게 벌어지고 이빨이 보임
    b = _bite_canvas(
        parts=[(12, 8, 38, 48), (24, 5, 53, 25), (24, 31, 53, 51)],
        cavity=(27, 15, 52, 41),
        teeth=[((29, 15), (33, 15), (31, 21)), ((36, 15), (40, 15), (38, 21)), ((43, 16), (47, 16), (45, 22)),
               ((30, 41), (34, 41), (32, 35)), ((37, 41), (41, 41), (39, 35)), ((44, 40), (48, 40), (46, 34))],
        eyes=[(15, 14), (23, 10)])
    save(b, OUT / "slime_bite_b.png")
    # 3) 적 위로 덮쳐 감쌈: 넓고 낮은 돔. 가운데 창에 적이 비친다. 위쪽에 눈과 이빨
    w = _bite_canvas(
        parts=[(7, 10, 49, 49), (11, 6, 45, 30)],
        window=(15, 19, 41, 43),
        teeth=[((21, 22), (24, 22), (22, 25)), ((26, 22), (29, 22), (27, 25)), ((31, 22), (34, 22), (32, 25))],
        eyes=[(18, 12), (35, 12)],
        drips=[(10, 49, 3), (24, 49, 2), (40, 49, 4)])
    save(w, OUT / "slime_wrap.png")


def make_enemy() -> None:
    """동굴 딱정벌레: 밝은 주황 외곽선이라 어두운 바닥에서도 보인다."""
    img = Image.new("RGBA", (13, 10), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((1, 1, 11, 8), fill=(0xC8, 0x3C, 0x2E, 255))  # 몸통
    d.ellipse((3, 2, 8, 5), fill=(0xFF, 0x7A, 0x4A, 255))  # 등 하이라이트
    d.rectangle((0, 7, 1, 8), fill=(0xFF, 0xB0, 0x5C, 255))  # 다리
    d.rectangle((11, 7, 12, 8), fill=(0xFF, 0xB0, 0x5C, 255))
    d.rectangle((2, 9, 3, 9), fill=(0xFF, 0xB0, 0x5C, 255))
    d.rectangle((9, 9, 10, 9), fill=(0xFF, 0xB0, 0x5C, 255))
    for x in (4, 8):  # 눈
        d.point((x, 6), fill=(0xFF, 0xF2, 0x9A, 255))
    save(outline(img, (0xFF, 0xE0, 0x8A)), OUT / "enemy.png")


def make_crystal() -> None:
    img = Image.new("RGBA", (15, 17), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(7, 0), (10, 4), (10, 15), (4, 15), (4, 4)], fill=(0x5C, 0xD8, 0xF0, 255))  # 큰 결정
    d.polygon([(7, 0), (10, 4), (7, 6)], fill=(0xC8, 0xF8, 0xFF, 255))
    d.polygon([(4, 4), (7, 6), (7, 15), (4, 15)], fill=(0x2E, 0x9C, 0xC8, 255))
    d.polygon([(1, 8), (3, 6), (4, 15), (0, 15)], fill=(0x3C, 0xB8, 0xE0, 255))  # 왼쪽 작은 결정
    d.polygon([(11, 9), (13, 7), (14, 15), (10, 15)], fill=(0x3C, 0xB8, 0xE0, 255))  # 오른쪽 작은 결정
    d.line([(8, 6), (8, 13)], fill=(0xC8, 0xF8, 0xFF, 255))
    save(outline(img, (0x10, 0x2A, 0x44)), OUT / "crystal.png")


def make_mushroom() -> None:
    img = Image.new("RGBA", (11, 9), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for cx, top, r in ((5, 0, 2), (1, 3, 1), (9, 4, 1)):  # 큰 버섯 1 + 작은 버섯 2
        d.rectangle((cx, top + r + 1, cx, 8), fill=(0xB8, 0xF0, 0xE8, 255))
        d.ellipse((cx - r, top, cx + r, top + r + 1), fill=(0x5C, 0xF0, 0xD8, 255))
        d.point((cx - 1, top + 1), fill=(0xFF, 0xFF, 0xFF, 255))
    save(outline(img, (0x0E, 0x30, 0x38)), OUT / "mushroom.png")


def make_rubble() -> None:
    rng = random.Random(11)
    img = Image.new("RGBA", (15, 11), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for x, y, w, h in ((1, 5, 5, 5), (6, 6, 6, 4), (9, 2, 5, 5), (4, 1, 5, 5)):
        base = rng.choice([(0x80, 0x84, 0x90), (0x70, 0x74, 0x80), (0x90, 0x94, 0xA0)])
        d.rectangle((x, y, x + w - 1, y + h - 1), fill=(*base, 255))
        d.line([(x, y), (x + w - 1, y)], fill=(0xB8, 0xBC, 0xC8, 255))
        d.line([(x, y + h - 1), (x + w - 1, y + h - 1)], fill=(0x50, 0x54, 0x60, 255))
    d.point((2, 5), fill=(0x4C, 0x8C, 0x50, 255))  # 이끼
    d.point((10, 2), fill=(0x4C, 0x8C, 0x50, 255))
    save(outline(img, (0x1C, 0x1C, 0x2C)), OUT / "rubble.png")


def make_bones() -> None:
    img = Image.new("RGBA", (15, 9), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bone, shade = (0xE8, 0xE0, 0xC8, 255), (0xB0, 0xA8, 0x90, 255)
    for i in range(4):  # 갈비뼈
        d.arc((1 + i * 2, 0, 5 + i * 2, 6), 180, 360, fill=bone)
    d.line([(1, 7), (11, 7)], fill=shade)
    d.line([(2, 8), (13, 5)], fill=bone)  # 긴 뼈
    d.rectangle((13, 4, 14, 5), fill=bone)
    d.rectangle((1, 8, 2, 8), fill=bone)
    save(outline(img, (0x2C, 0x28, 0x24)), OUT / "bones.png")


def make_pot() -> None:
    img = Image.new("RGBA", (13, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    clay, dark, light = (0xB8, 0x68, 0x3C, 255), (0x80, 0x44, 0x28, 255), (0xE0, 0x90, 0x58, 255)
    d.rectangle((3, 0, 9, 2), fill=clay)  # 입구
    d.rectangle((4, 1, 8, 1), fill=(0x28, 0x14, 0x10, 255))
    d.ellipse((0, 2, 12, 13), fill=clay)
    d.arc((0, 2, 12, 13), 100, 260, fill=light)
    d.arc((0, 2, 12, 13), 280, 80, fill=dark)
    d.line([(2, 7), (4, 9), (6, 7), (8, 9), (10, 7)], fill=dark)  # 무늬
    save(outline(img, (0x2A, 0x14, 0x10)), OUT / "pot.png")


def make_campfire() -> None:
    img = Image.new("RGBA", (15, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(7, 0), (10, 5), (11, 9), (3, 9), (4, 5)], fill=(0xFF, 0x8C, 0x1C, 255))  # 불꽃
    d.polygon([(7, 3), (9, 7), (9, 9), (5, 9), (5, 7)], fill=(0xFF, 0xD8, 0x4C, 255))
    d.polygon([(7, 6), (8, 9), (6, 9)], fill=(0xFF, 0xFA, 0xD0, 255))
    d.line([(2, 10), (12, 10)], fill=(0x5C, 0x30, 0x1C, 255))  # 장작
    for x in (0, 3, 6, 9, 12):  # 돌 테두리
        d.rectangle((x, 11, x + 2, 13), fill=(0x88, 0x8C, 0x98, 255))
        d.line([(x, 11), (x + 2, 11)], fill=(0xC0, 0xC4, 0xD0, 255))
    save(outline(img, (0x24, 0x18, 0x1C)), OUT / "campfire.png")


def make_tiles() -> None:
    """tiles.png: 16x16 도트 타일 격자.
    0행: 바닥 4종 / 1행: 벽 3종 / 2행: 바닥과 맞닿은 벽 (위·아래·왼쪽·오른쪽 벽의 안쪽 줄)."""
    rng = random.Random(7)
    atlas = Image.new("RGBA", (16 * 4, 16 * 3), (0, 0, 0, 0))

    def floor(i):
        t = Image.new("RGBA", (16, 16), (0x34, 0x38, 0x5C, 255))
        d = ImageDraw.Draw(t)
        for _ in range(26):  # 점 질감
            x, y = rng.randrange(16), rng.randrange(16)
            d.point((x, y), fill=rng.choice([(0x2C, 0x30, 0x52, 255), (0x3C, 0x40, 0x68, 255)]))
        x, y = rng.randrange(2, 9), rng.randrange(3, 12)  # 갈라진 틈
        d.line([(x, y), (x + 3, y + 1), (x + 5, y)], fill=(0x24, 0x28, 0x44, 255))
        if i == 3:  # 이끼 얼룩
            for _ in range(5):
                d.point((rng.randrange(16), rng.randrange(16)), fill=(0x2C, 0x6C, 0x68, 255))
        return t

    def wall(i):
        t = Image.new("RGBA", (16, 16), (0x1A, 0x1C, 0x34, 255))
        d = ImageDraw.Draw(t)
        for k in range(3):  # 세로 바위 기둥
            x = k * 5 + rng.randrange(0, 2)
            d.rectangle((x, 0, x + 3, 15), fill=(0x24, 0x28, 0x46, 255))
            d.line([(x, 0), (x, 15)], fill=(0x30, 0x34, 0x58, 255))
        for _ in range(8):
            d.point((rng.randrange(16), rng.randrange(16)), fill=(0x12, 0x14, 0x26, 255))
        return t

    def edge(base):  # 바닥 쪽(아래)에 발광 이끼 줄을 얹은 벽
        t = base.copy()
        d = ImageDraw.Draw(t)
        for x in range(16):
            h = rng.choice([1, 2, 2, 3])
            d.line([(x, 15), (x, 16 - h)], fill=(0x2C, 0xB8, 0x98, 255) if h > 1 else (0x3C, 0xE0, 0xC0, 255))
        return t

    for i in range(4):
        atlas.paste(floor(i), (i * 16, 0))
    walls = [wall(i) for i in range(3)]
    for i, w in enumerate(walls):
        atlas.paste(w, (i * 16, 16))
    e = edge(walls[0])  # 위 벽의 안쪽 줄: 이끼가 아래쪽. 나머지는 회전
    atlas.paste(e, (0, 32))
    atlas.paste(e.rotate(180), (16, 32))  # 아래 벽: 이끼가 위쪽
    atlas.paste(e.rotate(-90), (32, 32))  # 왼쪽 벽: 이끼가 오른쪽
    atlas.paste(e.rotate(90), (48, 32))  # 오른쪽 벽: 이끼가 왼쪽
    save(atlas, TILES / "tiles.png")


if __name__ == "__main__":
    for fn in (make_slime, make_enemy, make_crystal, make_mushroom, make_rubble, make_bones,
               make_pot, make_campfire, make_tiles):
        fn()
    print("완료:", OUT, TILES)
