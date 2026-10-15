#!/usr/bin/env python3
"""Synthesizes the game's original sound effects into assets/sounds/*.wav.

Everything is generated from sine/noise primitives here, so the sounds are
original and license-free.   python3 tools/gen_sounds.py
"""
import math, pathlib, random, struct, wave

SR = 22050
OUT = pathlib.Path(__file__).resolve().parent.parent / 'assets' / 'sounds'
OUT.mkdir(parents=True, exist_ok=True)
rng = random.Random(7)


def env(i, n, a=0.01, r=0.25):
    t, d = i / SR, n / SR
    if t < a:
        return t / a
    return max(0.0, 1 - (t - a) / max(1e-6, d - a)) ** (1 / max(r, 1e-3)) if r else 1.0


def tone(freq, dur, vol=0.5, harm=(1, .35, .15), decay=3.0, bend=0.0):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = freq * (1 + bend * t / dur)
        ph += 2 * math.pi * f / SR
        s = sum(a * math.sin(ph * (k + 1)) for k, a in enumerate(harm))
        e = min(1, t / 0.005) * math.exp(-decay * t)
        out.append(s * e * vol)
    return out


def noise(dur, vol=0.3, decay=30.0, lp=0.3):
    n = int(SR * dur)
    out, y = [], 0.0
    for i in range(n):
        y += lp * (rng.uniform(-1, 1) - y)
        out.append(y * vol * math.exp(-decay * i / SR))
    return out


def mix(*parts):
    """parts: (offset_seconds, samples)"""
    n = max(int(o * SR) + len(s) for o, s in parts)
    buf = [0.0] * n
    for o, s in parts:
        st = int(o * SR)
        for i, v in enumerate(s):
            buf[st + i] += v
    return buf


def save(name, buf):
    peak = max(1e-6, max(abs(v) for v in buf))
    k = min(1.0, 0.85 / peak)
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, v * k)) * 32767)) for v in buf))


C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0
save('tap', tone(880, 0.06, .4, (1, .2), decay=60))
save('flip', mix((0, noise(0.12, .5, 35, .5)), (0.02, tone(1400, 0.05, .15, (1,), decay=80))))
save('shuffle', mix(*[(i * 0.045, noise(0.07, .45, 45, .6)) for i in range(12)]))
save('reveal', mix((0, tone(G5, .5, .3, decay=6)), (0.08, tone(C6, .6, .3, decay=5)), (0.16, tone(E6, .8, .25, decay=4))))
save('win', mix((0, tone(C5, .3, .35, decay=6)), (0.12, tone(E5, .3, .35, decay=6)), (0.24, tone(G5, .3, .35, decay=6)),
                (0.36, tone(C6, .9, .4, decay=3)), (0.36, tone(E6, .9, .2, decay=3))))
save('lose', mix((0, tone(G5 / 2, .35, .35, decay=5)), (0.18, tone(E5 / 2, .35, .35, decay=5)), (0.36, tone(C5 / 2 * 0.94, .8, .35, decay=3, bend=-.06))))
save('joker', mix(*[(i * 0.11, tone(f, .16, .3, (1, .5, .3, .2), decay=14, bend=b))
                    for i, (f, b) in enumerate([(660, .3), (520, -.25), (780, .35), (440, -.3), (990, .4)])]))
save('perfect', mix((0, tone(C5, .25, .3, decay=8)), (0.1, tone(G5, .25, .3, decay=8)), (0.2, tone(C6, .25, .3, decay=8)),
                    (0.3, tone(E6, .25, .3, decay=8)), (0.4, tone(G6, 1.0, .35, decay=3)),
                    *[(0.45 + i * 0.07, tone(2000 + 300 * (i % 3), .12, .08, (1,), decay=30)) for i in range(8)]))
save('champion', mix(*[(o, tone(f, d, .3, decay=dc)) for o, f, d, dc in [
    (0, C5, .2, 8), (.15, C5, .2, 8), (.3, C5, .2, 8), (.45, G5, .5, 5), (.75, E5, .2, 8), (.9, G5, .2, 8), (1.05, C6, 1.2, 2.5)]],
    (1.05, tone(E6, 1.2, .18, decay=2.5)), (1.05, tone(G5, 1.2, .18, decay=2.5))))
print('sounds:', sorted(p.name for p in OUT.iterdir()))
