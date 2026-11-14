import numpy as np, wave, os, sys
from PIL import Image, ImageDraw
root = sys.argv[1]
SR = 22050
rng = np.random.default_rng(7)
def save(path, x):
    x = np.clip(x, -1, 1)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32000).astype('<i2').tobytes())
def t(d): return np.linspace(0, d, int(SR*d), endpoint=False)
def env(n, a=0.005, r=0.1):
    tt = np.arange(n)/SR; e = np.minimum(1, tt/a) * np.exp(-tt/r); return e
def noise(d): return rng.uniform(-1,1,int(SR*d))
def lp(x, k=8):
    return np.convolve(x, np.ones(k)/k, mode='same')
def tone(f, d, r=0.2, a=0.005):
    tt=t(d); return np.sin(2*np.pi*f*tt)*env(len(tt),a,r)
def sweep(f0,f1,d):
    tt=t(d); f=np.linspace(f0,f1,len(tt)); return np.sin(2*np.pi*np.cumsum(f)/SR)
sfx = os.path.join(root,'assets/audio/sfx'); mus=os.path.join(root,'assets/audio/music')
os.makedirs(sfx,exist_ok=True); os.makedirs(mus,exist_ok=True)
S={}
n=noise(0.25); S['swing']=lp(n,3)*np.sin(np.linspace(0,np.pi,len(n)))*0.5
n=noise(0.4); S['heavy']=lp(n,5)*np.sin(np.linspace(0,np.pi,len(n)))*0.7
S['hit']=lp(noise(0.15),6)*env(int(SR*0.15),0.001,0.04)*0.9+tone(110,0.15,0.05)*0.5
def metal(d,fs,r):
    tt=t(d); return sum(np.sin(2*np.pi*f*tt) for f in fs)/len(fs)*env(len(tt),0.001,r)
S['block']=metal(0.4,[620,1340,2210,3170],0.08)*0.7+lp(noise(0.4),2)*env(int(SR*0.4),0.001,0.01)*0.4
S['parry']=metal(0.8,[880,1760,2640,3520,4500],0.25)*0.8
S['hurt']=tone(160,0.25,0.08)*0.6+lp(noise(0.25),10)*env(int(SR*0.25),0.001,0.05)*0.5
S['jump']=lp(noise(0.12),12)*env(int(SR*0.12),0.01,0.04)*0.6
S['land']=lp(noise(0.15),20)*env(int(SR*0.15),0.001,0.04)*0.9
S['dodge']=lp(noise(0.3),4)*np.sin(np.linspace(0,np.pi,int(SR*0.3)))*0.4
S['tired']=lp(noise(0.4),30)*np.sin(np.linspace(0,np.pi,int(SR*0.4)))*0.4
S['dummy']=lp(noise(0.2),14)*env(int(SR*0.2),0.001,0.05)*0.8
S['yield']=sum(tone(f,1.0,0.5) for f in [392,494,587])*0.25
S['mount']=lp(noise(0.3),16)*env(int(SR*0.3),0.01,0.1)*0.5
def neigh(d=0.9):
    tt=t(d); f=600+250*np.sin(2*np.pi*7*tt)*np.exp(-tt*1.5) - 250*tt
    s=np.sign(np.sin(2*np.pi*np.cumsum(f)/SR))*0.3+np.sin(2*np.pi*np.cumsum(f*2)/SR)*0.2
    return lp(s,6)*np.sin(np.linspace(0,np.pi,len(tt)))**0.5*0.5
S['neigh']=neigh(); S['snort']=lp(noise(0.35),25)*env(int(SR*0.35),0.02,0.1)*0.7
hoof=lambda: lp(noise(0.08),18)*env(int(SR*0.08),0.001,0.02)
S['horse_jump']=np.concatenate([hoof(),hoof()*0.8, np.zeros(1000)])*0.9
S['hoof_land']=np.concatenate([hoof(),np.zeros(600),hoof(),np.zeros(400),hoof()])*0.9
S['collect']=np.concatenate([tone(880,0.12,0.1),tone(1175,0.12,0.1),tone(1568,0.3,0.2)])*0.4
S['supply']=np.concatenate([tone(660,0.1,0.08),tone(990,0.25,0.15)])*0.4
S['checkpoint']=(tone(523,1.2,0.6)+tone(784,1.2,0.6)*0.6+tone(1046,1.2,0.4)*0.3)*0.3
S['crumble']=lp(noise(0.6),8)*np.abs(np.sin(np.linspace(0,20,int(SR*0.6))))*0.4
S['stone']=lp(noise(0.25),20)*env(int(SR*0.25),0.001,0.06)*0.9
S['gate']=lp(noise(1.2),40)*0.5+sweep(60,90,1.2)*0.2
S['victory']=np.concatenate([tone(f,0.25 if i<3 else 1.0,0.3 if i<3 else 0.8) for i,f in enumerate([392,523,659,784])])*0.4
S['ui']=tone(1200,0.05,0.02)*0.3
for k,v in S.items(): save(os.path.join(sfx,k+'.wav'),v)
# music: tanpura-like drone (Sa-Pa) + soft dholak-style pulse, 16 s loop
d=16.0; tt=t(d); sa=146.8
def pluck_drone(f, start_offsets):
    out=np.zeros(len(tt))
    for off in start_offsets:
        i=int(off*SR); n=len(tt)-i; tl=np.arange(n)/SR
        s=sum(np.sin(2*np.pi*f*h*tl+h)/h**1.2 for h in range(1,9))*np.exp(-tl*0.6)
        out[i:]+=s*0.25
    return out
beats=np.arange(0,d,4.0)
m=pluck_drone(sa*1.5,beats)+pluck_drone(sa*2,beats+1)+pluck_drone(sa*2,beats+2)+pluck_drone(sa,beats+3)
for b in np.arange(0,d,0.5):
    i=int(b*SR); n=min(int(0.3*SR),len(tt)-i); tl=np.arange(n)/SR
    acc=1.0 if (b%2)==0 else 0.5
    m[i:i+n]+=np.sin(2*np.pi*(90+60*np.exp(-tl*30))*tl)*np.exp(-tl*12)*0.35*acc
# fade loop seam
m=m/np.max(np.abs(m))*0.6
save(os.path.join(mus,'gogunda_theme.wav'),m)
w=lp(noise(12.0),60); w=w/np.max(np.abs(w))*0.4*(0.7+0.3*np.sin(np.linspace(0,4*np.pi,len(w))))
save(os.path.join(mus,'wind.wav'),w)
# icon
img=Image.new('RGBA',(256,256),(43,47,107,255)); dr=ImageDraw.Draw(img)
dr.ellipse((18,18,238,238),outline=(201,161,74),width=10)
dr.polygon([(70,150),(186,150),(170,95),(128,70),(86,95)],fill=(232,137,43))
dr.rectangle((70,140,186,152),fill=(201,161,74))
dr.ellipse((95,145,161,205),fill=(185,122,79))
dr.line((105,185,151,185),fill=(28,20,16),width=7)
img.save(os.path.join(root,'assets/ui/icon.png'))
print('assets ok', len(S))

# ---- Milestone 2 additions
S2 = {}
S2['bow'] = (lp(noise(0.18), 3) * env(int(SR*0.18), 0.001, 0.05) * 0.5 + tone(220, 0.18, 0.06) * 0.3)
v = np.zeros(int(SR*0.7))
for k in range(7):
    i = int(rng.uniform(0, 0.45) * SR); n = int(SR*0.12)
    v[i:i+n] += lp(noise(0.12), 2) * env(n, 0.001, 0.03) * 0.5
S2['arrow_volley'] = v
S2['splash'] = lp(noise(0.5), 5) * env(int(SR*0.5), 0.01, 0.15) * 0.6
S2['branch'] = lp(noise(0.3), 3) * env(int(SR*0.3), 0.001, 0.08) * 0.7 + lp(noise(0.3), 30) * 0.2
for k, v in S2.items():
    save(os.path.join(sfx, k + '.wav'), v)
def theme(sa, d, beat_every, accent, drone_gain, perc_gain, seed_offs):
    tt = t(d)
    def drone(f, offs):
        out = np.zeros(len(tt))
        for off in offs:
            i = int(off * SR); n = len(tt) - i; tl = np.arange(n) / SR
            out[i:] += sum(np.sin(2*np.pi*f*h*tl + h) / h**1.2 for h in range(1, 9)) * np.exp(-tl * 0.6) * 0.25
        return out
    beats = np.arange(0, d, 4.0)
    m = (drone(sa*1.5, beats) + drone(sa*2, beats+1) + drone(sa*2, beats+2) + drone(sa, beats+3)) * drone_gain
    for b in np.arange(0, d, beat_every):
        i = int(b * SR); n = min(int(0.3*SR), len(tt) - i); tl = np.arange(n) / SR
        acc = 1.0 if (round(b / beat_every) % accent) == 0 else 0.55
        m[i:i+n] += np.sin(2*np.pi*(80 + 70*np.exp(-tl*30))*tl) * np.exp(-tl*12) * perc_gain * acc
    return m / np.max(np.abs(m)) * 0.6
save(os.path.join(mus, 'battle_theme.wav'), theme(138.6, 16.0, 0.25, 4, 0.8, 0.45, 1))
save(os.path.join(mus, 'ride_theme.wav'), theme(130.8, 16.0, 0.5, 3, 1.0, 0.25, 2))
print('m2 assets ok')
