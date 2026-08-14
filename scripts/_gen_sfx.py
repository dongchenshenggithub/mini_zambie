"""Generate synthesized SFX WAV files for mini_zambie.

Produces short, punchy one-shot sound effects using NumPy synthesis.
Each sound is designed to read clearly in a busy game mix.

Output: assets/sfx/{hit, player_hurt, shoot, enemy_die, explosion, swing, reload, pickup, levelup}.wav
"""
import os, struct, math, random

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")
os.makedirs(OUT, exist_ok=True)

SAMPLE_RATE = 22050


def normalize(samples):
    """Peak-normalize to [-1, 1]."""
    mx = max(abs(x) for x in samples) if samples else 1.0
    if mx < 0.001:
        mx = 0.001
    return [x / mx for x in samples]


def envelope(length_ms, attack_ms=2, decay_ms=40, sustain=0.7, release_ms=10):
    """ADSR-like envelope (simplified AR for one-shots)."""
    n = int(length_ms * SAMPLE_RATE / 1000)
    att = int(attack_ms * SAMPLE_RATE / 1000)
    rel = int(release_ms * SAMPLE_RATE / 1000)
    env = []
    for i in range(n):
        if i < att:
            env.append(i / max(att, 1))
        elif i > n - rel:
            env.append((n - i) / max(rel, 1))
        else:
            env.append(sustain)
    # Smooth decay from sustain to release start
    decay_start = att
    decay_end = n - rel
    if decay_end > decay_start:
        for i in range(decay_start, decay_end):
            t = (i - decay_start) / max(decay_end - decay_start, 1)
            env[i] *= (1.0 - t * (1.0 - sustain * 0.3))
    return env


def sine_wave(freq, duration_ms, volume=1.0, phase=0):
    n = int(duration_ms * SAMPLE_RATE / 1000)
    return [volume * math.sin(2 * math.pi * freq * i / SAMPLE_RATE + phase) for i in range(n)]


def noise(duration_ms, volume=1.0, color='white'):
    n = int(duration_ms * SAMPLE_RATE / 1000)
    if color == 'white':
        return [volume * (random.random() * 2 - 1) for _ in range(n)]
    else:  # pink-ish approximation
        out = [0.0] * n
        b = [0.0] * 7
        for i in range(n):
            w = random.random() * 2 - 1
            b[0] = 0.99886 * b[0] + w
            b[1] = 0.99332 * b[1] + w
            b[2] = 0.96900 * b[2] + w
            b[3] = 0.86650 * b[3] + w
            b[4] = 0.55000 * b[4] + w
            b[5] = -0.7616 * b[5] + w
            out[i] = volume * (b[0] + b[1] + b[2] + b[3] + b[4] + b[5]) / 6.0
        return out


def write_wav(path, samples, sample_rate=SAMPLE_RATE):
    """Write raw float samples as 16-bit PCM WAV."""
    samples = normalize(samples)
    # Convert to 16-bit integers
    data = struct.pack('<' + 'h' * len(samples), *[int(max(-32768, min(32767, s * 30000))) for s in samples])
    with open(path, 'wb') as f:
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + len(data)))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<IHHIIH', 16, 1, sample_rate, sample_rate * 2, 2, 16))
        f.write(b'data')
        f.write(struct.pack('<I', len(data)))
        f.write(data)


# ========== SFX DEFINITIONS ==========

def make_hit():
    """Bullet/projectile hitting enemy — quick thud + click."""
    dur = 120  # ms
    env = envelope(dur, attack_ms=1, decay_ms=60, sustain=0.5, release_ms=30)

    # Low thud (impact body)
    thud = sine_wave(80, dur, volume=0.8)
    # Mid crack (bone/hit)
    crack = sine_wave(400, dur, volume=0.4)
    # High click (surface)
    click = sine_wave(1200, dur, volume=0.2)
    # Noise burst for texture
    n = noise(dur, volume=0.15)

    samples = []
    for i in range(len(env)):
        s = thud[i] * 0.6 + crack[i] * 0.3 + click[i] * 0.15 + n[i]
        samples.append(s * env[i])
    return samples


def make_player_hurt():
    """Player taking damage — sharp, painful sting."""
    dur = 180
    env = envelope(dur, attack_ms=1, decay_ms=80, sustain=0.4, release_ms=40)

    # Sharp high-frequency stab
    stab = sine_wave(800, dur, volume=0.7)
    # Mid pain tone
    pain = sine_wave(350, dur, volume=0.5)
    # Quick descending sweep (grunt feel)
    sweep = []
    n_samples = int(dur * SAMPLE_RATE / 1000)
    for i in range(n_samples):
        t = i / n_samples
        freq = 500 * (1.0 - t * 0.6)  # 500 -> 200 Hz sweep
        sweep.append(math.sin(2 * math.pi * freq * i / SAMPLE_RATE) * 0.4)
    # Noise grit
    n = noise(dur, volume=0.1)

    samples = []
    for i in range(len(env)):
        s = stab[i] * 0.5 + pain[i] * 0.3 + sweep[i] * 0.3 + n[i]
        samples.append(s * env[i])
    return samples


def make_shoot():
    """Weapon firing — pop + bass thud."""
    dur = 100
    env = envelope(dur, attack_ms=0, decay_ms=50, sustain=0.6, release_ms=20)

    pop = sine_wave(150, dur, volume=0.9)
    thud = sine_wave(60, dur, volume=0.7)
    n = noise(dur, volume=0.25)
    # Click harmonics
    click = sine_wave(800, 30, volume=0.3)
    # Pad click to full length
    click += [0.0] * (len(pop) - len(click))

    samples = []
    for i in range(len(env)):
        s = pop[i] * 0.5 + thud[i] * 0.35 + n[i] + click[i] * 0.2
        samples.append(s * env[i])
    return samples


def make_enemy_die():
    """Enemy death — wet splat + gurgle downward slide."""
    dur = 300
    env = envelope(dur, attack_ms=2, decay_ms=120, sustain=0.5, release_ms=80)

    n_samples = int(dur * SAMPLE_RATE / 1000)
    # Downward pitch slide (death rattle)
    slide = []
    for i in range(n_samples):
        t = i / n_samples
        freq = 200 * (1.0 - t * 0.7)  # 200 -> 60 Hz
        slide.append(math.sin(2 * math.pi * freq * i / SAMPLE_RATE) * 0.5)
    # Squelch / wet sound
    squelch = noise(dur, volume=0.25, color='pink')
    # Low rumble
    rumble = sine_wave(50, dur, volume=0.4)

    samples = []
    for i in range(len(env)):
        s = slide[i] + squelch[i] * 0.4 + rumble[i] * 0.3
        samples.append(s * env[i])
    return samples


def make_explosion():
    """Explosion — big boom + debris rattling."""
    dur = 400
    env = envelope(dur, attack_ms=3, decay_ms=200, sustain=0.4, release_ms=100)

    # Sub-bass boom
    boom = sine_wave(40, dur, volume=1.0)
    # Mid crack
    crack = sine_wave(120, dur, volume=0.5)
    # Lots of noise
    n = noise(dur, volume=0.5)
    # Debris rattling (high-freq noise tail)
    debris = noise(dur, volume=0.2)

    samples = []
    for i in range(len(env)):
        # Debris fades in slower
        debris_vol = min(1.0, i / (len(env) * 0.3)) * 0.3
        s = boom[i] * 0.5 + crack[i] * 0.25 + n[i] * 0.4 + debris[i] * debris_vol
        samples.append(s * env[i])
    return samples


def make_swing():
    """Melee weapon swing — whoosh."""
    dur = 150
    env = envelope(dur, attack_ms=5, decay_ms=80, sustain=0.5, release_ms=30)

    n_samples = int(dur * SAMPLE_RATE / 1000)
    # Rising then falling noise (whoosh shape)
    whoosh = noise(dur, volume=0.6)
    # Pitch-modulated sine for body
    body = []
    for i in range(n_samples):
        t = i / n_samples
        # Rise quickly then fall
        if t < 0.3:
            freq = 200 + t * 600
        else:
            freq = 380 - (t - 0.3) * 400
        body.append(math.sin(2 * math.pi * freq * i / SAMPLE_RATE) * 0.5)

    samples = []
    for i in range(len(env)):
        s = body[i] + whoosh[i] * 0.5
        samples.append(s * env[i])
    return samples


def make_reload():
    """Reload — mechanical click-clack (light rifle/SMG)."""
    dur = 200
    # Two distinct clicks
    click1 = sine_wave(1000, 20, volume=0.8)
    silence1 = [0.0] * int(80 * SAMPLE_RATE / 1000)
    click2 = sine_wave(800, 25, volume=0.7)
    silence2 = [0.0] * int(75 * SAMPLE_RATE / 1000)
    # Metal clack
    clack = sine_wave(400, 30, volume=0.5)
    pad = [0.0] * (int(dur * SAMPLE_RATE / 1000) - len(click1) - len(silence1) - len(click2) - len(silence2) - len(clack))

    samples = click1 + silence1 + click2 + silence2 + clack + pad
    return samples


def make_reload_shotgun():
    """Shotgun reload — pump-action thunk + shell insert + close."""
    dur = 350
    # Deep pump thunk
    pump = sine_wave(90, 40, volume=1.0)
    pump += [0.0] * int(60 * SAMPLE_RATE / 1000)
    # Shell insert (metallic scrape + click)
    scrape = noise(50, volume=0.25)
    shell_click = sine_wave(600, 15, volume=0.5)
    scrape += [0.0] * int(30 * SAMPLE_RATE / 1000)
    # Close action (heavier thunk)
    close = sine_wave(70, 45, volume=0.9)
    pad = [0.0] * (int(dur * SAMPLE_RATE / 1000) - len(pump) - len(scrape) - len(shell_click) - len(close))

    samples = pump + scrape + shell_click + close + pad
    return samples


def make_reload_heavy():
    """Heavy weapon reload (RPG) — magazine slam + mechanical lock."""
    dur = 400
    # Heavy mag drop (sub-bass thud)
    drop = sine_wave(45, 60, volume=1.0)
    drop += noise(40, volume=0.2)
    drop += [0.0] * int(80 * SAMPLE_RATE / 1000)
    # Lock engagement (metallic chunk)
    lock = sine_wave(200, 35, volume=0.7)
    lock += sine_wave(350, 20, volume=0.4)
    lock += [0.0] * int(90 * SAMPLE_RATE / 1000)
    # Final seat (solid thud)
    seat = sine_wave(55, 50, volume=0.85)
    pad = [0.0] * (int(dur * SAMPLE_RATE / 1000) - len(drop) - len(lock) - len(seat))

    samples = drop + lock + seat + pad
    return samples


def make_reload_laser():
    """Laser/energy weapon reload — rising charge hum + peak discharge."""
    dur = 500
    n_samples = int(dur * SAMPLE_RATE / 1000)
    # Rising charge hum (frequency sweeps up)
    charge = []
    for i in range(n_samples):
        t = i / n_samples
        # Frequency rises from 200Hz to 1200Hz over first 70% of duration
        if t < 0.7:
            freq = 200.0 + t * (1200.0 - 200.0) / 0.7
            vol = 0.3 + t * 0.4  # volume rises with charge
        else:
            freq = 1200.0 - (t - 0.7) * 1500.0  # rapid sweep down after peak
            vol = 0.7 * (1.0 - (t - 0.7) / 0.3)  # fade out
        charge.append(math.sin(2 * math.pi * freq * i / SAMPLE_RATE) * max(0.0, vol))
    # Add a bright peak "ding" at 75%
    ding_start = int(n_samples * 0.72)
    ding_dur = int(60 * SAMPLE_RATE / 1000)
    for i in range(ding_start, min(ding_start + ding_dur, n_samples)):
        t = (i - ding_start) / max(ding_dur, 1)
        fade = math.sin(t * math.pi)
        charge[i] += fade * 0.5 * math.sin(2 * math.pi * 2400 * i / SAMPLE_RATE)

    # Envelope: quick attack, sustain, smooth release
    env = envelope(dur, attack_ms=10, decay_ms=dur*0.6, sustain=0.6, release_ms=80)
    samples = []
    for i in range(min(len(env), len(charge))):
        samples.append(charge[i] * env[i])
    return samples


def make_pickup():
    """Item pickup — bright ascending chime."""
    dur = 200
    env = envelope(dur, attack_ms=3, decay_ms=100, sustain=0.6, release_ms=40)

    n_samples = int(dur * SAMPLE_RATE / 1000)
    # Ascending arpeggio
    notes = [523, 659, 784, 1047]  # C5, E5, G5, C6
    chord = [0.0] * n_samples
    for idx, freq in enumerate(notes):
        start = int(idx * n_samples * 0.15)
        vol = 0.5 - idx * 0.1
        for i in range(start, n_samples):
            t = (i - start) / (n_samples - start)
            fade = max(0, 1.0 - t * 2)
            chord[i] += vol * fade * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)

    samples = []
    for i in range(min(len(env), len(chord))):
        samples.append(chord[i] * env[i])
    return samples


def make_levelup():
    """Level up — triumphant fanfare chirp."""
    dur = 350
    env = envelope(dur, attack_ms=5, decay_ms=150, sustain=0.5, release_ms=80)

    n_samples = int(dur * SAMPLE_RATE / 1000)
    # Triumphant ascending melody
    melody = [
        (523, 0.0, 0.12),   # C5
        (659, 0.08, 0.12),  # E5
        (784, 0.16, 0.12),  # G5
        (1047, 0.24, 0.18), # C6 (held longer)
    ]
    wave = [0.0] * n_samples
    for freq, start_t, dur_t in melody:
        si = int(start_t * n_samples)
        ei = int((start_t + dur_t) * n_samples)
        vol = 0.5
        for i in range(si, min(ei, n_samples)):
            t = (i - si) / max(ei - si, 1)
            fade = math.sin(t * math.pi)  # smooth envelope per note
            wave[i] += vol * fade * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
    # Sparkle overlay (high freq quiet tones)
    for i in range(n_samples):
        t = i / n_samples
        if t > 0.3:
            wave[i] += 0.1 * math.sin(2 * math.pi * 2093 * i / SAMPLE_RATE) * (1.0 - (t - 0.3) / 0.7)

    samples = []
    for i in range(min(len(env), len(wave))):
        samples.append(wave[i] * env[i])
    return samples


# ========== MAIN ==========
SFX_DEFS = [
    ("hit", make_hit, "Enemy hit impact"),
    ("player_hurt", make_player_hurt, "Player hurt/pain"),
    ("shoot", make_shoot, "Weapon fire"),
    ("enemy_die", make_enemy_die, "Enemy death"),
    ("explosion", make_explosion, "Explosion"),
    ("swing", make_swing, "Melee swing"),
    ("reload", make_reload, "Reload (light rifle/SMG)"),
    ("reload_shotgun", make_reload_shotgun, "Reload (shotgun pump)"),
    ("reload_heavy", make_reload_heavy, "Reload (RPG/heavy mag)"),
    ("reload_laser", make_reload_laser, "Reload (laser/energy charge)"),
    ("pickup", make_pickup, "Item pickup"),
    ("levelup", make_levelup, "Level up fanfare"),
]


def main():
    random.seed(42)
    for name, fn, desc in SFX_DEFS:
        path = os.path.join(OUT, f"{name}.wav")
        samples = fn()
        write_wav(path, samples)
        size_kb = os.path.getsize(path) / 1024
        print(f"  {name}.wav  ({len(samples)/SAMPLE_RATE*1000:.0f}ms, {size_kb:.1f}KB) — {desc}")
    print("Done.")


if __name__ == "__main__":
    main()
