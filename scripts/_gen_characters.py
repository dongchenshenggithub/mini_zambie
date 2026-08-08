"""Generate per-character animated sprite sheets for mini_zambie (6 classes).

Each character gets a 4(col) x 4(row) frame sheet (one PNG: player_<class>.png):
  row 0  idle    (2 unique frames, duplicated to fill 4 cols)
  row 1  walk    (4 frames)
  row 2  attack  (3 unique frames, col3 duplicates col2)
  row 3  hurt    (2 unique frames, duplicated)

Cell base = 24x24, upscaled x3 (NEAREST) -> 288x288 on disk. The runtime slices
it with Sprite2D.hframes=4 / vframes=4, so every row MUST be exactly 4 cells wide.

Drawing is parametric: a shared humanoid builder + an alien builder, driven by a
per-character palette and feature flags, so the six classes read as distinct
characters (helmet / cyber-eye / topknot+visor / cat-ears / glasses+coat / tentacles)
while reusing one pose system for the animation frames.

Output: assets/pixel/player_0.png .. player_5.png  (+ _characters_gallery.png)
"""
import os
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "pixel")
os.makedirs(OUT, exist_ok=True)

CELL = 24
SCALE = 3
OUTLINE = (18, 18, 24, 255)


# ---------- low-level pixel helpers (cell-local, with offset) ----------
def new_cell():
    return Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))


def P(img, x, y, c, ox=0, oy=0):
    x, y = int(x) + ox, int(y) + oy
    if 0 <= x < CELL and 0 <= y < CELL:
        img.putpixel((x, y), c)


def rrect(img, x0, y0, x1, y1, c, ox=0, oy=0):
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            P(img, x, y, c, ox, oy)


def fell(img, cx, cy, rx, ry, c, ox=0, oy=0):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            if ((x - cx) ** 2) / (rx * rx) + ((y - cy) ** 2) / (ry * ry) <= 1.0:
                P(img, x, y, c, ox, oy)


def fdisc(img, cx, cy, r, c, ox=0, oy=0):
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                P(img, x, y, c, ox, oy)


def rline(img, x0, y0, x1, y1, c, ox=0, oy=0):
    x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
    dx = abs(x1 - x0); dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1; sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        P(img, x0, y0, c, ox, oy)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy; x0 += sx
        if e2 <= dx:
            err += dx; y0 += sy


def outline_cell(img, col):
    src = img.copy()
    px = src.load()
    for y in range(CELL):
        for x in range(CELL):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < CELL and 0 <= ny < CELL and px[nx, ny][3] > 0:
                        img.putpixel((x, y), col)
                        break


# ---------- pose tables ----------
IDLE = [{"bob": 0}, {"bob": 1}]
WALK = [
    {"legL": 0, "legR": 0, "bob": 0},
    {"legL": -1, "legR": 1, "bob": 1},
    {"legL": 0, "legR": 0, "bob": 0},
    {"legL": 1, "legR": -1, "bob": 1},
]
ATTACK = [{"arm": 0}, {"arm": 2}, {"arm": 1}]
HURT = [{"lean": -1, "arm_up": True}, {"lean": -1, "arm_up": True, "bob": 1}]

# Each row is padded to 4 columns (duplicated frames) for a uniform sheet.
ROWS = [
    [IDLE[0], IDLE[1], IDLE[0], IDLE[1]],
    WALK,
    [ATTACK[0], ATTACK[1], ATTACK[2], ATTACK[1]],
    [HURT[0], HURT[1], HURT[0], HURT[1]],
]


# ---------- humanoid builder ----------
def draw_humanoid(img, pal, feat, pose):
    ox = pose.get("lean", 0)
    oy = pose.get("bob", 0)
    arm = pose.get("arm", 0)
    legL = pose.get("legL", 0)
    legR = pose.get("legR", 0)
    arm_up = pose.get("arm_up", False)
    bd = pal["body_dark"]

    # legs
    rrect(img, 9 + legL, 16, 11 + legL, 21, bd, ox, oy)
    rrect(img, 12 + legR, 16, 14 + legR, 21, bd, ox, oy)
    rrect(img, 9 + legL, 21, 11 + legL, 22, (40, 30, 30, 255), ox, oy)
    rrect(img, 12 + legR, 21, 14 + legR, 22, (40, 30, 30, 255), ox, oy)

    # torso
    rrect(img, 8, 10, 15, 16, pal["body"], ox, oy)
    if feat.get("robe"):
        rrect(img, 8, 13, 15, 14, pal["accent"], ox, oy)          # sash
    if feat.get("tie"):
        rrect(img, 11, 10, 12, 15, pal["accent"], ox, oy)          # lab-coat tie
    if feat.get("beads"):
        for x in range(9, 15):
            if (x // 2) % 2 == 0:
                P(img, x, 16, pal["accent"], ox, oy)

    # back arm
    ay0 = 9 if arm_up else 11
    rrect(img, 6, ay0, 8, 15, bd, ox, oy)

    # front (weapon) arm -- thrusts forward on attack
    ax = 15 + arm * 2
    rrect(img, ax, 11, ax + 2, 15, pal["body"], ox, oy)
    fdisc(img, ax + 2, 13, 1, pal["skin"], ox, oy)                # hand

    # neck + head
    rrect(img, 11, 9, 12, 10, pal["skin"], ox, oy)
    fell(img, 12, 6, 4, 4, pal["skin"], ox, oy)

    # mech half-face (left side steel)
    if feat.get("mech_half"):
        rrect(img, 8, 3, 11, 9, pal["metal"], ox, oy)
        rrect(img, 8, 3, 11, 4, (160, 172, 186, 255), ox, oy)
        rline(img, 11, 3, 11, 9, pal["metal_dark"], ox, oy)
        rrect(img, 9, 7, 10, 8, (110, 120, 134, 255), ox, oy)     # panel

    # hair / helmet
    if feat.get("helmet"):
        rrect(img, 7, 0, 17, 3, pal["helmet"], ox, oy)
        rrect(img, 8, 1, 16, 2, pal["helmet_top"], ox, oy)
        rrect(img, 6, 3, 18, 4, pal["helmet_brim"], ox, oy)       # brim
        rrect(img, 20, 4, 23, 18, (150, 152, 160, 255), ox, oy)   # side hair
        rrect(img, 0, 4, 3, 18, (150, 152, 160, 255), ox, oy)
    elif feat.get("topknot"):
        rrect(img, 7, 2, 17, 5, pal["hair"], ox, oy)
        rrect(img, 9, 0, 15, 2, pal["hair"], ox, oy)
        fdisc(img, 12, 1, 2, pal["hair"], ox, oy)                # bun
        P(img, 12, 0, pal["accent"], ox, oy)                      # pin
    elif feat.get("bald_fringe"):
        rrect(img, 8, 2, 11, 5, pal["hair"], ox, oy)             # side fringe
        rrect(img, 13, 2, 16, 5, pal["hair"], ox, oy)
        rrect(img, 9, 0, 15, 2, pal["hair"], ox, oy)
    elif feat.get("cat_ears"):
        rrect(img, 7, 2, 17, 5, pal["hair"], ox, oy)
        # ears
        rrect(img, 6, -1, 9, 3, pal["hair"], ox, oy)
        rrect(img, 7, 0, 8, 2, pal["ear_inner"], ox, oy)
        rrect(img, 14, -1, 17, 3, pal["hair"], ox, oy)
        rrect(img, 15, 0, 16, 2, pal["ear_inner"], ox, oy)
    elif feat.get("bald"):
        pass  # mech_monk: shiny bald handled by skin showing
    else:
        rrect(img, 7, 2, 17, 5, pal["hair"], ox, oy)

    # eyes
    if feat.get("mech_half"):
        fdisc(img, 9, 6, 1, (245, 245, 250, 255), ox, oy)        # normal R eye
        P(img, 9, 6, (30, 30, 40, 255), ox, oy)
        fdisc(img, 9, 6, 2, pal["cyber"], ox, oy)                # glowing L eye
        P(img, 9, 6, (200, 255, 255, 255), ox, oy)
    elif feat.get("glasses"):
        rrect(img, 9, 6, 11, 8, (245, 245, 250, 255), ox, oy)    # eye whites
        rrect(img, 13, 6, 15, 8, (245, 245, 250, 255), ox, oy)
        P(img, 10, 7, (30, 30, 40, 255), ox, oy)
        P(img, 14, 7, (30, 30, 40, 255), ox, oy)
        rline(img, 8, 6, 9, 6, (40, 40, 52, 255), ox, oy)        # frames
        rline(img, 15, 6, 16, 6, (40, 40, 52, 255), ox, oy)
        rline(img, 11, 7, 13, 7, (40, 40, 52, 255), ox, oy)      # bridge
    else:
        P(img, 10, 6, (30, 30, 40, 255), ox, oy)
        P(img, 14, 6, (30, 30, 40, 255), ox, oy)

    # cyber visor over right eye
    if feat.get("visor"):
        rrect(img, 12, 5, 16, 7, pal["cyber"], ox, oy)
        P(img, 14, 6, (180, 255, 210, 255), ox, oy)
        rline(img, 8, 8, 11, 8, pal["cyber"], ox, oy)            # cheek circuit
        rline(img, 8, 8, 8, 10, pal["cyber"], ox, oy)
    # forehead mark
    if feat.get("forehead"):
        P(img, 12, 3, pal["accent"], ox, oy)
        P(img, 11, 4, pal["accent"], ox, oy)
        P(img, 13, 4, pal["accent"], ox, oy)
    # scar
    if feat.get("scar"):
        rline(img, 14, 5, 15, 9, (200, 120, 120, 255), ox, oy)
    # blush
    if feat.get("blush"):
        rrect(img, 8, 8, 10, 9, (235, 150, 150, 255), ox, oy)
        rrect(img, 14, 8, 16, 9, (235, 150, 150, 255), ox, oy)


# ---------- alien builder (octopus shooter) ----------
def draw_alien(img, pal, feat, pose):
    ox = pose.get("lean", 0)
    oy = pose.get("bob", 0)
    arm = pose.get("arm", 0)
    phase = pose.get("legL", 0)  # reuse legL as walk phase
    tent = pal["body"]

    # tentacles (4) at the bottom, wiggle with walk phase
    swing = [0, 1, 0, -1][(phase % 4 + 4) % 4]
    for i, tx in enumerate((6, 10, 14, 18)):
        wob = swing if i % 2 == 0 else -swing
        fdisc(img, tx + wob, 19, 2, tent, ox, oy)
        rrect(img, tx - 1 + wob, 17, tx + 1 + wob, 21, tent, ox, oy)
        P(img, tx - 1 + wob, 20, (220, 160, 240, 255), ox, oy)
        P(img, tx + 1 + wob, 20, (220, 160, 240, 255), ox, oy)

    # body / head bulb
    fell(img, 12, 8, 6, 7, pal["skin"], ox, oy)
    fdisc(img, 12, 9, 5, pal["skin"], ox, oy)

    # big alien eyes
    fell(img, 9, 7, 2, 3, (240, 240, 250, 255), ox, oy)
    fell(img, 15, 7, 2, 3, (240, 240, 250, 255), ox, oy)
    P(img, 9, 8, (30, 20, 50, 255), ox, oy)
    P(img, 15, 8, (30, 20, 50, 255), ox, oy)
    P(img, 10, 6, (180, 200, 255, 255), ox, oy)
    P(img, 16, 6, (180, 200, 255, 255), ox, oy)
    # mouth
    rrect(img, 11, 12, 13, 13, (120, 60, 150, 255), ox, oy)
    # cyan spots
    P(img, 8, 4, pal["accent"], ox, oy)
    P(img, 16, 4, pal["accent"], ox, oy)
    P(img, 12, 3, pal["accent"], ox, oy)


# ---------- character configs ----------
CHARS = {
    0: dict(
        name="veteran", body=(92, 104, 72), body_dark=(66, 76, 52),
        skin=(214, 176, 138), hair=(150, 152, 160), accent=(54, 62, 40),
        helmet=(72, 84, 54), helmet_top=(84, 96, 64), helmet_brim=(60, 70, 44),
        cyber=(80, 225, 235), ear_inner=(242, 180, 192),
        feat={"helmet": True, "scar": True},
    ),
    1: dict(
        name="mech_monk", body=(96, 78, 120), body_dark=(70, 56, 92),
        skin=(210, 170, 140), hair=(210, 170, 140), accent=(210, 175, 95),
        metal=(135, 146, 160), metal_dark=(95, 105, 118), cyber=(80, 225, 235),
        ear_inner=(242, 180, 192),
        feat={"mech_half": True, "cyber_eye": True, "bald": True, "beads": True, "robe": True},
    ),
    2: dict(
        name="cyber_cultivator", body=(70, 150, 120), body_dark=(50, 110, 90),
        skin=(220, 180, 150), hair=(42, 40, 56), accent=(200, 70, 70),
        cyber=(60, 220, 150), ear_inner=(242, 180, 192),
        feat={"topknot": True, "visor": True, "forehead": True, "robe": True},
    ),
    3: dict(
        name="cat_cafe_worker", body=(220, 168, 138), body_dark=(190, 130, 110),
        skin=(232, 192, 162), hair=(226, 142, 74), accent=(190, 130, 110),
        cyber=(80, 225, 235), ear_inner=(242, 180, 192),
        feat={"cat_ears": True, "blush": True},
    ),
    4: dict(
        name="professor", body=(232, 234, 240), body_dark=(196, 198, 206),
        skin=(206, 166, 134), hair=(236, 236, 242), accent=(170, 70, 90),
        cyber=(80, 225, 235), ear_inner=(242, 180, 192),
        feat={"glasses": True, "tie": True, "bald_fringe": True},
    ),
    5: dict(
        name="alien_shooter", alien=True, body=(150, 84, 188), body_dark=(110, 60, 140),
        skin=(168, 96, 206), accent=(90, 220, 230),
        cyber=(80, 225, 235), ear_inner=(242, 180, 192),
        feat={"tentacles": True},
    ),
}


def render_cell(cfg, pose):
    img = new_cell()
    if cfg.get("alien"):
        draw_alien(img, cfg, cfg["feat"], pose)
    else:
        draw_humanoid(img, cfg, cfg["feat"], pose)
    outline_cell(img, OUTLINE)
    return img


def build_sheet(cfg):
    base = Image.new("RGBA", (CELL * 4, CELL * 4), (0, 0, 0, 0))
    for row, poses in enumerate(ROWS):
        for col, pose in enumerate(poses):
            cell = render_cell(cfg, pose)
            base.paste(cell, (col * CELL, row * CELL))
    if SCALE > 1:
        base = base.resize((CELL * 4 * SCALE, CELL * 4 * SCALE), Image.NEAREST)
    return base


def gallery(cells):
    g = Image.new("RGBA", (CELL * 6, CELL), (0, 0, 0, 0))
    for i, c in enumerate(cells):
        g.paste(c, (i * CELL, 0))
    return g.resize((CELL * 6 * 4, CELL * 4), Image.NEAREST)


if __name__ == "__main__":
    idle_cells = []
    for cid in range(6):
        cfg = CHARS[cid]
        sheet = build_sheet(cfg)
        path = os.path.join(OUT, "player_%d.png" % cid)
        sheet.save(path)
        print("wrote", path, sheet.size)
        idle_cells.append(render_cell(cfg, IDLE[0]))
    gal = gallery(idle_cells)
    gal.save(os.path.join(OUT, "_characters_gallery.png"))
    print("wrote _characters_gallery.png", gal.size)
    print("DONE")
