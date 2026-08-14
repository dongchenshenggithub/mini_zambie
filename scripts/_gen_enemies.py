"""Generate per-enemy-type animated sprite sheets for mini_zambie (15 types).

Each enemy gets a 4(col) x 4(row) frame sheet (one PNG):
  row 0  idle    (2 unique frames, cols 2-3 duplicate 0-1)
  row 1  walk    (4 frames: leg swing + body bob)
  row 2  attack  (3 unique frames, col3 = col2 hold)
  row 3  hurt    (2 unique frames, duplicated)

Cell base = 24x24, upscaled x3 (NEAREST) -> 288x288 on disk.
Runtime slices with Sprite2D.hframes=4 / vframes=4.

Enemy types (match GameEnums.ZombieType + boss paths in zombie_base/boss_base):
  normal, fast, tank, self_destruct, mecha_mutant,
  bio_shield, nanomite, hologram,
  elite_bio_tyrant, elite_mecha_soldier, elite_gene_fusion,
  boss_king, boss_titan, boss_nano, boss_alpha

Output: assets/pixel/zombie_*.png + assets/pixel/boss_*.png  (+ _enemies_gallery.png)
"""
import os, random
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "pixel")
os.makedirs(OUT, exist_ok=True)

CELL = 24
SCALE = 3
OUTLINE = (18, 18, 24, 255)

# ---------- low-level pixel helpers ----------
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
            if ((x - cx) ** 2 / max(rx * rx, 0.01)) + ((y - cy) ** 2 / max(ry * ry, 0.01)) <= 1.0:
                P(img, x, y, c, ox, oy)

def fdisc(img, cx, cy, r, c, ox=0, oy=0):
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                P(img, x, y, c, ox, oy)

def line(img, x0, y0, x1, y1, c, ox=0, oy=0):
    """Bresenham-style line."""
    dx, dy = abs(x1 - x0), abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    while True:
        P(img, x0, y0, c, ox, oy)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy; x0 += sx
        if e2 < dx:
            err += dx; y0 += sy

def outline_ellipse(img, cx, cy, rx, ry, c, ox=0, oy=0):
    """Draw ellipse outline only."""
    pts = set()
    for t in range(0, 360, 5):
        import math
        rad = math.radians(t)
        px = int(cx + rx * math.cos(rad))
        py = int(cy + ry * math.sin(rad))
        pts.add((px + ox, py + oy))
    for p in pts:
        if 0 <= p[0] < CELL and 0 <= p[1] < CELL:
            img.putpixel(p, c)


# ---------- shared drawing primitives for monsters ----------

def draw_head(img, cx, cy, skin_c, outline_c, ox=0, oy=0, w=5, h=6):
    """Rounded rectangle head."""
    rrect(img, cx - w//2, cy - h//2, cx + w//2, cy + h//2, skin_c, ox, oy)
    # outline border
    for dx in range(-w//2, w//2 + 1):
        P(img, cx + dx, cy - h//2, outline_c, ox, oy)
        P(img, cx + dx, cy + h//2, outline_c, ox, oy)
    for dy in range(-h//2, h//2 + 1):
        P(img, cx - w//2, cy + dy, outline_c, ox, oy)
        P(img, cx + w//2, cy + dy, outline_c, ox, oy)

def draw_eye(img, cx, cy, eye_c, ox=0, oy=0, w=1):
    """One or two pixel eye."""
    P(img, cx, cy, eye_c, ox, oy)
    if w >= 2:
        P(img, cx + 1, cy, eye_c, ox, oy)

def draw_body(img, cx, cy, body_c, outline_c, ox=0, oy=0, w=6, h=8):
    """Torso."""
    rrect(img, cx - w//2, cy - h//2, cx + w//2, cy + h//2, body_c, ox, oy)
    # outline
    for dx in range(-w//2, w//2 + 1):
        P(img, cx + dx, cy - h//2, outline_c, ox, oy)
        P(img, cx + dx, cy + h//2, outline_c, ox, oy)
    for dy in range(-h//2, h//2 + 1):
        P(img, cx - w//2, cy + dy, outline_c, ox, oy)
        P(img, cx + w//2, cy + dy, outline_c, ox, oy)

def draw_leg(img, cx, cy_top, leg_c, ox=0, oy=0, side=1, stride=0):
    """Leg: side=-1 left, side=1 right. stride offsets for walk."""
    offset = stride * side * 2
    # thigh
    rrect(img, cx + side * 1 - 1, cy_top, cx + side * 1 + 1, cy_top + 5 + offset, leg_c, ox, oy)
    # shin
    rrect(img, cx + side * 1 - 1, cy_top + 5 + offset, cx + side * 1 + 1, cy_top + 10 - offset, leg_c, ox, oy)
    # foot
    rrect(img, cx + side * 1 - 2, cy_top + 10 - offset, cx + side * 1 + 2, cy_top + 12 - offset, OUTLINE, ox, oy)

def draw_arm(img, cx, cy, arm_c, ox=0, oy=0, side=1, angle=0, reach=0):
    """Arm with optional angle/reach for attack."""
    ax = cx + side * (4 + reach)
    ay = cy - 1 + angle
    line(img, cx + side * 3, cy, ax, ay, arm_c, ox, oy)
    # hand
    fdisc(img, ax, ay, 1, arm_c, ox, oy)

def draw_zombie_mouth(img, cx, cy, ox=0, oy=0):
    """Simple zombie mouth (dark line or open)."""
    P(img, cx, cy + 1, (30, 20, 20, 255), ox, oy)
    P(img, cx - 1, cy + 1, (30, 20, 20, 255), ox, oy)
    P(img, cx + 1, cy + 1, (30, 20, 20, 255), ox, oy)


# ========== ENEMY TYPE BUILDERS ==========

# Each builder returns a list of 16 cells (4x4 grid, row-major order).
# Parameters: palette dict with keys: skin, body, accent, dark, eye, outline

def build_humanoid_zombie(palette, is_fast=False, is_tank=False, has_armor=False):
    """Standard humanoid zombie (normal/fast/tank)."""
    cells = []
    s, b, a, d, e, oc = palette["skin"], palette["body"], palette["accent"], palette["dark"], palette["eye"], palette["outline"]
    bw = 8 if is_tank else 6  # body width
    bh = 10 if is_tank else 8  # body height
    hw = 6 if is_tank else 5   # head width
    hh = 7 if is_tank else 6   # head height
    leg_len = 6 if is_tank else 5

    for row in range(4):
        for col in range(4):
            cell = new_cell()
            cx, cy = CELL // 2, CELL // 2

            # --- animation parameters ---
            bob = 0
            leg_swing = 0
            arm_reach = 0
            arm_angle = 0
            tilt = 0
            mouth_open = False
            flash = False

            if row == 0:  # idle
                bob = [0, 1][col % 2]
                leg_swing = [0, 1][col % 2]
            elif row == 1:  # walk
                bob = [0, 1, 0, -1][col]
                leg_swing = [-2, 2, -2, 2][col]
                if is_fast:
                    leg_swing = [-3, 3, -3, 3][col]
                    bob = [0, 2, 0, -2][col]
            elif row == 2:  # attack
                arm_reach = [0, 3, 5, 5][col]
                arm_angle = [0, -2, -4, -4][col]
                tilt = [0, 1, 2, 2][col]
                mouth_open = col >= 1
            elif row == 3:  # hurt
                flash = True
                tilt = [2, -1][col % 2]
                bob = -1

            # Head position
            hc = cx + tilt
            hy = cy - bh//2 - hh//2 - 2 + bob

            # Legs
            ly = cy + bh//2 - 1
            draw_leg(cell, cx, ly, d, 0, 0, -1, leg_swing)
            draw_leg(cell, cx, ly, d, 0, 0, 1, -leg_swing)

            # Body
            draw_body(cell, cx, cy + bob, b, oc, 0, 0, bw, bh)

            # Armor plates if tank/elite
            if is_tank or has_armor:
                rrect(cell, cx - bw//2 - 1, cy - bh//3 + bob, cx - 1, cy - bh//6 + bob, a, 0, 0)
                rrect(cell, cx + 1, cy - bh//3 + bob, cx + bw//2 + 1, cy - bh//6 + bob, a, 0, 0)

            # Head
            draw_head(cell, hc, hy, s, oc, 0, 0, hw, hh)

            # Eyes
            ey = hy - 1
            if not flash:
                draw_eye(cell, hc - 2, ey, e, 0, 0, 2 if not is_fast else 1)
                draw_eye(cell, hc + 1, ey, e, 0, 0, 2 if not is_fast else 1)
            else:
                # white flash on hurt
                draw_eye(cell, hc - 2, ey, (255, 255, 255, 255), 0, 0, 2)
                draw_eye(cell, hc + 1, ey, (255, 255, 255, 255), 0, 0, 2)

            # Mouth
            if mouth_open:
                rrect(cell, hc - 1, hy + 2, hc + 1, hy + 4, d, 0, 0)
                # teeth
                P(cell, hc - 1, hy + 3, (220, 220, 200, 255), 0, 0)
                P(cell, hc + 1, hy + 3, (220, 220, 200, 255), 0, 0)
            else:
                draw_zombie_mouth(cell, hc, hy, 0, 0)

            # Arms
            draw_arm(cell, cx, cy + bob, s, 0, 0, -1, -arm_angle, arm_reach)
            draw_arm(cell, cx, cy + bob, s, 0, 0, 1, arm_angle, 0)

            # Tattered cloth detail
            if not is_tank and not has_armor:
                for i in range(3):
                    tx = cx - bw//2 + 2 + i * 2
                    ty = cy + bh//2 + bob
                    P(cell, tx, ty, d, 0, 0)
                    if i % 2 == 0:
                        P(cell, tx, ty + 1, d, 0, 0)

            cells.append(cell)
    return cells


def build_self_destruct_zombie(palette):
    """Orange glowing self-destruct zombie with visible core."""
    cells = []
    s, b, a, d, e, oc = palette["skin"], palette["body"], palette["accent"], palette["dark"], palette["eye"], palette["outline"]
    glow_colors = [(255, 100, 0, 180), (255, 150, 50, 200), (255, 200, 100, 220), (255, 150, 50, 200)]

    for row in range(4):
        for col in range(4):
            cell = new_cell()
            cx, cy = CELL // 2, CELL // 2
            bob = 0; leg_swing = 0; pulse = 0; arm_r = 0; flash = False

            if row == 0:
                bob = [0, 1][col % 2]; pulse = col % 2
            elif row == 1:
                bob = [0, 1, 0, -1][col]; leg_swing = [-2, 2, -2, 2][col]; pulse = col % 2
            elif row == 2:
                arm_r = [0, 4, 6, 6][col]; pulse = 2
            elif row == 3:
                flash = True; pulse = 3

            # Glowing aura
            gc = glow_colors[pulse % len(glow_colors)]
            fell(cell, cx, cy + bob, 9, 11, gc, 0, 0)

            # Body (smaller, more hunched)
            draw_body(cell, cx, cy + bob, s, oc, 0, 0, 5, 7)
            # Glowing core in chest
            fell(cell, cx, cy - 1 + bob, 2, 2, a, 0, 0)

            # Head
            hc = cx; hy = cy - 6 + bob
            draw_head(cell, hc, hy, s, oc, 0, 0, 5, 6)
            if not flash:
                draw_eye(cell, hc - 2, hy - 1, e, 0, 0, 2)
                draw_eye(cell, hc + 1, hy - 1, e, 0, 0, 2)
            else:
                draw_eye(cell, hc - 2, hy - 1, (255, 255, 255, 255), 0, 0, 2)
                draw_eye(cell, hc + 1, hy - 1, (255, 255, 255, 255), 0, 0, 2)
            draw_zombie_mouth(cell, hc, hy, 0, 0)

            # Legs
            draw_leg(cell, cx, cy + 4 + bob, d, 0, 0, -1, leg_swing)
            draw_leg(cell, cx, cy + 4 + bob, d, 0, 0, 1, -leg_swing)

            # Arms (reaching forward when attacking, glowing hands)
            draw_arm(cell, cx, cy + bob, s, 0, 0, -1, 0, arm_r)
            draw_arm(cell, cx, cy + bob, s, 0, 0, 1, 0, 0)
            if arm_r > 3:
                # glowing hand
                fdisc(cell, cx + 4 + arm_r, cy - 3 + bob, 2, a, 0, 0)

            # Crackling energy lines
            if pulse >= 2:
                for i in range(3):
                    lx = cx - 6 + rand_range_int(0, 12)
                    ly = cy - 8 + rand_range_int(0, 16)
                    P(cell, int(lx), int(ly), (255, 200, 50, 200), 0, 0)

            cells.append(cell)
    return cells


def build_mecha_mutant(palette):
    """Half-flesh half-machine purple mutant."""
    cells = []
    s, b, a, d, e, oc = palette["skin"], palette["body"], palette["accent"], palette["dark"], palette["eye"], palette["outline"]
    metal = palette.get("metal", (120, 120, 140, 255))

    for row in range(4):
        for col in range(4):
            cell = new_cell()
            cx, cy = CELL // 2, CELL // 2
            bob = 0; leg_s = 0; arm_r = 0; flash = False; eye_glow = False

            if row == 0:
                bob = [0, 1][col % 2]; leg_s = [0, 1][col % 2]
            elif row == 1:
                bob = [0, 1, 0, -1][col]; leg_s = [-2, 2, -2, 2][col]
            elif row == 2:
                arm_r = [0, 4, 6, 6][col]; eye_glow = True
            elif row == 3:
                flash = True

            # Legs (mechanical left, organic right)
            # Left leg: metal
            rrect(cell, cx - 3, cy + 3 + bob, cx - 1, cy + 8 + bob - leg_s, metal, 0, 0)
            rrect(cell, cx - 3, cy + 8 + bob - leg_s, cx - 1, cy + 11 + bob + leg_s, metal, 0, 0)
            # Right leg: organic
            draw_leg(cell, cx, cy + 3, s, 0, 0, 1, -leg_s)

            # Body (half metal, half flesh)
            rrect(cell, cx - 3, cy - 4 + bob, cx, cy + 4 + bob, metal, 0, 0)
            rrect(cell, cx, cy - 4 + bob, cx + 3, cy + 4 + bob, b, 0, 0)
            # Seam line
            line(cell, cx, cy - 4 + bob, cx, cy + 4 + bob, a, 0, 0)
            # Wires
            line(cell, cx - 1, cy - 2 + bob, cx - 2, cy + bob, a, 0, 0)
            line(cell, cx - 1, cy + bob, cx - 2, cy + 2 + bob, a, 0, 0)

            # Head (cybernetic)
            hc = cx; hy = cy - 7 + bob
            draw_head(cell, hc, hy, metal, oc, 0, 0, 5, 6)
            # Flesh patch on face
            rrect(cell, hc, hy - 1, hc + 2, hy + 3, s, 0, 0)
            # Eye (glowing red/orange)
            ec = (255, 80, 30, 255) if eye_glow else e
            if flash: ec = (255, 255, 255, 255)
            draw_eye(cell, hc + 1, hy, ec, 0, 0, 1)
            # Antenna
            line(cell, hc - 1, hy - 3, hc - 2, hy - 5, metal, 0, 0)
            P(cell, hc - 2, hy - 5, a, 0, 0)

            # Arms (left mechanical claw, right organic)
            # Left: metal arm with claw
            ar_x = cx - 3 - arm_r
            line(cell, cx - 3, cy - 2 + bob, ar_x, cy - 3 - arm_r//2 + bob, metal, 0, 0)
            fdisc(cell, ar_x, cy - 3 - arm_r//2 + bob, 2, metal, 0, 0)
            # Right: organic
            draw_arm(cell, cx, cy + bob, s, 0, 0, 1, 0, 0)

            cells.append(cell)
    return cells


def build_bio_shield_zombie(palette):
    """Green zombie with large organic shield arm."""
    cells = []
    s, b, a, d, e, oc = palette["skin"], palette["body"], palette["accent"], palette["dark"], palette["eye"], palette["outline"]
    shield_c = palette.get("shield", (40, 120, 40, 255))

    for row in range(4):
        for col in range(4):
            cell = new_cell()
            cx, cy = CELL // 2, CELL // 2
            bob = 0; leg_s = 0; shield_up = False; flash = False

            if row == 0:
                bob = [0, 1][col % 2]; leg_s = [0, 1][col % 2]
            elif row == 1:
                bob = [0, 1, 0, -1][col]; leg_s = [-2, 2, -2, 2][col]
            elif row == 2:
                shield_up = True
            elif row == 3:
                flash = True; bob = -1

            # Legs
            ly = cy + 4 + bob
            draw_leg(cell, cx, ly, d, 0, 0, -1, leg_s)
            draw_leg(cell, cx, ly, d, 0, 0, 1, -leg_s)

            # Body
            draw_body(cell, cx, cy + bob, b, oc, 0, 0, 6, 8)

            # Shield arm (left side, large)
            sx = cx - 4
            sy = cy - 2 + bob
            if shield_up:
                # Raised shield
                fell(cell, sx, sy - 2, 5, 6, shield_c, 0, 0)
                # Shield outline
                outline_ellipse(cell, sx, sy - 2, 5, 6, oc, 0, 0)
                # Vine details
                line(cell, sx - 3, sy - 4, sx + 3, sy, a, 0, 0)
            else:
                # Shield at rest
                fell(cell, sx, sy, 4, 5, shield_c, 0, 0)
                outline_ellipse(cell, sx, sy, 4, 5, oc, 0, 0)

            # Head
            hc = cx + 1; hy = cy - 6 + bob
            draw_head(cell, hc, hy, s, oc, 0, 0, 5, 6)
            if not flash:
                draw_eye(cell, hc - 2, hy - 1, e, 0, 0, 2)
                draw_eye(cell, hc + 1, hy - 1, e, 0, 0, 2)
            else:
                draw_eye(cell, hc - 2, hy - 1, (255, 255, 255, 255), 0, 0, 2)
                draw_eye(cell, hc + 1, hy - 1, (255, 255, 255, 255), 0, 0, 2)
            draw_zombie_mouth(cell, hc, hy, 0, 0)

            # Right arm (normal)
            draw_arm(cell, cx, cy + bob, s, 0, 0, 1, 0, 0)

            # Plant growth on body
            if row >= 2:
                P(cell, cx + 2, cy - 2 + bob, a, 0, 0)
                P(cell, cx + 3, cy - 1 + bob, a, 0, 0)

            cells.append(cell)
    return cells


def build_nanomite_zombie(palette):
    """Magenta swarm of nanobots - non-humanoid, cluster shape."""
    cells = []
    s, b, a, d, e, oc = palette["skin"], palette["body"], palette["accent"], palette["dark"], palette["eye"], palette["outline"]

    # Base cluster shape (relative positions from center)
    base_dots = [
        (-3,-2),( -2,-3),( -1,-2),( 0,-3),( 1,-2),( 2,-3),( 3,-2),
        (-4, 0),( -3, 1),( -2, 0),( -1, 1),( 0, 0),( 1, 1),( 2, 0),( 3, 1),( 4, 0),
        (-3, 3),( -2, 4),( -1, 3),( 0, 4),( 1, 3),( 2, 4),( 3, 3),
        (-1,-1),( 0,-1),( 1,-1),( -1, 2),( 0, 2),( 1, 2),
        (-5, 1),( 5, 1),( -4, 2),( 4, 2),
    ]

    for row in range(4):
        for col in range(4):
            cell = new_cell()
            cx, cy = CELL // 2, CELL // 2
            flash = False
            scatter = 0
            glow = 0

            if row == 0:
                scatter = [0, 1][col % 2]
            elif row == 1:
                scatter = col  # 0,1,2,3
            elif row == 2:
                scatter = [0, 2, 3, 3][col]; glow = min(col, 2)
            elif row == 3:
                flash = True; scatter = 2

            # Draw nanobot cluster
            import math
            for (dx, dy) in base_dots:
                # Jitter based on animation
                jx = dx + int(math.sin(col * 1.5 + dx) * scatter * 0.8)
                jy = dy + int(math.cos(col * 1.2 + dy) * scatter * 0.8)
                # Each bot is a small square
                bc = s if not flash else (255, 255, 255, 255)
                P(cell, cx + jx, cy + jy, bc, 0, 0)
                P(cell, cx + jx + 1, cy + jy, bc, 0, 0)
                P(cell, cx + jx, cy + jy + 1, d, 0, 0)
                P(cell, cx + jx + 1, cy + jy + 1, d, 0, 0)

            # Core (brighter center)
            cc = a if not flash else (255, 255, 255, 255)
            if glow > 0:
                fell(cell, cx, cy, 2 + glow, 2 + glow, cc, 0, 0)
            else:
                fdisc(cell, cx, cy, 2, cc, 0, 0)

            # Eye(s) - multiple small eyes in the cluster
            if not flash:
                P(cell, cx - 1, cy - 2, e, 0, 0)
                P(cell, cx + 2, cy - 2, e, 0, 0)
            else:
                P(cell, cx - 1, cy - 2, (255, 255, 255, 255), 0, 0)
                P(cell, cx + 2, cy - 2, (255, 255, 255, 255), 0, 0)

            # Glitch artifacts
            if scatter >= 2:
                for _ in range(scatter):
                    gx = cx + rand_range_int(-6, 6)
                    gy = cy + rand_range_int(-5, 5)
                    P(cell, gx, gy, (255, 0, 255, 150), 0, 0)

            cells.append(cell)
    return cells


def build_hologram_zombie(palette):
    """Cyan translucent holographic projection."""
    cells = []
    s, b, a, d, e, oc = palette["skin"], palette["body"], palette["accent"], palette["dark"], palette["eye"], palette["outline"]
    # Semi-transparent versions
    hs = (s[0], s[1], s[2], 140)  # semi-transparent skin
    hb = (b[0], b[1], b[2], 140)
    ho = (oc[0], oc[1], oc[2], 160)

    for row in range(4):
        for col in range(4):
            cell = new_cell()
            cx, cy = CELL // 2, CELL // 2
            bob = 0; leg_s = 0; flicker = False; arm_r = 0

            if row == 0:
                bob = [0, 1][col % 2]; leg_s = [0, 1][col % 2]
                flicker = (col % 3 == 0)
            elif row == 1:
                bob = [0, 1, 0, -1][col]; leg_s = [-2, 2, -2, 2][col]
                flicker = (col == 3)
            elif row == 2:
                arm_r = [0, 3, 5, 5][col]
            elif row == 3:
                bob = -1; flicker = True

            alpha_mod = 0.4 if flicker else 1.0

            def ta(c, mod=alpha_mod):
                return (c[0], c[1], c[2], int(c[3] * mod))

            # Legs (translucent)
            draw_leg(cell, cx, cy + 4 + bob, ta(d), 0, 0, -1, leg_s)
            draw_leg(cell, cx, cy + 4 + bob, ta(d), 0, 0, 1, -leg_s)

            # Body
            draw_body(cell, cx, cy + bob, ta(b), ta(ho), 0, 0, 6, 8)

            # Head
            hc = cx; hy = cy - 6 + bob
            draw_head(cell, hc, hy, ta(hs), ta(ho), 0, 0, 5, 6)
            draw_eye(cell, hc - 2, hy - 1, ta(e), 0, 0, 2)
            draw_eye(cell, hc + 1, hy - 1, ta(e), 0, 0, 2)
            draw_zombie_mouth(cell, hc, hy, 0, 0)

            # Arms
            draw_arm(cell, cx, cy + bob, ta(hs), 0, 0, -1, 0, arm_r)
            draw_arm(cell, cx, cy + bob, ta(hs), 0, 0, 1, 0, 0)

            # Scanlines (horizontal dashed lines for hologram effect)
            for scan_y in range(0, CELL, 3):
                for scan_x in range(CELL):
                    existing = cell.getpixel((scan_x, scan_y))
                    if existing[3] > 0:
                        cell.putpixel((scan_x, scan_y), (existing[0], existing[1], existing[2], int(existing[3] * 0.7)))

            # Projection base (faint circle on ground)
            if not flicker:
                outline_ellipse(cell, cx, cy + 11, 6, 2, ta(a), 0, 0)

            cells.append(cell)
    return cells


def build_elite_zombie(palette, elite_type="bio_tyrant"):
    """Elite zombie - larger, more detailed, intimidating."""
    cells = []
    s, b, a, d, e, oc = palette["skin"], palette["body"], palette["accent"], palette["dark"], palette["eye"], palette["outline"]
    extra = palette.get("extra", a)

    is_tyrant = (elite_type == "bio_tyrant")
    is_mecha = (elite_type == "mecha_soldier")
    is_fusion = (elite_type == "gene_fusion")

    bw = 8 if is_tyrant else 7
    bh = 10 if is_tyrant else 9
    hw = 6 if is_tyrant else 6
    hh = 7 if is_tyrant else 6

    for row in range(4):
        for col in range(4):
            cell = new_cell()
            cx, cy = CELL // 2, CELL // 2
            bob = 0; leg_s = 0; arm_r = 0; flash = False; extra_limb = False

            if row == 0:
                bob = [0, 1][col % 2]; leg_s = [0, 1][col % 2]
            elif row == 1:
                bob = [0, 1, 0, -1][col]; leg_s = [-2, 2, -2, 2][col]
            elif row == 2:
                arm_r = [0, 4, 6, 6][col]; extra_limb = col >= 1
            elif row == 3:
                flash = True; bob = -1

            # Legs (thicker for elites)
            draw_leg(cell, cx, cy + bh//2 + bob, d, 0, 0, -1, leg_s)
            draw_leg(cell, cx, cy + bh//2 + bob, d, 0, 0, 1, -leg_s)

            # Body (larger)
            draw_body(cell, cx, cy + bob, b, oc, 0, 0, bw, bh)

            if is_mecha:
                # Armor plating
                rrect(cell, cx - bw//2, cy - bh//3 + bob, cx - bw//4, cy + bh//6 + bob, a, 0, 0)
                rrect(cell, cx + bw//4, cy - bh//3 + bob, cx + bw//2, cy + bh//6 + bob, a, 0, 0)
                # Helmet visor
                rrect(cell, cx - hw//2, cy - bh//2 - hh//2 - 2 + bob, cx + hw//2, cy - bh//2 - hh//2 + 1 + bob, extra, 0, 0)
            elif is_tyrant:
                # Extra muscle definition
                rrect(cell, cx - bw//2 - 1, cy - 2 + bob, cx - bw//2, cy + 2 + bob, a, 0, 0)
                rrect(cell, cx + bw//2, cy - 2 + bob, cx + bw//2 + 1, cy + 2 + bob, a, 0, 0)
                # Veins
                line(cell, cx - 2, cy - 2 + bob, cx - 2, cy + 2 + bob, extra, 0, 0)
            elif is_fusion:
                # Chaotic extra growths
                for i in range(3):
                    gx = cx - 3 + i * 3
                    gy = cy - 3 + bob + (i % 2) * 2
                    fdisc(cell, gx, gy, 1, extra, 0, 0)

            # Head
            hc = cx; hy = cy - bh//2 - hh//2 - 2 + bob
            head_c = a if is_mecha else s
            draw_head(cell, hc, hy, head_c, oc, 0, 0, hw, hh)

            if is_fusion:
                # Second smaller head
                draw_head(cell, hc + 4, hy - 1, s, oc, 0, 0, 4, 5)

            # Eyes
            ey = hy - 1
            ec = e if not flash else (255, 255, 255, 255)
            if is_mecha:
                # Visor slit (glowing eye strip)
                rrect(cell, hc - 2, ey, hc + 2, ey + 1, ec, 0, 0)
            else:
                draw_eye(cell, hc - 2, ey, ec, 0, 0, 2)
                draw_eye(cell, hc + 1, ey, ec, 0, 0, 2)
                if is_fusion:
                    draw_eye(cell, hc + 3, ey - 1, ec, 0, 0, 1)
                    draw_eye(cell, hc + 5, ey - 1, ec, 0, 0, 1)

            # Mouth
            if is_tyrant:
                rrect(cell, hc - 1, hy + 2, hc + 1, hy + 4, d, 0, 0)
                # Fangs
                P(cell, hc - 1, hy + 2, (220, 220, 200, 255), 0, 0)
                P(cell, hc + 1, hy + 2, (220, 220, 200, 255), 0, 0)
                P(cell, hc, hy + 3, (220, 220, 200, 255), 0, 0)
            else:
                draw_zombie_mouth(cell, hc, hy, 0, 0)

            # Arms
            draw_arm(cell, cx, cy + bob, head_c if is_mecha else s, 0, 0, -1, -1, arm_r)
            draw_arm(cell, cx, cy + bob, head_c if is_mecha else s, 0, 0, 1, 1, 0)

            if extra_limb and is_tyrant:
                # Extra tyrant arm
                draw_arm(cell, cx, cy - 2 + bob, s, 0, 0, -1, -2, arm_r - 1)

            cells.append(cell)
    return cells


def build_boss_zombie(palette, boss_type="king"):
    """Boss zombie - larger sprite, more detail, menacing."""
    cells = []
    s, b, a, d, e, oc = palette["skin"], palette["body"], palette["accent"], palette["dark"], palette["eye"], palette["outline"]
    extra = palette.get("extra", a)

    is_king = (boss_type == "king")
    is_titan = (boss_type == "titan")
    is_nano = (boss_type == "nano")
    is_alpha = (boss_type == "alpha")

    # Bosses are drawn slightly larger (use more pixels)
    for row in range(4):
        for col in range(4):
            cell = new_cell()
            cx, cy = CELL // 2, CELL // 2 + 1  # slightly lower center
            bob = 0; leg_s = 0; arm_r = 0; flash = False; special = 0

            if row == 0:
                bob = [0, 1][col % 2]; leg_s = [0, 1][col % 2]
            elif row == 1:
                bob = [0, 2, 0, -2][col]; leg_s = [-2, 2, -2, 2][col]
            elif row == 2:
                arm_r = [0, 5, 7, 7][col]; special = col
            elif row == 3:
                flash = True; bob = -2

            if is_king:
                _draw_boss_king(cell, cx, cy, bob, leg_s, arm_r, flash, special, s, b, a, d, e, oc, extra)
            elif is_titan:
                _draw_boss_titan(cell, cx, cy, bob, leg_s, arm_r, flash, special, s, b, a, d, e, oc, extra)
            elif is_nano:
                _draw_boss_nano(cell, cx, cy, bob, leg_s, arm_r, flash, special, s, b, a, d, e, oc, extra)
            elif is_alpha:
                _draw_boss_alpha(cell, cx, cy, bob, leg_s, arm_r, flash, special, s, b, a, d, e, oc, extra)

            cells.append(cell)
    return cells


def _draw_boss_king(cell, cx, cy, bob, leg_s, arm_r, flash, special, s, b, a, d, e, oc, extra):
    """Zombie King - crowned, regal, large."""
    # Big body
    draw_body(cell, cx, cy + bob, s, oc, 0, 0, 9, 10)
    # Crown / bone spikes on head
    for i in range(-3, 4, 2):
        line(cell, cx + i, cy - 9 + bob, cx + i, cy - 12 + bob, extra, 0, 0)
        P(cell, cx + i, cy - 12 + bob, a, 0, 0)
    # Cape / royal collar
    rrect(cell, cx - 4, cy - 5 + bob, cx + 4, cy - 3 + bob, a, 0, 0)
    # Head (large)
    hc = cx; hy = cy - 7 + bob
    draw_head(cell, hc, hy, s, oc, 0, 0, 7, 8)
    # Crown base on head
    rrect(cell, hc - 3, hy - 2, hc + 3, hy, extra, 0, 0)
    # Eyes (menacing)
    ec = e if not flash else (255, 255, 255, 255)
    draw_eye(cell, hc - 2, hy, ec, 0, 0, 2)
    draw_eye(cell, hc + 1, hy, ec, 0, 0, 2)
    # Angry brows
    line(cell, hc - 3, hy - 2, hc - 1, hy - 1, d, 0, 0)
    line(cell, hc + 1, hy - 1, hc + 3, hy - 2, d, 0, 0)
    # Mouth (wide, roaring when attacking)
    if special >= 1:
        rrect(cell, hc - 2, hy + 3, hc + 2, hy + 5, d, 0, 0)
        # Teeth
        for i in range(-1, 2):
            P(cell, hc + i, hy + 3, (220, 220, 200, 255), 0, 0)
            P(cell, hc + i, hy + 5, (220, 220, 200, 255), 0, 0)
    else:
        draw_zombie_mouth(cell, hc, hy, 0, 0)
    # Legs (thick)
    draw_leg(cell, cx - 1, cy + 5 + bob, d, 0, 0, -1, leg_s)
    draw_leg(cell, cx + 1, cy + 5 + bob, d, 0, 0, 1, -leg_s)
    # Arms (large, reaching)
    draw_arm(cell, cx, cy + bob, s, 0, 0, -1, -2, arm_r)
    draw_arm(cell, cx, cy + bob, s, 0, 0, 1, 2, arm_r // 2)


def _draw_boss_titan(cell, cx, cy, bob, leg_s, arm_r, flash, special, s, b, a, d, e, oc, extra):
    """Bio Titan - massive, armored, club-arm."""
    # Very wide body
    draw_body(cell, cx, cy + bob, b, oc, 0, 0, 10, 11)
    # Armor plates
    rrect(cell, cx - 5, cy - 4 + bob, cx - 2, cy + 2 + bob, a, 0, 0)
    rrect(cell, cx + 2, cy - 4 + bob, cx + 5, cy + 2 + bob, a, 0, 0)
    # Shoulder pads
    fell(cell, cx - 5, cy - 5 + bob, 3, 2, extra, 0, 0)
    fell(cell, cx + 5, cy - 5 + bob, 3, 2, extra, 0, 0)
    # Head (small relative to body)
    hc = cx; hy = cy - 8 + bob
    draw_head(cell, hc, hy, s, oc, 0, 0, 6, 7)
    # Helmet
    rrect(cell, hc - 3, hy - 2, hc + 3, hy + 1, extra, 0, 0)
    # One glowing eye (cyclops-ish)
    ec = e if not flash else (255, 255, 255, 255)
    fdisc(cell, hc, hy, 2, ec, 0, 0)
    # Mouth (grill/visor)
    rrect(cell, hc - 2, hy + 3, hc + 2, hy + 4, d, 0, 0)
    # Thick legs
    rrect(cell, cx - 3, cy + 5 + bob, cx - 1, cy + 11 + bob - leg_s, d, 0, 0)
    rrect(cell, cx + 1, cy + 5 + bob, cx + 3, cy + 11 + bob - leg_s, d, 0, 0)
    # Club/weapon arm (right)
    wx = cx + 4 + arm_r
    wy = cy - 2 + bob
    line(cell, cx + 4, cy + bob, wx, wy, extra, 0, 0)
    # Club head
    rrect(cell, wx - 1, wy - 3, wx + 3, wy + 1, a, 0, 0)
    # Normal left arm
    draw_arm(cell, cx, cy + bob, s, 0, 0, -1, 1, 0)


def _draw_boss_nano(cell, cx, cy, bob, leg_s, arm_r, flash, special, s, b, a, d, e, oc, extra):
    """Nano Core - central core with orbiting particles."""
    # Central core body
    fell(cell, cx, cy + bob, 6, 7, s, 0, 0)
    outline_ellipse(cell, cx, cy + bob, 6, 7, oc, 0, 0)
    # Inner bright core
    cc = a if not flash else (255, 255, 255, 255)
    intensity = 2 + special
    fell(cell, cx, cy + bob, 2 + intensity, 2 + intensity, cc, 0, 0)
    # Orbiting particles
    import math
    n_particles = 8
    for i in range(n_particles):
        angle = math.radians((col_offset := special * 45) + i * (360 // n_particles) + (row_time := int(bob * 20)))
        pr = 8 + int(math.sin(angle * 2) * 2)
        px = cx + int(pr * math.cos(angle))
        py = cy + bob + int(pr * math.sin(angle) * 0.6)
        pc = extra if not flash else (255, 255, 255, 255)
        fdisc(cell, px, py, 1 if i % 2 == 0 else 2, pc, 0, 0)
    # Floating leg-like stabilizers
    rrect(cell, cx - 4, cy + 6 + bob, cx - 2, cy + 10 + bob - leg_s, d, 0, 0)
    rrect(cell, cx + 2, cy + 6 + bob, cx + 4, cy + 10 + bob - leg_s, d, 0, 0)
    # Eye/core in center
    if not flash:
        fdisc(cell, cx, cy - 1 + bob, 1, e, 0, 0)
    else:
        fdisc(cell, cx, cy - 1 + bob, 2, (255, 255, 255, 255), 0, 0)
    # Energy tendrils
    if special >= 1:
        for i in range(3):
            tx = cx + rand_range_int(-5, 5)
            ty = cy + bob + rand_range_int(-5, 8)
            line(cell, cx, cy + bob, tx, ty, (a[0], a[1], a[2], 150), 0, 0)


def _draw_boss_alpha(cell, cx, cy, bob, leg_s, arm_r, flash, special, s, b, a, d, e, oc, extra):
    """Experiment Alpha - horrific multi-form abomination."""
    # Shifting body mass
    body_c = s if (special % 2 == 0) else b
    draw_body(cell, cx, cy + bob, body_c, oc, 0, 0, 9, 10)
    # Exposed musculature / tendons
    for i in range(4):
        sx = cx - 3 + i * 2
        line(cell, sx, cy - 4 + bob, sx + (1 if i % 2 else -1), cy + 4 + bob, extra, 0, 0)
    # Multiple heads / faces
    # Main head (center)
    hc = cx; hy = cy - 7 + bob
    draw_head(cell, hc, hy, s, oc, 0, 0, 6, 7)
    ec = e if not flash else (255, 255, 255, 255)
    draw_eye(cell, hc - 2, hy, ec, 0, 0, 2)
    draw_eye(cell, hc + 1, hy, ec, 0, 0, 2)
    # Secondary head (left shoulder)
    hc2 = cx - 5; hy2 = cy - 4 + bob
    draw_head(cell, hc2, hy2, b, oc, 0, 0, 5, 6)
    draw_eye(cell, hc2 - 1, hy2, ec, 0, 0, 1)
    draw_eye(cell, hc2 + 1, hy2, ec, 0, 0, 1)
    # Tertiary head (right, lower, emerging)
    if special >= 1:
        hc3 = cx + 4; hy3 = cy - 2 + bob
        draw_head(cell, hc3, hy3, d, oc, 0, 0, 4, 5)
        draw_eye(cell, hc3, hy3, (255, 0, 0, 255), 0, 0, 1)
    # Tentacle arms
    for i in range(3):
        ax = cx + ( -4 + i * 4 )
        ay = cy - 2 + bob
        ex = ax + ( -3 + arm_r ) * (1 if i != 1 else -1)
        ey = ay - 2 - i + special
        line(cell, ax, ay, ex, ey, s if i % 2 == 0 else b, 0, 0)
        fdisc(cell, ex, ey, 1 if i < 2 else 2, a, 0, 0)
    # Legs (asymmetric)
    draw_leg(cell, cx - 1, cy + 5 + bob, d, 0, 0, -1, leg_s)
    # Right leg: thicker, different color (mutation)
    rrect(cell, cx + 1, cy + 5 + bob, cx + 3, cy + 10 + bob - leg_s, extra, 0, 0)
    # Pulsing core in chest
    core_r = 2 + special
    fell(cell, cx, cy - 1 + bob, core_r, core_r, a if not flash else (255, 255, 255, 255), 0, 0)


# ---------- utility ----------
def rand_range_int(lo, hi):
    return random.randint(lo, hi - 1)


# ---------- sheet assembly ----------
def make_sheet(cells):
    """Pack 16 cells into a 4x4 spritesheet image, then upscale x3 NEAREST."""
    sheet = Image.new("RGBA", (CELL * 4, CELL * 4), (0, 0, 0, 0))
    for idx, cell in enumerate(cells):
        sx = (idx % 4) * CELL
        sy = (idx // 4) * CELL
        sheet.paste(cell, (sx, sy))
    # Upscale
    w, h = sheet.size
    big = sheet.resize((w * SCALE, h * SCALE), Image.NEAREST)
    return big


# ---------- palettes ----------
PALETTES = {
    "normal": {
        "skin": (140, 160, 100, 255),      # greenish-gray zombie skin
        "body": (90, 100, 70, 255),         # tattered clothes
        "accent": (160, 100, 60, 255),      # brown accents
        "dark": (60, 55, 50, 255),          # dark limbs/mouth
        "eye": (220, 220, 150, 255),        # yellowish glowing eye
        "outline": (18, 18, 24, 255),
    },
    "fast": {
        "skin": (180, 170, 110, 255),       # pale yellowish
        "body": (120, 110, 80, 255),        # ragged darker
        "accent": (200, 180, 80, 255),      # bright yellow
        "dark": (80, 70, 50, 255),
        "eye": (255, 220, 80, 255),         # bright orange eye
        "outline": (18, 18, 24, 255),
    },
    "tank": {
        "skin": (130, 130, 130, 255),       # gray skin
        "body": (80, 80, 90, 255),          # dark armor
        "accent": (140, 140, 150, 255),     # metal plates
        "dark": (50, 50, 55, 255),
        "eye": (200, 60, 60, 255),          # red eyes
        "outline": (18, 18, 24, 255),
    },
    "self_destruct": {
        "skin": (180, 120, 80, 255),        # orange-brown
        "body": (140, 90, 50, 255),
        "accent": (255, 140, 30, 255),      # bright orange glow
        "dark": (100, 60, 30, 255),
        "eye": (255, 200, 50, 255),         # glowing orange
        "outline": (18, 18, 24, 255),
    },
    "mecha_mutant": {
        "skin": (160, 120, 160, 255),       # purplish skin
        "body": (120, 90, 130, 255),
        "accent": (200, 100, 255, 255),     # purple energy
        "dark": (80, 60, 90, 255),
        "eye": (255, 80, 80, 255),          # red cyber-eye
        "outline": (18, 18, 24, 255),
        "metal": (130, 135, 150, 255),      # metal parts
    },
    "bio_shield": {
        "skin": (100, 140, 90, 255),        # greenish
        "body": (70, 110, 60, 255),
        "accent": (80, 180, 60, 255),       # bright green
        "dark": (50, 80, 40, 255),
        "eye": (150, 255, 130, 255),        # green glow
        "outline": (18, 18, 24, 255),
        "shield": (40, 140, 40, 255),       # shield color
    },
    "nanomite": {
        "skin": (180, 60, 180, 255),        # magenta
        "body": (140, 40, 140, 255),
        "accent": (255, 100, 255, 255),     # bright magenta
        "dark": (100, 30, 100, 255),
        "eye": (255, 200, 255, 255),        # pink-white
        "outline": (18, 18, 24, 255),
    },
    "hologram": {
        "skin": (100, 220, 220, 255),       # cyan
        "body": (70, 180, 180, 255),
        "accent": (150, 255, 255, 255),     # bright cyan
        "dark": (50, 140, 140, 255),
        "eye": (200, 255, 255, 255),        # bright cyan
        "outline": (18, 18, 24, 255),
    },
    "elite_bio_tyrant": {
        "skin": (180, 60, 50, 255),         # dark red
        "body": (140, 40, 35, 255),
        "accent": (220, 80, 60, 255),       # red vein
        "dark": (90, 25, 20, 255),
        "eye": (255, 200, 80, 255),         # orange-yellow
        "outline": (18, 18, 24, 255),
        "extra": (200, 50, 50, 255),        # vein/muscle red
    },
    "elite_mecha_soldier": {
        "skin": (100, 120, 180, 255),       # blue-gray
        "body": (70, 90, 150, 255),         # blue armor
        "accent": (130, 160, 220, 255),     # light blue
        "dark": (50, 60, 100, 255),
        "eye": (100, 200, 255, 255),        # cyan visor
        "outline": (18, 18, 24, 255),
        "extra": (80, 100, 160, 255),       # dark metal
    },
    "elite_gene_fusion": {
        "skin": (200, 180, 60, 255),        # gold
        "body": (170, 150, 40, 255),
        "accent": (255, 230, 100, 255),     # bright gold
        "dark": (130, 110, 20, 255),
        "eye": (255, 255, 150, 255),        # bright yellow
        "outline": (18, 18, 24, 255),
        "extra": (255, 200, 50, 255),       # orange growth
    },
    "boss_king": {
        "skin": (180, 60, 60, 255),         # red
        "body": (140, 45, 45, 255),
        "accent": (220, 180, 60, 255),      # gold crown
        "dark": (100, 30, 30, 255),
        "eye": (255, 220, 80, 255),         # orange
        "outline": (18, 18, 24, 255),
        "extra": (200, 160, 40, 255),       # gold spikes
    },
    "boss_titan": {
        "skin": (120, 100, 70, 255),        # brown-green
        "body": (90, 75, 50, 255),
        "accent": (160, 140, 90, 255),      # tan armor
        "dark": (60, 50, 35, 255),
        "eye": (255, 180, 50, 255),         # orange
        "outline": (18, 18, 24, 255),
        "extra": (140, 120, 70, 255),       # metal
    },
    "boss_nano": {
        "skin": (140, 80, 180, 255),        # purple
        "body": (110, 60, 150, 255),
        "accent": (180, 120, 255, 255),     # bright purple
        "dark": (80, 40, 110, 255),
        "eye": (220, 180, 255, 255),        # lavender
        "outline": (18, 18, 24, 255),
        "extra": (200, 100, 255, 255),      # particle color
    },
    "boss_alpha": {
        "skin": (180, 80, 120, 255),        # reddish-pink
        "body": (140, 60, 90, 255),
        "accent": (255, 100, 150, 255),     # hot pink
        "dark": (100, 40, 70, 255),
        "eye": (255, 255, 100, 255),        # yellow (multiple)
        "outline": (18, 18, 24, 255),
        "extra": (255, 150, 80, 255),       # orange tendon
    },
}

# ---------- mapping: type name -> (builder_fn, palette_key, kwargs) ----------
ENEMY_DEFS = [
    ("zombie_normal", "normal", {}, build_humanoid_zombie),
    ("zombie_fast", "fast", {"is_fast": True}, build_humanoid_zombie),
    ("zombie_tank", "tank", {"is_tank": True}, build_humanoid_zombie),
    ("zombie_self", "self_destruct", {}, build_self_destruct_zombie),
    ("zombie_mecha_mutant", "mecha_mutant", {}, build_mecha_mutant),
    ("zombie_bio_shield", "bio_shield", {}, build_bio_shield_zombie),
    ("zombie_nanomite", "nanomite", {}, build_nanomite_zombie),
    ("zombie_hologram", "hologram", {}, build_hologram_zombie),
    ("zombie_elite_bio_tyrant", "elite_bio_tyrant", {"elite_type": "bio_tyrant"}, build_elite_zombie),
    ("zombie_elite_mecha_soldier", "elite_mecha_soldier", {"elite_type": "mecha_soldier"}, build_elite_zombie),
    ("zombie_elite_gene_fusion", "elite_gene_fusion", {"elite_type": "gene_fusion"}, build_elite_zombie),
    ("boss_king", "boss_king", {"boss_type": "king"}, build_boss_zombie),
    ("boss_titan", "boss_titan", {"boss_type": "titan"}, build_boss_zombie),
    ("boss_nano", "boss_nano", {"boss_type": "nano"}, build_boss_zombie),
    ("boss_alpha", "boss_alpha", {"boss_type": "alpha"}, build_boss_zombie),
]


def main():
    random.seed(42)
    generated = []

    for filename, pal_key, kw, builder in ENEMY_DEFS:
        palette = PALETTES[pal_key]
        cells = builder(palette, **kw)
        sheet = make_sheet(cells)
        out_path = os.path.join(OUT, f"{filename}.png")
        sheet.save(out_path)
        print(f"  {out_path}  ({sheet.size[0]}x{sheet.size[1]})")
        generated.append((filename, sheet))

    # Gallery: all enemies in a grid
    n = len(generated)
    cols = 5
    rows = (n + cols - 1) // cols
    thumb_w, thumb_h = 96, 96  # thumbnail size per enemy (from 288 -> 96 = /3)
    gallery = Image.new("RGBA", (cols * thumb_w + (cols - 1) * 8,
                                rows * thumb_h + (rows - 1) * 8 + 40), (20, 18, 28, 255))
    # Title area (skip, just use space)
    for idx, (fname, sheet) in enumerate(generated):
        gx = (idx % cols) * (thumb_w + 8) + 4
        gy = (idx // cols) * (thumb_h + 8) + 36
        # Resize a single frame (idle frame 0) as thumbnail
        frame = sheet.crop((0, 0, CELL * SCALE, CELL * SCALE))
        thumb = frame.resize((thumb_w, thumb_h), Image.NEAREST)
        gallery.paste(thumb, (gx, gy))
    gallery_path = os.path.join(OUT, "_enemies_gallery.png")
    gallery.save(gallery_path)
    print(f"  {gallery_path}  ({gallery.size[0]}x{gallery.size[1]})")
    print("Done.")


if __name__ == "__main__":
    main()
