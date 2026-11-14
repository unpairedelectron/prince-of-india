"""Placeholder audio for the hero campaigns (run: python3 tools/make_audio_campaigns.py <project root>).
Same style as tools/make_assets.py: synthesised, 22.05 kHz mono WAV."""
import numpy as np, wave, os, sys
root = sys.argv[1]
SR = 22050
rng = np.random.default_rng(11)
def save(path, x):
    x = np.clip(x, -1, 1)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32000).astype('<i2').tobytes())
def t(d): return np.linspace(0, d, int(SR * d), endpoint=False)
def env(n, a=0.005, r=0.1):
    tt = np.arange(n) / SR
    return np.minimum(1, tt / a) * np.exp(-tt / r)
def noise(d): return rng.uniform(-1, 1, int(SR * d))
def lp(x, k=8): return np.convolve(x, np.ones(k) / k, mode='same')
def tone(f, d, r=0.2, a=0.005):
    tt = t(d); return np.sin(2 * np.pi * f * tt) * env(len(tt), a, r)
sfx = os.path.join(root, 'assets/audio/sfx'); mus = os.path.join(root, 'assets/audio/music')
save(os.path.join(sfx, 'spike.wav'), (lp(noise(0.18), 3) * env(int(SR * 0.18), 0.001, 0.03) * 0.6 + tone(1800, 0.18, 0.04) * 0.3))
save(os.path.join(sfx, 'musket.wav'), lp(noise(0.5), 4) * env(int(SR * 0.5), 0.001, 0.07) * 0.95 + tone(90, 0.5, 0.1) * 0.5)
save(os.path.join(sfx, 'cannon.wav'), lp(noise(1.0), 14) * env(int(SR * 1.0), 0.001, 0.22) * 1.0 + tone(55, 1.0, 0.3) * 0.7)

def pluck(f, d, r=0.5):
    tt = t(d)
    return (np.sin(2 * np.pi * f * tt) + 0.5 * np.sin(4 * np.pi * f * tt) + 0.25 * np.sin(6 * np.pi * f * tt)) * env(len(tt), 0.003, r) / 1.75
def drum(d=0.18, f=90): return (tone(f, d, 0.06) + lp(noise(d), 10) * env(int(SR * d), 0.001, 0.03) * 0.5)
def place(out, x, at):
    i = int(at * SR); n = min(len(x), len(out) - i)
    if n > 0: out[i:i + n] += x[:n]
def track(name, sa, scale, bpm, melody, beat, drone=0.12, length=16.0):
    """melody: scale degrees per half-beat (None = rest); beat: drum pattern per half-beat."""
    out = np.zeros(int(SR * length)); tt = t(length)
    out += drone * (np.sin(2 * np.pi * sa * tt) + 0.6 * np.sin(2 * np.pi * sa * 1.5 * tt) + 0.4 * np.sin(2 * np.pi * sa * 2 * tt)) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.25 * tt))
    step = 60.0 / bpm / 2
    n = int(length / step)
    for i in range(n):
        m = melody[i % len(melody)]
        if m is not None:
            place(out, pluck(sa * 2 * 2 ** (scale[m % len(scale)] / 12.0) * (2 if m >= len(scale) else 1), step * 2.5, 0.35) * 0.3, i * step)
        b = beat[i % len(beat)]
        if b: place(out, drum(0.2, 70 if b == 2 else 140) * (0.5 if b == 2 else 0.25), i * step)
    fade = int(SR * 0.05); out[:fade] *= np.linspace(0, 1, fade); out[-fade:] *= np.linspace(1, 0, fade)
    save(os.path.join(mus, name + '.wav'), out * 0.8)
BHUP = [0, 2, 4, 7, 9]          # Bhupali / pentatonic major
BHAIRAVI = [0, 1, 3, 5, 7, 8, 10]
KAFI = [0, 2, 3, 5, 7, 9, 10]
DURGA = [0, 2, 5, 7, 9]
track('sahyadri_theme', 146.8, KAFI, 96, [0, None, 2, 3, 4, None, 3, 2, 0, None, 4, 5, 7, None, 5, 4], [2, 0, 1, 0, 2, 1, 1, 0])
track('jhansi_theme', 130.8, BHUP, 88, [0, 1, 2, None, 4, None, 3, 2, 5, None, 4, 3, 2, 1, 0, None], [2, 0, 0, 1, 2, 0, 1, 1])
track('assam_theme', 164.8, DURGA, 80, [4, None, 3, 2, None, 1, 0, None, 2, None, 3, 4, 5, None, 4, None], [2, 0, 0, 0, 1, 0, 2, 0])
track('night_theme', 110.0, BHAIRAVI, 66, [0, None, None, 1, None, 3, None, None, 4, None, 3, None, 1, None, 0, None], [2, 0, 0, 0, 0, 0, 1, 0], drone=0.16)
track('boss_theme', 123.5, BHAIRAVI, 132, [0, 0, 3, 0, 4, 0, 3, 1, 0, 0, 5, 4, 3, 1, 0, 7], [2, 1, 1, 2, 1, 1, 2, 1], drone=0.14)
r = lp(noise(8.0), 3) * 0.22 + lp(noise(8.0), 40) * 0.5
fade = int(SR * 0.3); r[:fade] *= np.linspace(0, 1, fade); r[-fade:] *= np.linspace(1, 0, fade)
save(os.path.join(mus, 'rain.wav'), r)
print("ok")
