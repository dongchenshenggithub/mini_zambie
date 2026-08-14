"""
Generate distinct, clear pixel-art icons for all drop items in the game.
Output: 5 item icons (32x32) + 1 white rarity ring (32x32).

Design philosophy:
- Each icon has a UNIQUE SHAPE + SIGNATURE COLOR so players can tell
  drop types apart at a glance even at small display size (~18px).
- Rarity is shown via a SEPARATE colored ring (not tinting the icon),
  so type color and rarity color never conflict.

Icons generated:
  item_potion.png   - Red flask (heal)
  item_weapon.png   - Steel blade (weapon pickup)
  item_accessory.png - Purple gem (accessory)
  item_parts.png    - Orange gear (parts/limb)
  orb.png           - Cyan soul star (XP)
  rarity_ring.png   - White circle outline (modulated to rarity color)
"""

from PIL import Image, ImageDraw
import os

SIZE = 32
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "pixel")


def P(img, x, y, c):
    """Set a single pixel."""
    if 0 <= x < SIZE and 0 <= y < SIZE:
        img.putpixel((int(x), int(y)), c)


def rect(img, x1, y1, x2, y2, c):
    """Filled rectangle."""
    for y in range(int(y1), int(y2) + 1):
        for x in range(int(x1), int(x2) + 1):
            P(img, x, y, c)


def fcirc(img, cx, cy, r, c, fill=False):
    """Circle outline or filled."""
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            dx = x - cx
            dy = y - cy
            d2 = dx * dx + dy * dy
            if fill:
                if d2 <= r * r:
                    P(img, x, y, c)
            else:
                if r * r <= d2 <= (r + 0.5) * (r + 0.5):
                    P(img, x, y, c)


def line(img, x1, y1, x2, y2, c, thick=1):
    """Bresenham-style line with thickness."""
    steps = max(abs(x2 - x1), abs(y2 - y1), 1)
    for i in range(steps + 1):
        t = i / steps
        x = x1 + (x2 - x1) * t
        y = y1 + (y2 - y1) * t
        for dy in range(-thick // 2, thick - thick // 2):
            for dx in range(-thick // 2, thick - thick // 2):
                P(img, x + dx, y + dy, c)


# ── Color palette ──────────────────────────────────────────────
C_RED       = (220, 60, 60)     # potion
C_RED_DARK  = (160, 40, 40)
C_RED_LIGHT = (255, 120, 120)
C_STEEL     = (180, 190, 210)   # weapon blade
C_STEEL_DARK= (120, 130, 150)
C_BROWN     = (160, 120, 80)    # weapon hilt
C_PURPLE    = (180, 100, 220)   # accessory
C_PURPLE_LT = (220, 170, 255)
C_ORANGE    = (230, 150, 50)    # parts gear
C_ORANGE_DK = (180, 110, 30)
C_CYAN      = (80, 220, 220)    # soul orb
C_CYAN_LT   = (160, 255, 255)
C_GREEN     = (120, 220, 140)   # companion (ally/guard)
C_GREEN_DK  = (70, 160, 95)
C_GREEN_LT  = (190, 255, 205)
C_WHITE     = (255, 255, 255)   # rarity ring / highlights
C_BLACK     = (20, 20, 25)      # outlines / darks


# ═══════════════════════════════════════════════════════════════
# 1. POTION — red flask with cork and liquid level
# ═══════════════════════════════════════════════════════════════
def draw_potion():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    # Bottle body (rounded rectangle)
    rect(img, 10, 12, 21, 27, C_RED)
    # Darker bottom
    rect(img, 10, 22, 21, 27, C_RED_DARK)
    # Highlight on left
    rect(img, 11, 13, 12, 21, C_RED_LIGHT)
    # Neck
    rect(img, 13, 7, 18, 11, C_RED_DARK)
    # Cork/stopper
    rect(img, 13, 4, 18, 6, C_BROWN)
    # Cork highlight
    P(img, 14, 5, C_ORANGE)
    # Outline
    for y in range(12, 28):
        P(img, 10, y, C_BLACK)
        P(img, 21, y, C_BLACK)
    for x in range(10, 22):
        P(img, x, 27, C_BLACK)
        P(img, x, 12, C_BLACK)
    # Neck outline
    P(img, 13, 7, C_BLACK); P(img, 18, 7, C_BLACK)
    P(img, 13, 11, C_BLACK); P(img, 18, 11, C_BLACK)
    # Cross symbol (medical/heal indicator)
    rect(img, 15, 16, 16, 20, C_WHITE)
    rect(img, 14, 17, 17, 18, C_WHITE)

    img.save(os.path.join(OUT, "item_potion.png"))
    print("  item_potion.png  (red flask)")


# ═══════════════════════════════════════════════════════════════
# 2. WEAPON — diagonal sword blade with hilt
# ═══════════════════════════════════════════════════════════════
def draw_weapon():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    # Blade (diagonal from lower-left to upper-right)
    # Main blade body
    line(img, 8, 26, 24, 6, C_STEEL, thick=5)
    # Blade edge highlight (right side)
    line(img, 11, 25, 25, 5, C_WHITE, thick=1)
    # Blade dark edge (left side)
    line(img, 6, 27, 22, 7, C_STEEL_DARK, thick=1)
    # Point tip
    P(img, 24, 6, C_WHITE)
    P(img, 25, 5, C_STEEL)

    # Guard (horizontal bar across hilt)
    rect(img, 5, 23, 12, 25, C_BROWN)
    rect(img, 6, 24, 11, 24, C_ORANGE)  # guard highlight

    # Hilt handle
    rect(img, 7, 25, 10, 29, C_BROWN)
    rect(img, 8, 26, 9, 28, C_ORANGE)  # hilt wrap

    # Pommel (bottom)
    fcirc(img, 8.5, 29.5, 2.0, C_BROWN, fill=True)
    P(img, 8, 30, C_ORANGE)

    img.save(os.path.join(OUT, "item_weapon.png"))
    print("  item_weapon.png  (steel sword)")


# ═══════════════════════════════════════════════════════════════
# 3. ACCESSORY — faceted purple gem/diamond
# ═══════════════════════════════════════════════════════════════
def draw_accessory():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    # Diamond shape (rotated square = 4-point gem)
    pts = [(cx, 4), (27, cy), (cx, 28), (5, cy)]

    # Fill diamond body
    from PIL import ImageDraw as ID
    d = ID.Draw(img)
    d.polygon(pts, fill=C_PURPLE)

    # Darker bottom half
    bpts = [(cx, 16), (27, cy), (cx, 28), (5, cy)]
    d.polygon(bpts, fill=C_PURPLE)

    # Left facet (darker)
    lpts = [(cx, 4), (cx, 28), (5, cy)]
    d.polygon(lpts, fill=(140, 70, 180))

    # Right facet (lighter)
    rpts = [(cx, 4), (cx, 28), (27, cy)]
    d.polygon(rpts, fill=C_PURPLE_LT)

    # Top highlight (brightest)
    tpts = [(cx, 4), (20, cy - 3), (cx, cy)]
    d.polygon(tpts, fill=C_WHITE)

    # Outline
    d.polygon(pts, fill=None, outline=C_BLACK)

    # Small sparkle
    P(img, cx + 2, cy - 5, C_WHITE)
    P(img, cx + 3, cy - 6, C_WHITE)

    img.save(os.path.join(OUT, "item_accessory.png"))
    print("  item_accessory.png (purple gem)")


# ═══════════════════════════════════════════════════════════════
# 4. PARTS — orange gear/cog with teeth
# ═══════════════════════════════════════════════════════════════
def draw_parts():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2
    r_outer = 11.0
    r_inner = 6.0
    teeth = 8

    # Gear body (filled ring)
    fcirc(img, cx, cy, r_outer, C_ORANGE, fill=True)
    fcirc(img, cx, cy, r_inner, (0, 0, 0, 0), fill=True)  # hollow center

    # Teeth (rectangles around the perimeter)
    import math
    for i in range(teeth):
        ang = (2 * math.pi * i) / teeth
        tx = cx + (r_outer + 2) * math.cos(ang)
        ty = cy + (r_outer + 2) * math.sin(ang)
        tw, th = 4, 3
        # Rotate-aligned tooth (approximate as axis-aligned box at position)
        rect(img, int(tx - tw / 2), int(ty - th / 2),
              int(tx + tw / 2), int(ty + th / 2), C_ORANGE)

    # Inner hub
    fcirc(img, cx, cy, 4.0, C_ORANGE_DK, fill=True)

    # Center hole (dark)
    fcirc(img, cx, cy, 2.0, C_BLACK, fill=True)

    # Highlight arc (upper-left quadrant of outer ring)
    for a_deg in range(135, 225):
        a = math.radians(a_deg)
        px = cx + (r_outer - 2) * math.cos(a)
        py = cy + (r_outer - 2) * math.sin(a)
        P(img, int(px), int(py), (255, 200, 100))

    # Darker bottom-right
    for a_deg in range(-45, 45):
        a = math.radians(a_deg)
        px = cx + (r_outer - 2) * math.cos(a)
        py = cy + (r_outer - 2) * math.sin(a)
        P(img, int(px), int(py), C_ORANGE_DK)

    img.save(os.path.join(OUT, "item_parts.png"))
    print("  item_parts.png   (orange gear)")


# ═══════════════════════════════════════════════════════════════
# 5. SOUL ORB — cyan glowing 4-point star
# ═══════════════════════════════════════════════════════════════
def draw_orb():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    # Outer glow (larger faint circle)
    fcirc(img, cx, cy, 13.0, (100, 240, 240, 60), fill=True)

    # Main body (diamond shape)
    from PIL import ImageDraw as ID
    d = ID.Draw(img)
    pts = [(cx, 5), (27, cy), (cx, 27), (5, cy)]
    d.polygon(pts, fill=C_CYAN)

    # Inner bright core
    ipts = [(cx, 10), (21, cy), (cx, 22), (11, cy)]
    d.polygon(ipts, fill=C_CYAN_LT)

    # Brightest center
    fcirc(img, cx, cy, 4.0, C_WHITE, fill=True)

    # Star points (4 diagonal rays)
    ray_len = 5
    for dx, dy in [(-1, -1), (1, -1), (1, 1), (-1, 1)]:
        for s in range(ray_len):
            dist = s + 1
            alpha = 255 - int(200 * dist / ray_len)
            col = (C_CYAN_LT[0], C_CYAN_LT[1], C_CYAN_LT[2], alpha)
            P(img, int(cx + dx * dist), int(cy + dy * dist), col)

    # Outline
    d.polygon(pts, fill=None, outline=(40, 180, 180))

    img.save(os.path.join(OUT, "orb.png"))
    print("  orb.png          (cyan soul star)")


# ═══════════════════════════════════════════════════════════════
# 6. RARITY RING — white circle outline (modulated to rarity color)
# ═══════════════════════════════════════════════════════════════
def draw_rarity_ring():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    # Ring: outer r=15, inner r=12 (3px thick)
    for r in range(12, 16):
        fcirc(img, cx, cy, float(r), C_WHITE, fill=False)

    # Slightly soften: make inner edge slightly transparent
    # (already handled by anti-aliasing via multiple circles)

    img.save(os.path.join(OUT, "rarity_ring.png"))
    print("  rarity_ring.png  (white circle outline)")


# ═══════════════════════════════════════════════════════════════
# 7. COMPANION — green paw print (ally / guard drop)
# ═══════════════════════════════════════════════════════════════
def draw_companion():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2

    # Outer soft halo so the drop reads as "friendly ally"
    fcirc(img, cx, cy, 14.0, (120, 220, 140, 45), fill=True)

    # Main pad (lower-center, big ellipse approximated by a filled circle)
    fcirc(img, cx, cy + 4, 6.5, C_GREEN, fill=True)
    # Pad shading (darker bottom)
    fcirc(img, cx, cy + 6, 5.0, C_GREEN_DK, fill=True)
    fcirc(img, cx, cy + 2, 4.5, C_GREEN, fill=True)

    # Four toes (small circles arranged in an arc above the pad)
    toes = [
        (cx - 7, cy - 5),
        (cx - 3, cy - 8),
        (cx + 3, cy - 8),
        (cx + 7, cy - 5),
    ]
    for tx, ty in toes:
        fcirc(img, float(tx), float(ty), 3.0, C_GREEN, fill=True)
        fcirc(img, float(tx), float(ty) + 1.0, 2.0, C_GREEN_LT, fill=True)

    # Pad highlight
    P(img, cx - 1, cy + 1, C_GREEN_LT)

    # Outline around pad + toes for readability
    for tx, ty in toes:
        d2 = ImageDraw.Draw(img)
        d2.ellipse([tx - 3, ty - 3, tx + 3, ty + 3], outline=C_BLACK)
    d = ImageDraw.Draw(img)
    d.ellipse([cx - 6, cy - 2, cx + 6, cy + 10], outline=C_BLACK)

    img.save(os.path.join(OUT, "item_companion.png"))
    print("  item_companion.png (green paw print)")


# ═══════════════════════════════════════════════════════════════
# GALLERY — all icons side by side for preview
# ═══════════════════════════════════════════════════════════════
def draw_gallery():
    names = ["item_potion.png", "item_weapon.png", "item_accessory.png",
             "item_parts.png", "item_companion.png", "orb.png"]
    labels = ["POTION", "WEAPON", "ACCESSORY", "PARTS", "ALLY", "ORB"]
    gap = 4
    icon_w = SIZE
    total_w = len(names) * icon_w + (len(names) - 1) * gap
    gallery_h = SIZE + 24  # space for labels below

    gallery = Image.new("RGBA", (total_w, gallery_h), (30, 30, 35, 255))

    for i, name in enumerate(names):
        path = os.path.join(OUT, name)
        icon = Image.open(path).convert("RGBA")
        x_off = i * (icon_w + gap)
        gallery.paste(icon, (x_off, 0), icon)

        # Label text (simple pixel font simulation)
        lbl = labels[i]
        lx = x_off + icon_w // 2 - len(lbl) * 3  # rough center
        for ci, ch in enumerate(lbl):
            # Tiny dot-matrix letters — just use PIL text
            pass

    from PIL import ImageFont, ImageDraw as ID
    d = ID.Draw(gallery)
    try:
        font = ImageFont.truetype("arial.ttf", 10)
    except:
        font = ImageFont.load_default()

    for i, lbl in enumerate(labels):
        x_off = i * (icon_w + gap)
        bbox = d.textbbox((0, 0), lbl, font=font)
        tw = bbox[2] - bbox[0]
        d.text((x_off + icon_w // 2 - tw // 2, SIZE + 6), lbl,
               fill=C_WHITE, font=font)

    gallery.save(os.path.join(OUT, "_drops_gallery.png"))
    print("  _drops_gallery.png (all icons preview)")


if __name__ == "__main__":
    print("Generating drop item icons...")
    os.makedirs(OUT, exist_ok=True)
    draw_potion()
    draw_weapon()
    draw_accessory()
    draw_parts()
    draw_orb()
    draw_rarity_ring()
    draw_companion()
    draw_gallery()
    print("Done! %d icons generated." % 7)
