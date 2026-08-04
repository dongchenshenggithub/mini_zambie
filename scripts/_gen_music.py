#!/usr/bin/env python3
"""Generate chiptune music loops for mini_zambie (pixel zombie roguelike).

Outputs 16-bit mono WAV into assets/music/. Pure stdlib (wave/math/random),
no third-party deps. Tracks: menu, gameplay, boss, victory, death.
"""
import os, math, random, wave, struct

SR = 44100
OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "music"))


def midi_to_freq(m: int) -> float:
    return 440.0 * (2.0 ** ((m - 69) / 12.0))


def osc(wave: str, phase: float) -> float:
    p = phase - math.floor(phase)
    if wave == "square":
        return 1.0 if p < 0.5 else -1.0
    if wave == "triangle":
        return 4.0 * abs(p - 0.5) - 1.0
    if wave == "saw":
        return 2.0 * p - 1.0
    if wave == "sine":
        return math.sin(2.0 * math.pi * p)
    if wave == "noise":
        return random.uniform(-1.0, 1.0)
    return 0.0


class Track:
    def __init__(self):
        self.events = []

    def note(self, start, dur, midi, wave="square", vol=0.3, attack=0.005, release=0.06, detune=0.0):
        self.events.append(("note", start, dur, midi, wave, vol, attack, release, detune))

    def kick(self, start, vol=0.8):
        self.events.append(("kick", start, vol))

    def snare(self, start, vol=0.5):
        self.events.append(("snare", start, vol))

    def hat(self, start, vol=0.22):
        self.events.append(("hat", start, vol))

    def render(self, length: float):
        n = int(length * SR)
        buf = [0.0] * n
        for ev in self.events:
            if ev[0] == "note":
                _, start, dur, midi, wave, vol, attack, release, detune = ev
                f = midi_to_freq(midi) * (2.0 ** (detune / 12.0))
                s0 = int(start * SR)
                s1 = int((start + dur) * SR)
                if s1 <= 0:
                    continue
                rel_start = dur - release
                for i in range(s0, min(s1, n)):
                    t = (i - s0) / SR
                    a = (t / attack) if (t < attack and attack > 0) else 1.0
                    if t > rel_start:
                        a *= max(0.0, (dur - t) / release) if release > 0 else 0.0
                    ph = (i - s0) / SR * f
                    buf[i] += osc(wave, ph) * vol * a
            elif ev[0] == "kick":
                _, start, vol = ev
                s0 = int(start * SR)
                dur = 0.18
                s1 = s0 + int(dur * SR)
                for i in range(s0, min(s1, n)):
                    t = (i - s0) / SR
                    f = 50 + 95 * math.exp(-t * 30)
                    env = math.exp(-t * 16)
                    buf[i] += math.sin(2.0 * math.pi * f * t) * vol * env
            elif ev[0] == "snare":
                _, start, vol = ev
                s0 = int(start * SR)
                dur = 0.16
                s1 = s0 + int(dur * SR)
                for i in range(s0, min(s1, n)):
                    t = (i - s0) / SR
                    env = math.exp(-t * 22)
                    buf[i] += (random.uniform(-1.0, 1.0) * 0.7 + math.sin(2.0 * math.pi * 180 * t) * 0.3) * vol * env
            elif ev[0] == "hat":
                _, start, vol = ev
                s0 = int(start * SR)
                dur = 0.05
                s1 = s0 + int(dur * SR)
                for i in range(s0, min(s1, n)):
                    t = (i - s0) / SR
                    env = math.exp(-t * 90)
                    buf[i] += random.uniform(-1.0, 1.0) * vol * env
        peak = max(1e-6, max(abs(x) for x in buf))
        norm = 0.85 / peak
        out = []
        for x in buf:
            x = math.tanh(x * norm * 1.3)
            out.append(int(max(-1.0, min(1.0, x)) * 32767))
        return out


def write_wav(path, samples):
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", s) for s in samples))


def build_menu():
    t = Track()
    bpm = 92
    beat = 60 / bpm
    bar = 4 * beat
    prog = [(57, [57, 60, 64]), (53, [53, 57, 60]), (60, [60, 64, 67]), (55, [55, 59, 62])]
    for i, (root, tones) in enumerate(prog):
        bs = i * bar
        for tn in tones:
            t.note(bs, bar * 0.98, tn, wave="triangle", vol=0.16, attack=0.05, release=0.3)
        for b in (0, 2):
            t.note(bs + b * beat, beat * 0.9, root - 12, wave="triangle", vol=0.30, attack=0.01, release=0.05)
        for k in range(8):
            tn = tones[k % len(tones)] + (12 if k >= 6 else 0)
            t.note(bs + k * (beat / 2), beat / 2 * 0.9, tn, wave="square", vol=0.18, attack=0.005, release=0.05)
    length = bar * 4
    return t.render(length), length


def build_gameplay():
    t = Track()
    bpm = 130
    beat = 60 / bpm
    bar = 4 * beat
    prog = [(57, [57, 60, 64]), (53, [53, 57, 60]), (60, [60, 64, 67]), (55, [55, 59, 62])]
    for i in range(8):
        root, tones = prog[i % 4]
        bs = i * bar
        for k in range(8):
            t.note(bs + k * (beat / 2), beat / 2 * 0.8, root - 12, wave="square", vol=0.30, attack=0.002, release=0.02)
        for k in range(16):
            tn = tones[(k // 2) % len(tones)] + (12 if (k // 4) % 2 else 0)
            t.note(bs + k * (beat / 4), beat / 4 * 0.8, tn, wave="square", vol=0.16, attack=0.002, release=0.02)
        t.kick(bs + 0 * beat, 0.8)
        t.kick(bs + 2 * beat, 0.8)
        t.snare(bs + 1 * beat, 0.45)
        t.snare(bs + 3 * beat, 0.45)
        for k in range(8):
            t.hat(bs + k * (beat / 2), 0.18 + 0.06 * (k % 2))
    length = bar * 8
    return t.render(length), length


def build_boss():
    t = Track()
    bpm = 150
    beat = 60 / bpm
    bar = 4 * beat
    prog = [(57, [57, 60, 64]), (64, [64, 68, 71]), (53, [53, 57, 60]), (55, [55, 59, 62])]
    for i in range(8):
        root, tones = prog[i % 4]
        bs = i * bar
        for k in range(8):
            t.note(bs + k * (beat / 2), beat / 2 * 0.85, root - 12, wave="saw", vol=0.30, attack=0.002, release=0.02)
        for k in range(16):
            tn = tones[k % len(tones)] + (12 if (k // 4) % 2 else 0)
            t.note(bs + k * (beat / 4), beat / 4 * 0.85, tn, wave="square", vol=0.18, attack=0.002, release=0.02, detune=4.0)
        t.kick(bs + 0 * beat, 0.85)
        t.kick(bs + 1 * beat, 0.85)
        t.kick(bs + 2 * beat, 0.85)
        t.kick(bs + 3 * beat, 0.85)
        t.snare(bs + 1 * beat, 0.5)
        t.snare(bs + 3 * beat, 0.5)
        for k in range(16):
            t.hat(bs + k * (beat / 4), 0.14 + 0.05 * (k % 2))
    length = bar * 8
    return t.render(length), length


def build_victory():
    t = Track()
    bpm = 120
    beat = 60 / bpm
    seq = [(69, 1.0), (73, 1.0), (76, 1.0), (81, 1.5)]
    start = 0.0
    for midi, dur in seq:
        t.note(start, dur * 0.95 * beat, midi, wave="square", vol=0.28, attack=0.005, release=0.1)
        t.note(start, dur * 0.95 * beat, midi - 12, wave="triangle", vol=0.18, attack=0.005, release=0.1)
        start += dur * beat
    for tn in (69, 73, 76, 81):
        t.note(start, 2.0, tn, wave="square", vol=0.20, attack=0.01, release=0.4)
    length = start + 2.0
    return t.render(length), length


def build_death():
    t = Track()
    bpm = 80
    beat = 60 / bpm
    t.note(0, 6.0, 45, wave="triangle", vol=0.22, attack=0.1, release=0.8)
    seq = [(69, 1.0), (67, 1.0), (64, 1.0), (60, 1.5), (57, 2.0)]
    start = 0.0
    for midi, dur in seq:
        t.note(start, dur * beat * 0.95, midi, wave="triangle", vol=0.30, attack=0.03, release=0.3)
        start += dur * beat
    length = max(6.0, start)
    return t.render(length), length


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    tracks = {
        "menu": build_menu,
        "gameplay": build_gameplay,
        "boss": build_boss,
        "victory": build_victory,
        "death": build_death,
    }
    print("Generating music into %s" % OUT_DIR)
    for name, fn in tracks.items():
        samples, length = fn()
        path = os.path.join(OUT_DIR, name + ".wav")
        write_wav(path, samples)
        size = os.path.getsize(path)
        print("  %-9s %5.1fs  %7d bytes  %s" % (name, length, size, path))
    print("DONE")


if __name__ == "__main__":
    main()
