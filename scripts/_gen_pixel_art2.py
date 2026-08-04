"""Generate the expanded pixel-art set for mini_zambie.

Outputs into assets/pixel/ (same folder the runtime PixelLoader reads from):
  - 5 themed area floor tiles + 1 boss floor (32x32, tileable)
  - 3 environment props: building (indestructible), car & crate (destructible)
  - 11 weapon-category icons (drawn pointing RIGHT so they can be rotated)
  - 8 upgrade-kind icons
  - 1 menu background (1280x720, blocky)
  - 1 upgrade card background (220x96, pixel frame)

All sprites are drawn at a low base resolution and scaled with NEAREST so the
result stays crisp pixel art. Runtime loads them via CanvasTexture (nearest).
"""
import os
from PIL import Image

OUT = "D:/MyCode/github/mini_zambie/assets/pixel"
os.makedirs(OUT, exist_ok=True)


# ---------- low-level pixel helpers ----------
def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(img, x, y, c):
    x, y = int(x), int(y)
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def fill(img, x0, y0, x1, y1, c):
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            put(img, x, y, c)


def disc(img, cx, cy, r, c):
    for y in range(int(cy - r), int(cy + r) + 1):
        for x in range(int(cx - r), int(cx + r) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                put(img, x, y, c)


def line(img, x0, y0, x1, y1, c):
    x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        put(img, x0, y0, c)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def outline(img, col):
    src = img.copy()
    for y in range(src.height):
        for x in range(src.width):
            if src.getpixel((x, y))[3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < src.width and 0 <= ny < src.height:
                        if src.getpixel((nx, ny))[3] > 0:
                            put(img, x, y, col)
                            break


def save(img, name, scale=1):
    if scale > 1:
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    img.save(os.path.join(OUT, name))
    print("wrote", name, img.size)


# ---------- area floor tiles (32x32, tileable) ----------
def floor_street():
    img = new(32, 32)
    fill(img, 0, 0, 31, 31, (38, 38, 46, 255))
    for y in range(0, 32, 8):
        for x in range(2, 8, 5):
            put(img, x, y, (214, 202, 84, 255))
    for y in range(20, 24):
        for x in range(20, 24):
            put(img, x, y, (58, 58, 66, 255))
    # subtle asphalt speckle
    for (x, y) in [(5, 12), (14, 27), (27, 6), (9, 22)]:
        put(img, x, y, (46, 46, 54, 255))
    save(img, "floor_street.png")


def floor_supermarket():
    img = new(32, 32)
    fill(img, 0, 0, 31, 31, (122, 110, 88, 255))
    for y in range(0, 32, 16):
        for x in range(0, 32, 16):
            fill(img, x + 1, y + 1, x + 14, y + 14, (86, 74, 54, 255))
            fill(img, x + 3, y + 3, x + 12, y + 6, (150, 132, 96, 255))
    save(img, "floor_supermarket.png")


def floor_hotel():
    img = new(32, 32)
    fill(img, 0, 0, 31, 31, (92, 80, 98, 255))
    for y in range(0, 32, 8):
        for x in range(0, 32, 8):
            fill(img, x + 2, y + 2, x + 5, y + 5, (70, 60, 78, 255))
    save(img, "floor_hotel.png")


def floor_hospital():
    img = new(32, 32)
    fill(img, 0, 0, 31, 31, (202, 212, 212, 255))
    for x in range(0, 33, 16):
        for y in range(0, 33, 16):
            put(img, x, y, (168, 182, 182, 255))
            put(img, x + 16, y, (168, 182, 182, 255))
    save(img, "floor_hospital.png")


def floor_parking():
    img = new(32, 32)
    fill(img, 0, 0, 31, 31, (62, 62, 70, 255))
    for y in range(0, 32, 16):
        for x in range(0, 32, 16):
            fill(img, x + 1, y + 14, x + 14, y + 15, (206, 182, 48, 255))
    save(img, "floor_parking.png")


def floor_boss():
    img = new(32, 32)
    fill(img, 0, 0, 31, 31, (72, 22, 28, 255))
    for (x, y) in [(6, 6), (24, 8), (10, 22), (26, 24), (16, 16)]:
        put(img, x, y, (52, 14, 18, 255))
        put(img, x + 1, y, (52, 14, 18, 255))
    save(img, "floor_boss.png")


# ---------- environment props ----------
def building():
    img = new(64, 64)
    fill(img, 4, 4, 59, 59, (92, 92, 104, 255))
    fill(img, 4, 4, 59, 7, (112, 112, 126, 255))   # top edge
    # windows
    for gy in range(14, 56, 14):
        for gx in range(12, 52, 16):
            fill(img, gx, gy, gx + 8, gy + 8, (140, 162, 184, 255))
            fill(img, gx + 1, gy + 1, gx + 2, gy + 2, (180, 200, 220, 255))
    outline(img, (40, 40, 50, 255))
    save(img, "building.png")


def car():
    img = new(40, 40)
    # body
    fill(img, 6, 16, 34, 30, (186, 46, 46, 255))
    fill(img, 12, 10, 28, 18, (200, 58, 58, 255))  # cabin
    fill(img, 14, 12, 26, 16, (120, 178, 220, 255))  # window
    # wheels
    disc(img, 13, 31, 4, (28, 28, 32, 255))
    disc(img, 27, 31, 4, (28, 28, 32, 255))
    disc(img, 13, 31, 1, (90, 90, 96, 255))
    disc(img, 27, 31, 1, (90, 90, 96, 255))
    # headlight
    fill(img, 33, 20, 35, 23, (240, 230, 120, 255))
    outline(img, (40, 16, 16, 255))
    save(img, "obstacle_car.png")


def crate():
    img = new(32, 32)
    fill(img, 4, 4, 27, 27, (150, 110, 60, 255))
    # planks
    fill(img, 4, 4, 27, 6, (120, 86, 44, 255))
    fill(img, 4, 24, 27, 27, (120, 86, 44, 255))
    fill(img, 4, 4, 6, 27, (120, 86, 44, 255))
    fill(img, 25, 4, 27, 27, (120, 86, 44, 255))
    # diagonal brace
    line(img, 6, 6, 25, 25, (120, 86, 44, 255))
    line(img, 25, 6, 6, 25, (120, 86, 44, 255))
    outline(img, (70, 50, 26, 255))
    save(img, "obstacle_crate.png")


# ---------- weapon icons (point RIGHT) ----------
def _gun_body(img, body, barrel, accent):
    fill(img, 8, 14, 26, 20, body)        # receiver
    fill(img, 22, 15, 31, 18, barrel)     # barrel to the right
    fill(img, 8, 20, 14, 26, body)        # grip
    fill(img, 9, 15, 25, 16, accent)      # top highlight
    outline(img, (20, 20, 24, 255))


def weapon_rifle():
    img = new(32, 32)
    _gun_body(img, (120, 122, 130, 255), (150, 152, 160, 255), (170, 172, 180, 255))
    fill(img, 24, 15, 31, 16, (90, 92, 100, 255))
    save(img, "weapon_rifle.png")


def weapon_heavy_ranged():
    img = new(32, 32)
    fill(img, 6, 12, 24, 22, (70, 72, 80, 255))     # big body
    fill(img, 22, 14, 31, 19, (96, 98, 106, 255))   # rocket tube
    fill(img, 23, 15, 30, 17, (40, 42, 48, 255))
    fill(img, 6, 22, 12, 28, (70, 72, 80, 255))     # grip
    outline(img, (20, 20, 24, 255))
    save(img, "weapon_heavy_ranged.png")


def weapon_blade():
    img = new(32, 32)
    # blade pointing right
    fill(img, 14, 14, 29, 17, (205, 212, 224, 255))
    fill(img, 14, 15, 28, 15, (235, 242, 252, 255))
    fill(img, 27, 13, 30, 18, (225, 232, 244, 255))  # tip
    fill(img, 8, 12, 14, 19, (120, 80, 40, 255))     # guard
    fill(img, 4, 14, 9, 17, (90, 60, 30, 255))       # handle
    outline(img, (40, 44, 54, 255))
    save(img, "weapon_blade.png")


def weapon_blunt():
    img = new(32, 32)
    disc(img, 20, 16, 7, (150, 152, 160, 255))       # head
    disc(img, 20, 16, 7, (150, 152, 160, 255))
    fill(img, 19, 9, 21, 23, (180, 182, 190, 255))
    fill(img, 4, 14, 18, 18, (110, 76, 40, 255))     # handle
    outline(img, (30, 30, 36, 255))
    save(img, "weapon_blunt.png")


def weapon_heavy_blunt():
    img = new(32, 32)
    fill(img, 12, 6, 27, 22, (120, 122, 130, 255))   # big hammer head
    fill(img, 13, 7, 26, 9, (160, 162, 170, 255))
    fill(img, 4, 14, 16, 18, (96, 66, 36, 255))      # handle
    outline(img, (24, 24, 30, 255))
    save(img, "weapon_heavy_blunt.png")


def weapon_laser():
    img = new(32, 32)
    _gun_body(img, (96, 100, 110, 255), (60, 200, 210, 255), (120, 220, 230, 255))
    fill(img, 26, 14, 31, 18, (60, 220, 230, 255))   # glowing emitter
    fill(img, 28, 15, 30, 17, (180, 255, 255, 255))
    save(img, "weapon_laser.png")


def weapon_heavy_laser():
    img = new(32, 32)
    fill(img, 6, 10, 24, 22, (70, 74, 84, 255))
    fill(img, 22, 12, 31, 20, (60, 210, 220, 255))   # big emitter
    fill(img, 25, 13, 30, 19, (170, 250, 255, 255))
    fill(img, 6, 22, 12, 28, (70, 74, 84, 255))
    outline(img, (20, 20, 24, 255))
    save(img, "weapon_heavy_laser.png")


def weapon_throw():
    img = new(32, 32)
    disc(img, 16, 16, 4, (180, 184, 192, 255))
    for a in range(0, 360, 60):
        import math
        rad = math.radians(a)
        x = 16 + math.cos(rad) * 11
        y = 16 + math.sin(rad) * 11
        fill(img, int(x) - 1, int(y) - 1, int(x) + 1, int(y) + 1, (180, 184, 192, 255))
        # blade
        bx = 16 + math.cos(rad) * 14
        by = 16 + math.sin(rad) * 14
        put(img, int(bx), int(by), (210, 214, 222, 255))
    outline(img, (40, 44, 54, 255))
    save(img, "weapon_throw.png")


def weapon_explosive():
    img = new(32, 32)
    disc(img, 16, 17, 8, (70, 150, 60, 255))         # green grenade
    fill(img, 13, 8, 19, 11, (110, 110, 116, 255))   # cap
    fill(img, 15, 4, 17, 8, (150, 150, 60, 255))     # pin
    fill(img, 14, 14, 18, 16, (40, 110, 36, 255))
    outline(img, (24, 60, 22, 255))
    save(img, "weapon_explosive.png")


def weapon_summon():
    img = new(32, 32)
    disc(img, 16, 14, 6, (150, 156, 168, 255))       # drone body
    fill(img, 2, 12, 8, 16, (110, 116, 128, 255))    # rotor L
    fill(img, 24, 12, 30, 16, (110, 116, 128, 255))  # rotor R
    fill(img, 14, 18, 18, 22, (90, 200, 220, 255))   # scanner
    outline(img, (30, 30, 36, 255))
    save(img, "weapon_summon.png")


def weapon_spray():
    img = new(32, 32)
    fill(img, 8, 14, 22, 20, (120, 122, 130, 255))   # tank
    fill(img, 20, 15, 31, 18, (210, 110, 40, 255))   # nozzle flame
    fill(img, 24, 15, 31, 17, (240, 200, 60, 255))
    fill(img, 25, 15, 31, 16, (255, 240, 120, 255))
    fill(img, 8, 20, 13, 26, (120, 122, 130, 255))   # grip
    outline(img, (20, 20, 24, 255))
    save(img, "weapon_spray.png")


def weapon_fallback():
    img = new(32, 32)
    _gun_body(img, (130, 132, 140, 255), (160, 162, 170, 255), (190, 192, 200, 255))
    save(img, "weapon_icon.png")


# ---------- upgrade-kind icons (24x24) ----------
def icon_health():
    img = new(24, 24)
    for (x, y) in [(8, 6), (9, 5), (10, 5), (11, 6), (12, 6), (13, 5), (14, 5), (15, 6)]:
        put(img, x, y, (220, 50, 60, 255))
    fill(img, 8, 7, 15, 8, (220, 50, 60, 255))
    fill(img, 9, 9, 14, 12, (220, 50, 60, 255))
    fill(img, 10, 13, 13, 16, (220, 50, 60, 255))
    fill(img, 11, 17, 12, 19, (220, 50, 60, 255))
    outline(img, (120, 20, 26, 255))
    save(img, "icon_health.png")


def icon_strength():
    img = new(24, 24)
    fill(img, 7, 8, 17, 18, (200, 80, 70, 255))      # fist
    fill(img, 7, 6, 17, 8, (220, 100, 90, 255))
    fill(img, 9, 4, 12, 7, (220, 100, 90, 255))      # thumb
    fill(img, 7, 18, 17, 21, (170, 60, 54, 255))
    outline(img, (110, 36, 30, 255))
    save(img, "icon_strength.png")


def icon_agility():
    img = new(24, 24)
    fill(img, 9, 6, 15, 10, (80, 180, 90, 255))      # boot top
    fill(img, 9, 10, 14, 18, (80, 180, 90, 255))
    fill(img, 9, 18, 18, 21, (60, 150, 70, 255))     # sole
    outline(img, (30, 90, 40, 255))
    save(img, "icon_agility.png")


def icon_intelligence():
    img = new(24, 24)
    fill(img, 8, 6, 16, 16, (70, 120, 210, 255))     # brain
    fill(img, 9, 7, 15, 15, (100, 150, 230, 255))
    fill(img, 11, 9, 13, 13, (150, 190, 250, 255))
    outline(img, (30, 60, 130, 255))
    save(img, "icon_intelligence.png")


def icon_constitution():
    img = new(24, 24)
    fill(img, 8, 5, 16, 20, (140, 144, 152, 255))    # shield
    fill(img, 9, 6, 15, 13, (176, 180, 190, 255))
    fill(img, 10, 14, 14, 19, (140, 144, 152, 255))
    fill(img, 11, 9, 13, 12, (90, 94, 102, 255))
    outline(img, (60, 64, 72, 255))
    save(img, "icon_constitution.png")


def icon_luck():
    img = new(24, 24)
    disc(img, 12, 12, 8, (220, 180, 50, 255))        # coin
    disc(img, 12, 12, 6, (240, 210, 90, 255))
    fill(img, 10, 10, 14, 14, (200, 160, 40, 255))
    outline(img, (130, 100, 24, 255))
    save(img, "icon_luck.png")


def icon_willpower():
    img = new(24, 24)
    fill(img, 11, 4, 13, 8, (170, 90, 210, 255))     # flame
    fill(img, 9, 8, 15, 14, (190, 110, 230, 255))
    fill(img, 10, 14, 14, 20, (150, 80, 190, 255))
    fill(img, 11, 18, 13, 21, (120, 60, 160, 255))
    fill(img, 11, 9, 13, 13, (230, 180, 255, 255))
    outline(img, (90, 40, 120, 255))
    save(img, "icon_willpower.png")


def icon_weapon():
    img = new(24, 24)
    line(img, 4, 20, 18, 6, (200, 206, 218, 255))    # blade 1
    line(img, 20, 4, 18, 6, (200, 206, 218, 255))
    line(img, 20, 20, 6, 6, (200, 206, 218, 255))    # blade 2
    line(img, 4, 4, 6, 6, (200, 206, 218, 255))
    fill(img, 10, 10, 14, 14, (120, 80, 40, 255))    # cross
    outline(img, (40, 44, 54, 255))
    save(img, "icon_weapon.png")


# ---------- UI backgrounds ----------
def menu_bg():
    img = new(320, 180)
    # sky gradient (blocky)
    for y in range(180):
        t = y / 180.0
        r = int(18 + t * 30)
        g = int(16 + t * 20)
        b = int(34 + t * 26)
        fill(img, 0, y, 319, y, (r, g, b, 255))
    # moon
    disc(img, 250, 40, 16, (230, 230, 200, 255))
    disc(img, 244, 36, 14, (200, 200, 170, 255))
    # city skyline silhouette
    fill(img, 0, 120, 319, 179, (10, 10, 18, 255))
    sky = [(0, 40), (40, 70), (90, 30), (130, 90), (180, 50), (220, 80), (270, 35)]
    for i in range(len(sky) - 1):
        x0, h0 = sky[i]
        x1, h1 = sky[i + 1]
        for x in range(x0, x1):
            h = int(h0 + (h1 - h0) * (x - x0) / max(1, (x1 - x0)))
            top = 180 - h
            fill(img, x, top, x, 179, (14, 14, 24, 255))
            # lit windows
            if (x // 6) % 2 == 0 and (x % 12) < 5:
                put(img, x, top + 8, (220, 200, 90, 255))
    save(img, "menu_bg.png", scale=4)  # -> 1280x720


def card_bg():
    img = new(220, 96)
    fill(img, 0, 0, 219, 95, (26, 24, 38, 230))     # dark fill
    # pixel border
    fill(img, 0, 0, 219, 3, (120, 110, 170, 255))
    fill(img, 0, 92, 219, 95, (120, 110, 170, 255))
    fill(img, 0, 0, 3, 95, (120, 110, 170, 255))
    fill(img, 216, 0, 219, 95, (120, 110, 170, 255))
    fill(img, 4, 4, 215, 91, (40, 36, 58, 255))     # inner panel
    save(img, "card_bg.png")


# ---------- run ----------
if __name__ == "__main__":
    floor_street()
    floor_supermarket()
    floor_hotel()
    floor_hospital()
    floor_parking()
    floor_boss()
    building()
    car()
    crate()
    weapon_rifle()
    weapon_heavy_ranged()
    weapon_blade()
    weapon_blunt()
    weapon_heavy_blunt()
    weapon_laser()
    weapon_heavy_laser()
    weapon_throw()
    weapon_explosive()
    weapon_summon()
    weapon_spray()
    weapon_fallback()
    icon_health()
    icon_strength()
    icon_agility()
    icon_intelligence()
    icon_constitution()
    icon_luck()
    icon_willpower()
    icon_weapon()
    menu_bg()
    card_bg()
    print("DONE")
