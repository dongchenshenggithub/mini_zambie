# Generate small retro SFX WAVs (16-bit PCM mono, 44100 Hz) for the game.
# Pure stdlib (wave + math) so it runs in the managed Python venv.
import math, os, struct, wave

SR = 44100

def write_wav(path, samples):
    # samples: list of float in [-1, 1]
    n = len(samples)
    frames = bytearray()
    for s in samples:
        v = max(-1.0, min(1.0, s))
        frames += struct.pack("<h", int(v * 32767))
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))
    print("WROTE", path, n)

def env(n, attack=0.005, release=0.05):
    out = []
    for i in range(n):
        t = i / SR
        if t < attack:
            a = t / attack
        else:
            a = 1.0
        # exponential-ish decay after attack
        dec = math.exp(-(t - attack) / max(release, 1e-3)) if t > attack else 1.0
        out.append(a * dec)
    return out

def tone(n, f0, f1=None, kind="sine", gain=0.5):
    out = []
    for i in range(n):
        t = i / SR
        f = f0 if f1 is None else f0 + (f1 - f0) * (i / n)
        ph = 2 * math.pi * f * t
        if kind == "sine":
            s = math.sin(ph)
        elif kind == "square":
            s = 1.0 if math.sin(ph) >= 0 else -1.0
        elif kind == "saw":
            s = 2.0 * (f * t - math.floor(0.5 + f * t))
        else:
            s = math.sin(ph)
        out.append(s * gain)
    return out

def noise(n, gain=0.5):
    out = []
    for i in range(n):
        out.append((((i * 1103515245 + 12345) % 65536) / 32768.0 - 0.5) * 2.0 * gain)
    return out

def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i in range(len(t)):
            out[i] += t[i]
    # soft clip
    for i in range(n):
        out[i] = math.tanh(out[i])
    return out

def apply_env(samples, e):
    return [s * e[i] if i < len(e) else s for i, s in enumerate(samples)]

OUT = "assets/sfx"
os.makedirs(OUT, exist_ok=True)

# shoot: descending zap
shoot = apply_env(mix(tone(int(0.12 * SR), 900, 280, "square", 0.5),
                       tone(int(0.12 * SR), 1400, 500, "sine", 0.25)),
                  env(int(0.12 * SR), 0.002, 0.05))
write_wav(os.path.join(OUT, "shoot.wav"), shoot)

# hit: noise burst + low thump
hit = apply_env(mix(noise(int(0.10 * SR), 0.6),
                     tone(int(0.10 * SR), 160, 90, "sine", 0.5)),
               env(int(0.10 * SR), 0.001, 0.04))
write_wav(os.path.join(OUT, "hit.wav"), hit)

# enemy_die: crunchy downward noise sweep
ed = apply_env(mix(noise(int(0.26 * SR), 0.55),
                    tone(int(0.26 * SR), 420, 70, "saw", 0.3)),
              env(int(0.26 * SR), 0.002, 0.12))
write_wav(os.path.join(OUT, "enemy_die.wav"), ed)

# pickup: two rising pleasant blips
pk = []
pk += apply_env(tone(int(0.08 * SR), 660, 660, "sine", 0.4), env(int(0.08 * SR), 0.005, 0.05))
pk += apply_env(tone(int(0.10 * SR), 990, 990, "sine", 0.4), env(int(0.10 * SR), 0.005, 0.06))
write_wav(os.path.join(OUT, "pickup.wav"), pk)

# levelup: C-E-G-C arpeggio
notes = [523.25, 659.25, 783.99, 1046.5]
lu = []
for f in notes:
    lu += apply_env(tone(int(0.11 * SR), f, f, "sine", 0.4), env(int(0.11 * SR), 0.005, 0.06))
write_wav(os.path.join(OUT, "levelup.wav"), lu)

# player_hurt: harsh low square
ph = apply_env(tone(int(0.16 * SR), 200, 110, "square", 0.5),
               env(int(0.16 * SR), 0.002, 0.08))
write_wav(os.path.join(OUT, "player_hurt.wav"), ph)

# swing: short filtered whoosh (noise with bandpass-ish via two tones)
sw = apply_env(mix(noise(int(0.12 * SR), 0.4),
                    tone(int(0.12 * SR), 700, 300, "sine", 0.2)),
               env(int(0.12 * SR), 0.01, 0.05))
write_wav(os.path.join(OUT, "swing.wav"), sw)

# explosion: big low rumble + noise
ex = apply_env(mix(noise(int(0.5 * SR), 0.6),
                    tone(int(0.5 * SR), 90, 40, "sine", 0.6)),
               env(int(0.5 * SR), 0.004, 0.25))
write_wav(os.path.join(OUT, "explosion.wav"), ex)

print("DONE")
