"""Generate a cohesive, fully-distinct pixel-art cast for ZombieRoguelike.

Covers every CharacterClass (6 players) and every ZombieType (11 regular +
4 bosses). Each monster type gets a unique silhouette/feature, not just a
recolour, so the player can tell them apart at a glance.

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
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def save(img, n, scale, name):
    big = img.resize((n * scale, n * scale), Image.NEAREST)
    big.save(os.path.join(OUT, name))
    print("wrote", name)


def ellipse(d, n, color, inset=0):
    d.ellipse([inset, inset, n - 1 - inset, n - 1 - inset], fill=color)


def eyes2(d, n, color=EYE):
    cx = n // 2
    ey = n // 2 - 1
    d.point((cx - 2, ey), fill=color)
    d.point((cx + 1, ey), fill=color)


# --------------------------------------------------------------------------
# PLAYERS (6 classes, class-distinct silhouettes)
# --------------------------------------------------------------------------
def player(n, scale, body, name, kind):
    img, d = grid(n)
    ellipse(d, n, OUTLINE, 0)
    ellipse(d, n, body, 1)
    # facing notch
    cx = n // 2
    d.rectangle([cx - 1, 0, cx, 2], fill=OUTLINE)
    if kind == "veteran":
        # cap brim
        d.rectangle([cx - 4, 1, cx + 4, 2], fill=(40, 60, 40, 255))
        eyes2(d, n)
    elif kind == "mech_monk":
        # mechanical right arm
        d.rectangle([n - 4, n // 2 - 2, n - 2, n // 2 + 3], fill=(170, 175, 185, 255))
        d.rectangle([n - 4, n // 2 - 2, n - 2, n // 2 - 1], fill=(220, 225, 235, 255))
        eyes2(d, n)
    elif kind == "cyber_cultivator":
        # chest glow core
        ellipse(d, n, (120, 240, 255, 255), n // 2 - 2)
        eyes2(d, n, (200, 255, 255, 255))
    elif kind == "cat_cafe_worker":
        # cat ears
        d.polygon([(cx - 5, 2), (cx - 2, 0), (cx - 1, 3)], fill=body)
        d.polygon([(cx + 5, 2), (cx + 2, 0), (cx + 1, 3)], fill=body)
        d.polygon([(cx - 4, 2), (cx - 2, 1), (cx - 1, 3)], fill=(255, 180, 210, 255))
        d.polygon([(cx + 4, 2), (cx + 2, 1), (cx + 1, 3)], fill=(255, 180, 210, 255))
        eyes2(d, n, (60, 60, 70, 255))
    elif kind == "professor":
        # glasses
        eyes2(d, n)
        d.rectangle([cx - 4, n // 2 - 2, cx - 1, n // 2], fill=(30, 30, 40, 255))
        d.rectangle([cx + 1, n // 2 - 2, cx + 4, n // 2], fill=(30, 30, 40, 255))
        d.line([(cx - 1, n // 2 - 1), (cx + 1, n // 2 - 1)], fill=(30, 30, 40, 255))
    elif kind == "alien_shooter":
        # antenna + big single eye
        d.line([(cx, 1), (cx, 4)], fill=(200, 200, 210, 255))
        d.point((cx, 1), fill=(120, 255, 160, 255))
        d.ellipse([cx - 3, n // 2 - 3, cx + 3, n // 2 + 1], fill=(180, 255, 210, 255))
        d.point((cx, n // 2 - 1), fill=EYE)
    save(img, n, scale, name)


N = 18
player(N, 3, (76, 175, 80, 255), "player_0.png", "veteran")
player(N, 3, (200, 120, 60, 255), "player_1.png", "mech_monk")
player(N, 3, (60, 200, 200, 255), "player_2.png", "cyber_cultivator")
player(N, 3, (230, 120, 170, 255), "player_3.png", "cat_cafe_worker")
player(N, 3, (150, 90, 200, 255), "player_4.png", "professor")
player(N, 3, (220, 70, 200, 255), "player_5.png", "alien_shooter")


# --------------------------------------------------------------------------
# ZOMBIES (11 regular types, each visually distinct)
# --------------------------------------------------------------------------
def zombie(n, scale, body, name, kind):
    img, d = grid(n)
    a = body[3] if len(body) == 4 else 255
    ellipse(d, n, OUTLINE, 0)
    ellipse(d, n, body, 1)
    cx = n // 2
    d.rectangle([cx - 1, 0, cx, 2], fill=OUTLINE)

    if kind == "normal":
        eyes2(d, n)
    elif kind == "fast":
        # leaner, with motion streaks behind
        eyes2(d, n, (255, 255, 200, 255))
        for y in (n // 2 - 2, n // 2 + 1):
            d.line([(1, y), (4, y)], fill=(255, 255, 180, 160))
    elif kind == "tank":
        # armored shoulder plates
        d.rectangle([1, n // 2 - 3, 3, n // 2 + 3], fill=(90, 95, 105, 255))
        d.rectangle([n - 4, n // 2 - 3, n - 2, n // 2 + 3], fill=(90, 95, 105, 255))
        eyes2(d, n, (255, 120, 120, 255))
    elif kind == "self_destruct":
        # pulsing core + warning spikes
        ellipse(d, n, (255, 230, 120, 255), n // 2 - 2)
        d.point((cx, n // 2 - 1), fill=(180, 60, 0, 255))
        for (dx, dy) in [(-4, -4), (4, -4), (-4, 4), (4, 4)]:
            d.point((cx + dx, n // 2 + dy), fill=(255, 200, 80, 255))
    elif kind == "mecha_mutant":
        # robotic plates + antenna
        d.rectangle([cx - 5, n // 2 - 1, cx + 5, n // 2 + 1], fill=(110, 110, 150, 255))
        d.line([(cx, 1), (cx, 4)], fill=(200, 200, 210, 255))
        d.point((cx, 1), fill=(255, 90, 90, 255))
        eyes2(d, n, (200, 230, 255, 255))
    elif kind == "bio_shield":
        # front shield arc
        d.arc([2, 2, n - 3, n - 3], 200, 340, fill=(120, 220, 160, 200), width=2)
        eyes2(d, n, (200, 255, 200, 255))
    elif kind == "nanomite":
        # fragmented swarm dots
        eyes2(d, n, (255, 160, 255, 255))
        for (dx, dy) in [(-5, -3), (5, -3), (-5, 3), (5, 3), (0, -5), (0, 5)]:
            d.point((cx + dx, n // 2 + dy), fill=(210, 110, 210, 255))
    elif kind == "hologram":
        # translucent cyan with scanlines (baked alpha)
        for y in range(2, n - 2, 2):
            d.line([(2, y), (n - 3, y)], fill=(180, 255, 255, 60))
        d.point((cx - 2, n // 2 - 1), fill=(220, 255, 255, 200))
        d.point((cx + 1, n // 2 - 1), fill=(220, 255, 255, 200))
    elif kind == "elite_bio_tyrant":
        # big maw + horns
        d.polygon([(cx - 4, 1), (cx - 2, 0), (cx - 2, 4)], fill=(70, 10, 10, 255))
        d.polygon([(cx + 4, 1), (cx + 2, 0), (cx + 2, 4)], fill=(70, 10, 10, 255))
        d.rectangle([cx - 3, n // 2 + 1, cx + 3, n // 2 + 3], fill=(120, 0, 0, 255))
        d.point((cx - 1, n // 2 + 2), fill=(255, 120, 120, 255))
        d.point((cx + 1, n // 2 + 2), fill=(255, 120, 120, 255))
        eyes2(d, n, (255, 60, 60, 255))
    elif kind == "elite_mecha_soldier":
        # visor bar + shoulder cannons
        d.rectangle([cx - 4, n // 2 - 2, cx + 4, n // 2 - 1], fill=(120, 200, 255, 255))
        d.rectangle([1, n // 2 - 3, 3, n // 2 + 1], fill=(60, 60, 90, 255))
        d.rectangle([n - 4, n // 2 - 3, n - 2, n // 2 + 1], fill=(60, 60, 90, 255))
        eyes2(d, n, (160, 220, 255, 255))
    elif kind == "elite_gene_fusion":
        # triple glowing eyes + fused core
        ellipse(d, n, (255, 240, 140, 255), n // 2 - 1)
        cx2 = n // 2
        d.point((cx2 - 3, n // 2 - 1), fill=(255, 120, 0, 255))
        d.point((cx2, n // 2 - 1), fill=(255, 120, 0, 255))
        d.point((cx2 + 3, n // 2 - 1), fill=(255, 120, 0, 255))
    save(img, n, scale, name)


ZN = 18
zombie(ZN, 3, (153, 76, 76, 255), "zombie_normal.png", "normal")
zombie(ZN, 3, (204, 204, 51, 255), "zombie_fast.png", "fast")
zombie(ZN, 3, (102, 102, 102, 255), "zombie_tank.png", "tank")
zombie(ZN, 3, (255, 102, 0, 255), "zombie_self.png", "self_destruct")
zombie(ZN, 3, (128, 128, 204, 255), "zombie_mecha_mutant.png", "mecha_mutant")
zombie(ZN, 3, (51, 153, 51, 255), "zombie_bio_shield.png", "bio_shield")
zombie(ZN, 3, (153, 51, 153, 255), "zombie_nanomite.png", "nanomite")
zombie(ZN, 3, (77, 204, 204, 150), "zombie_hologram.png", "hologram")
zombie(ZN, 3, (255, 0, 0, 255), "zombie_elite_bio_tyrant.png", "elite_bio_tyrant")
zombie(ZN, 3, (0, 0, 255, 255), "zombie_elite_mecha_soldier.png", "elite_mecha_soldier")
zombie(ZN, 3, (255, 230, 0, 255), "zombie_elite_gene_fusion.png", "elite_gene_fusion")
# keep a generic elite fallback for safety
zombie(ZN, 3, (95, 120, 205, 255), "zombie_elite.png", "elite_bio_tyrant")


# --------------------------------------------------------------------------
# BOSSES (4, bigger, crowned, type-distinct)
# --------------------------------------------------------------------------
def boss(n, scale, body, name, kind):
    img, d = grid(n)
    ellipse(d, n, OUTLINE, 0)
    ellipse(d, n, body, 1)
    cx = n // 2
    if kind == "king":
        eyes2(d, n, (255, 220, 120, 255))
        d.rectangle([cx - 5, n // 2 + 2, cx + 5, n // 2 + 4], fill=(120, 20, 20, 255))
    elif kind == "titan":
        # armor plates + horns
        d.rectangle([2, n // 2 - 4, 5, n // 2 + 4], fill=(90, 60, 110, 255))
        d.rectangle([n - 6, n // 2 - 4, n - 3, n // 2 + 4], fill=(90, 60, 110, 255))
        d.polygon([(cx - 6, 2), (cx - 3, 0), (cx - 3, 5)], fill=(50, 30, 60, 255))
        d.polygon([(cx + 6, 2), (cx + 3, 0), (cx + 3, 5)], fill=(50, 30, 60, 255))
        eyes2(d, n, (230, 160, 255, 255))
    elif kind == "nano":
        # core glow + antenna
        ellipse(d, n, (180, 255, 255, 255), n // 2 - 3)
        d.line([(cx, 1), (cx, 5)], fill=(200, 200, 210, 255))
        d.point((cx, 1), fill=(120, 255, 255, 255))
        eyes2(d, n, (200, 255, 255, 255))
    elif kind == "alpha":
        # triple eyes + spikes
        cx2 = n // 2
        d.point((cx2 - 4, n // 2 - 1), fill=(255, 200, 0, 255))
        d.point((cx2, n // 2 - 1), fill=(255, 200, 0, 255))
        d.point((cx2 + 4, n // 2 - 1), fill=(255, 200, 0, 255))
        for (dx, dy) in [(-6, -5), (6, -5), (-6, 5), (6, 5)]:
            d.point((cx + dx, n // 2 + dy), fill=(255, 230, 120, 255))
    # crown for all bosses
    for x in range(2, n - 1, 3):
        d.point((x, 0), fill=(240, 210, 80, 255))
    save(img, n, scale, name)


BN = 22
boss(BN, 3, (205, 55, 55, 255), "boss_king.png", "king")
boss(BN, 3, (155, 65, 185, 255), "boss_titan.png", "titan")
boss(BN, 3, (65, 185, 205, 255), "boss_nano.png", "nano")
boss(BN, 3, (225, 205, 65, 255), "boss_alpha.png", "alpha")

print("DONE")
