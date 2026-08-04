"""Generate a cohesive pixel-art sprite set for ZombieRoguelike.
Run with the managed Python venv that has Pillow installed.
Outputs PNGs (nearest-neighbour upscaled) into assets/pixel/.
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "pixel")
os.makedirs(OUT, exist_ok=True)

OUTLINE = (18, 18, 24, 255)
EYE = (15, 15, 20, 255)
WHITE = (245, 245, 250, 255)


def grid(n):
    img = Image.new("RGBA", (n, n), (0, 0,0,0))
    return img, ImageDraw.Draw(img)


def save(img, n, scale, name):
    big = img.resize((n * scale, n * scale), Image.NEAREST)
    big.save(os.path.join(OUT, name))
    print("wrote", name)


def ellipse(d, n, color, inset=0):
    d.ellipse([inset, inset, n - 1 - inset, n - 1 - inset], fill=color)


def creature(n, scale, body, name, gun=False, crown=False, eye=EYE):
    img, d = grid(n)
    ellipse(d, n, OUTLINE, 0)
    ellipse(d, n, body, 1)
    # eyes
    cx = n // 2
    ey = n // 2 - 1
    d.point((cx - 2, ey), fill=eye)
    d.point((cx + 1, ey), fill=eye)
    # front notch (darker) at top
    d.rectangle([cx - 1, 0, cx, 2], fill=OUTLINE)
    if gun:
        d.rectangle([cx - 1, 0, cx, 3], fill=(70, 70, 82, 255))
    if crown:
        for x in range(1, n - 1, 3):
            d.point((x, 0), fill=(240, 210, 80, 255))
    save(img, n, scale, name)


# --- Players (6 classes) ---
PLAYER_COLORS = [
    (76, 175, 80),    # 0 veteran - green
    (200, 120, 60),   # 1 mech_monk - orange/steel
    (60, 200, 200),   # 2 cyber_cultivator - cyan
    (230, 120, 170),  # 3 cat_cafe_worker - pink
    (150, 90, 200),   # 4 professor - purple
    (220, 70, 200),   # 5 alien_shooter - magenta
]
for i, c in enumerate(PLAYER_COLORS):
    creature(18, 3, tuple(list(c) + [255]), "player_%d.png" % i, gun=True)

# --- Zombies ---
creature(16, 3, (90, 150, 70, 255), "zombie_normal.png")
creature(16, 3, (155, 205, 90, 255), "zombie_fast.png")
creature(16, 3, (60, 110, 60, 255), "zombie_tank.png")
creature(16, 3, (205, 95, 60, 255), "zombie_self.png")
creature(16, 3, (95, 120, 205, 255), "zombie_elite.png")

# --- Bosses ---
creature(22, 3, (205, 55, 55, 255), "boss_king.png", crown=True)
creature(22, 3, (155, 65, 185, 255), "boss_titan.png", crown=True)
creature(22, 3, (65, 185, 205, 255), "boss_nano.png", crown=True)
creature(22, 3, (225, 205, 65, 255), "boss_alpha.png", crown=True)

# --- Bullet (white, tinted via modulate in-game) ---
img, d = grid(8)
ellipse(d, 8, (255, 240, 170, 255), 1)
ellipse(d, 8, (255, 255, 220, 255), 2)
save(img, 8, 2, "bullet.png")

# --- Soul orb (green glow) ---
img, d = grid(10)
ellipse(d, 10, (70, 200, 95, 170), 0)
ellipse(d, 10, (140, 255, 160, 255), 2)
save(img, 10, 3, "orb.png")

# --- Potion (red flask) ---
img, d = grid(12)
d.rectangle([4, 5, 7, 10], fill=(210, 70, 70, 255))
d.rectangle([5, 2, 6, 5], fill=(185, 185, 195, 255))
d.rectangle([4, 6, 7, 7], fill=(255, 130, 130, 255))
save(img, 12, 3, "item_potion.png")

# --- Weapon (sword) ---
img, d = grid(12)
d.rectangle([5, 1, 6, 9], fill=(225, 225, 235, 255))
d.rectangle([3, 8, 8, 9], fill=(150, 105, 60, 255))
d.rectangle([5, 9, 6, 11], fill=(125, 85, 55, 255))
save(img, 12, 3, "item_weapon.png")

# --- Accessory (gem) ---
img, d = grid(12)
d.polygon([(6, 1), (10, 6), (6, 11), (2, 6)], fill=(90, 150, 230, 255))
d.polygon([(6, 3), (8, 6), (6, 9), (4, 6)], fill=(165, 205, 255, 255))
save(img, 12, 3, "item_accessory.png")

# --- Parts / limb (gear) ---
img, d = grid(12)
ellipse(d, 12, (230, 150, 60, 255), 2)
ellipse(d, 12, (120, 70, 20, 255), 4)
for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
    d.rectangle([6 + dx * 4, 6 + dy * 4, 6 + dx * 4, 6 + dy * 4], fill=(230, 150, 60, 255))
save(img, 12, 3, "item_parts.png")

# --- Summon unit (drone) ---
img, d = grid(14)
d.rectangle([4, 4, 9, 9], fill=(90, 200, 120, 255))
d.rectangle([5, 5, 8, 7], fill=(40, 120, 70, 255))
d.point((6, 6), fill=WHITE)
d.point((7, 6), fill=WHITE)
save(img, 14, 3, "summon.png")

# --- Floor tile (subtle grid) ---
img, d = grid(16)
d.rectangle([0, 0, 15, 15], fill=(34, 38, 46, 255))
d.rectangle([0, 0, 15, 0], fill=(44, 49, 58, 255))
d.rectangle([0, 0, 0, 15], fill=(44, 49, 58, 255))
save(img, 16, 4, "floor_tile.png")

print("DONE")
