"""Generate 6 distinct pixel-art character portrait avatars for mini_zambie.

Each portrait is a 64x64 bust drawn at a low base resolution and upscaled x2
with NEAREST (128x128 output) so it stays crisp pixel art. The runtime reads
these via PixelLoader (CanvasTexture, nearest). Style matches the existing
assets/pixel set: flat fills, bold dark outlines, blocky shapes.

Output: assets/pixel/portrait_<id>.png  (id = veteran, alien_shooter, ...)
"""
import os
from PIL import Image

OUT = "D:/MyCode/github/mini_zambie/assets/pixel"


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
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                put(img, x, y, c)


def ellipse(img, cx, cy, rx, ry, c):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            if ((x - cx) ** 2) / (rx * rx) + ((y - cy) ** 2) / (ry * ry) <= 1.0:
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


def rect_outline(img, x0, y0, x1, y1, c):
    for x in range(int(x0), int(x1) + 1):
        put(img, x, y0, c)
        put(img, x, y1, c)
    for y in range(int(y0), int(y1) + 1):
        put(img, x0, y, c)
        put(img, x1, y, c)


def outline(img, col):
    src = img.copy()
    for y in range(src.height):
        for x in range(src.width):
            if src.getpixel((x, y))[3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < src.width and 0 <= ny < src.height:
                        if src.getpixel((nx, ny))[3] > 0:
                            put(img, x, y, col)
                            break


def bg_gradient(img, top, bottom):
    for y in range(img.height):
        t = y / img.height
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        fill(img, 0, y, img.width - 1, y, (r, g, b, 255))


def save(img, name, scale=2):
    if scale > 1:
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    img.save(os.path.join(OUT, name))
    print("wrote", name, img.size)


# ---------- shared bust pieces ----------
def shoulders(img, color, collar):
    # simple trapezoid shoulders across the bottom
    fill(img, 8, 50, 55, 63, color)
    fill(img, 14, 46, 49, 51, color)
    fill(img, 22, 44, 41, 47, color)
    # collar V
    fill(img, 28, 44, 35, 46, collar)
    fill(img, 29, 45, 34, 47, collar)


def neck(img, skin):
    fill(img, 28, 38, 35, 45, skin)


def eye(img, x, y, skin_shadow):
    fill(img, x, y, x + 2, y + 2, (245, 245, 250, 255))   # white
    put(img, x + 1, y + 1, (30, 30, 40, 255))             # pupil
    fill(img, x - 1, y, x + 3, y, skin_shadow)            # brow ridge


# ---------- character: veteran (grizzled human soldier) ----------
def portrait_veteran():
    img = new(64, 64)
    bg_gradient(img, (46, 52, 40), (18, 22, 16))
    shoulders(img, (78, 86, 60), (54, 62, 40))
    neck(img, (206, 168, 132))
    ellipse(img, 32, 25, 12, 14, (214, 176, 138))          # head
    disc(img, 32, 38, 9, (206, 168, 132))                  # jaw
    # military helmet
    fill(img, 19, 12, 45, 18, (72, 84, 54))
    fill(img, 20, 10, 44, 13, (84, 96, 64))
    fill(img, 17, 17, 47, 19, (60, 70, 44))                # brim
    # gray short hair at sides
    fill(img, 20, 16, 23, 22, (150, 152, 160))
    fill(img, 41, 16, 44, 22, (150, 152, 160))
    # brows + eyes
    eye(img, 26, 24, (180, 150, 118))
    eye(img, 36, 24, (180, 150, 118))
    put(img, 30, 23, (90, 80, 70)); put(img, 31, 23, (90, 80, 70))
    put(img, 33, 23, (90, 80, 70)); put(img, 34, 23, (90, 80, 70))
    # nose
    fill(img, 31, 28, 32, 31, (190, 152, 116))
    # stubble
    for (x, y) in [(26, 33), (29, 35), (32, 35), (35, 35), (38, 33), (28, 34), (34, 34)]:
        put(img, x, y, (176, 150, 120))
    # scar
    line(img, 38, 27, 40, 33, (200, 130, 130))
    outline(img, (16, 18, 12, 255))
    rect_outline(img, 1, 1, 62, 62, (120, 130, 96, 255))
    save(img, "portrait_veteran.png")


# ---------- character: alien_shooter (octopus alien) ----------
def portrait_alien_shooter():
    img = new(64, 64)
    bg_gradient(img, (66, 32, 74), (26, 12, 34))
    # tentacle shoulders (4 short tentacles)
    for tx in (12, 22, 42, 52):
        disc(img, tx, 50, 6, (150, 84, 188))
        fill(img, tx - 4, 50, tx + 4, 56, (150, 84, 188))
        put(img, tx - 2, 53, (220, 160, 240)); put(img, tx + 2, 53, (220, 160, 240))
    fill(img, 18, 46, 46, 50, (150, 84, 188))
    # bulbous head
    ellipse(img, 32, 26, 14, 15, (168, 96, 206))
    disc(img, 32, 30, 11, (176, 104, 214))
    # big alien eyes
    ellipse(img, 25, 25, 5, 6, (240, 240, 250, 255))
    ellipse(img, 39, 25, 5, 6, (240, 240, 250, 255))
    put(img, 25, 26, (30, 20, 50, 255)); put(img, 39, 26, (30, 20, 50, 255))
    put(img, 26, 24, (180, 200, 255, 255)); put(img, 40, 24, (180, 200, 255, 255))
    # small mouth
    fill(img, 29, 36, 35, 37, (120, 60, 150))
    # cyan spots
    for (x, y) in [(22, 18), (42, 18), (30, 14), (34, 14)]:
        put(img, x, y, (90, 220, 230))
    outline(img, (40, 16, 52, 255))
    rect_outline(img, 1, 1, 62, 62, (150, 90, 200, 255))
    save(img, "portrait_alien_shooter.png")


# ---------- character: professor (older human, glasses, lab coat) ----------
def portrait_professor():
    img = new(64, 64)
    bg_gradient(img, (40, 46, 60), (18, 22, 32))
    shoulders(img, (232, 234, 240), (180, 150, 170))     # lab coat + tie
    fill(img, 30, 44, 33, 52, (170, 70, 90))              # tie
    neck(img, (202, 162, 132))
    ellipse(img, 32, 25, 12, 14, (206, 166, 134))         # head
    disc(img, 32, 38, 9, (202, 162, 132))
    # bald with white side fringe
    fill(img, 21, 14, 26, 20, (232, 232, 238))
    fill(img, 38, 14, 43, 20, (232, 232, 238))
    fill(img, 24, 11, 40, 14, (236, 236, 242))
    # brows (gray) + eyes
    eye(img, 25, 25, (180, 140, 110))
    eye(img, 36, 25, (180, 140, 110))
    put(img, 29, 24, (160, 160, 165)); put(img, 33, 24, (160, 160, 165))
    # glasses
    ellipse(img, 26, 26, 5, 4, (60, 200, 230, 120))       # lens tint
    ellipse(img, 38, 26, 5, 4, (60, 200, 230, 120))
    rect_outline(img, 21, 22, 31, 30, (40, 40, 52, 255))  # left frame
    rect_outline(img, 33, 22, 43, 30, (40, 40, 52, 255))  # right frame
    line(img, 31, 26, 33, 26, (40, 40, 52, 255))          # bridge
    # nose + mustache + mouth
    fill(img, 31, 29, 32, 32, (186, 146, 114))
    fill(img, 27, 34, 37, 35, (200, 200, 205))            # mustache
    fill(img, 28, 37, 36, 38, (170, 120, 100))
    outline(img, (30, 26, 22, 255))
    rect_outline(img, 1, 1, 62, 62, (120, 150, 200, 255))
    save(img, "portrait_professor.png")


# ---------- character: mech_monk (half machine monk) ----------
def portrait_mech_monk():
    img = new(64, 64)
    bg_gradient(img, (36, 42, 50), (16, 20, 26))
    shoulders(img, (96, 78, 120), (70, 56, 92))           # robe
    # prayer beads
    for x in range(26, 39):
        if (x // 2) % 2 == 0:
            put(img, x, 45, (210, 175, 95, 255))
    neck(img, (208, 168, 138))
    ellipse(img, 32, 25, 12, 14, (210, 170, 140))         # head
    disc(img, 32, 38, 9, (208, 168, 138))
    # left half metal plate (x < 32)
    fill(img, 20, 16, 31, 39, (135, 146, 160))
    fill(img, 20, 16, 31, 18, (160, 172, 186))            # top sheen
    line(img, 31, 18, 31, 39, (95, 105, 118))             # seam
    fill(img, 22, 30, 29, 33, (110, 120, 134))            # panel
    # bald tonsure (right side skin shows, top skin)
    disc(img, 32, 14, 8, (210, 170, 140))
    fill(img, 32, 8, 36, 12, (210, 170, 140))
    # right eye normal, left eye glowing
    fill(img, 35, 25, 37, 27, (245, 245, 250, 255)); put(img, 36, 26, (30, 30, 40, 255))
    put(img, 34, 24, (150, 110, 80))
    disc(img, 26, 26, 3, (80, 225, 235, 255))             # glowing cyber eye
    put(img, 26, 26, (200, 255, 255, 255))
    # circuit line on temple
    line(img, 22, 20, 30, 20, (80, 225, 235, 255))
    line(img, 22, 20, 22, 24, (80, 225, 235, 255))
    # nose + mouth
    fill(img, 31, 29, 32, 32, (188, 150, 120))
    fill(img, 28, 37, 36, 38, (150, 110, 90))
    outline(img, (24, 24, 30, 255))
    rect_outline(img, 1, 1, 62, 62, (140, 200, 220, 255))
    save(img, "portrait_mech_monk.png")


# ---------- character: cat_cafe_worker (cat ears) ----------
def portrait_cat_cafe_worker():
    img = new(64, 64)
    bg_gradient(img, (60, 42, 54), (30, 18, 30))
    shoulders(img, (220, 168, 138), (190, 130, 110))      # apron/uniform
    neck(img, (230, 190, 160))
    ellipse(img, 32, 25, 12, 14, (232, 192, 162))         # head
    disc(img, 32, 38, 9, (230, 190, 160))
    # orange hair
    fill(img, 20, 14, 44, 22, (226, 142, 74))
    fill(img, 22, 12, 42, 15, (240, 160, 90))
    # cat ears
    fill(img, 19, 8, 26, 16, (228, 146, 80)); fill(img, 21, 11, 24, 15, (242, 180, 192))  # L ear
    fill(img, 38, 8, 45, 16, (228, 146, 80)); fill(img, 40, 11, 43, 15, (242, 180, 192))  # R ear
    # eyes (big, friendly, shine)
    ellipse(img, 26, 26, 4, 5, (60, 50, 80, 255))
    ellipse(img, 38, 26, 4, 5, (60, 50, 80, 255))
    put(img, 27, 24, (200, 200, 220, 255)); put(img, 39, 24, (200, 200, 220, 255))
    # nose + :3 mouth
    fill(img, 31, 30, 32, 31, (200, 120, 120))
    line(img, 32, 31, 29, 33, (150, 90, 90)); line(img, 32, 31, 35, 33, (150, 90, 90))
    # blush
    fill(img, 22, 31, 25, 33, (235, 150, 150)); fill(img, 39, 31, 42, 33, (235, 150, 150))
    outline(img, (40, 26, 20, 255))
    rect_outline(img, 1, 1, 62, 62, (240, 160, 110, 255))
    save(img, "portrait_cat_cafe_worker.png")


# ---------- character: cyber_cultivator (daoist + cyber) ----------
def portrait_cyber_cultivator():
    img = new(64, 64)
    bg_gradient(img, (26, 50, 42), (12, 22, 20))
    shoulders(img, (70, 150, 120), (50, 110, 90))         # jade robe
    fill(img, 29, 44, 34, 52, (200, 70, 70))              # red sash
    neck(img, (218, 178, 148))
    ellipse(img, 32, 25, 12, 14, (220, 180, 150))         # head
    disc(img, 32, 38, 9, (218, 178, 148))
    # black hair + topknot (发髻)
    fill(img, 20, 14, 44, 20, (42, 40, 56))
    fill(img, 22, 11, 42, 14, (54, 50, 70))
    disc(img, 32, 8, 5, (42, 40, 56))                     # bun
    put(img, 32, 4, (200, 60, 60))                        # pin
    # eyes + cyber visor line
    eye(img, 25, 25, (190, 150, 120))
    eye(img, 36, 25, (190, 150, 120))
    fill(img, 34, 24, 41, 26, (60, 220, 150, 200))        # neon visor over right eye
    put(img, 37, 25, (180, 255, 210, 255))
    # neon circuit on cheek
    line(img, 23, 28, 30, 28, (60, 220, 150, 255))
    line(img, 23, 28, 23, 33, (60, 220, 150, 255))
    # forehead mark
    put(img, 32, 19, (200, 60, 60)); put(img, 31, 20, (200, 60, 60)); put(img, 33, 20, (200, 60, 60))
    # nose + small goatee
    fill(img, 31, 29, 32, 32, (198, 158, 128))
    fill(img, 30, 37, 34, 39, (60, 55, 75))
    outline(img, (20, 22, 18, 255))
    rect_outline(img, 1, 1, 62, 62, (80, 220, 150, 255))
    save(img, "portrait_cyber_cultivator.png")


# ---------- contact sheet (for visual verification) ----------
def contact_sheet():
    ids = ["veteran", "alien_shooter", "professor", "mech_monk", "cat_cafe_worker", "cyber_cultivator"]
    sheet = new(64 * 6, 64)
    for i, cid in enumerate(ids):
        im = Image.open(os.path.join(OUT, "portrait_%s.png" % cid)).convert("RGBA")
        sheet.paste(im, (i * 64, 0))
    sheet = sheet.resize((64 * 6 * 2, 64 * 2), Image.NEAREST)
    sheet.save(os.path.join(OUT, "_contact_sheet.png"))
    print("wrote _contact_sheet.png")


if __name__ == "__main__":
    portrait_veteran()
    portrait_alien_shooter()
    portrait_professor()
    portrait_mech_monk()
    portrait_cat_cafe_worker()
    portrait_cyber_cultivator()
    contact_sheet()
    print("DONE")
