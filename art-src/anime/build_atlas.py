"""Pack anime SVGs into characters_atlas.png for the game.
Cells are taller (80x112) so human proportions read at game scale."""
import json
from PIL import Image
m = json.load(open('svg/meta.json'))
UNITS = ['tallowguard','wickthrower','drip_matron','waxling','sparkrunner','fusepot','flarecaster','lensmender','prismshot','moth','gloomwisp','husk']
CW, CH = 80, 112
BOSS = 192
# layout: row0 flames, row1 bodies, row2 white, row3-4 boss+white
A = Image.new('RGBA', (max(12*CW, BOSS*2), CH*2 + 64 + BOSS), (0,0,0,0))

def white(im):
    w = Image.new('RGBA', im.size, (255,255,255,0)); w.putalpha(im.getchannel('A')); return w

def cell(name, w, h, flame):
    src = Image.open(f'png/{name}{"_noflame" if flame else ""}.png')
    # fit into w x h keeping aspect, bottom-aligned
    src.thumbnail((w-4, h-4), Image.LANCZOS)
    canvas = Image.new('RGBA', (w, h), (0,0,0,0))
    canvas.alpha_composite(src, ((w-src.size[0])//2, h-src.size[1]-2))
    return canvas

for i, f in enumerate(['flame_warm', 'flame_cold']):
    fl = Image.open(f'png/{f}.png').resize((64,64), Image.LANCZOS)
    A.alpha_composite(fl, (192 + 64*i, 0))

gd = []
for i, n in enumerate(UNITS):
    fl = m[n]['flame']
    c = cell(n, CW, CH, fl is not None)
    A.alpha_composite(c, (i*CW, 64))
    A.alpha_composite(white(c), (i*CW, 64+CH))
    f = 'null' if fl is None else f'[Vector2({fl[0]/200:.3f}, {fl[1]/280:.3f}), {fl[2]/280:.3f}, {1 if fl[3]=="cold" else 0}]'
    gd.append(f'\t&"{n}": [{i}, {f}],')

b = cell('matriarch', BOSS, BOSS, False)
by = 64 + 2*CH
A.alpha_composite(b, (0, by)); A.alpha_composite(white(b), (BOSS, by))
out = '../../art/characters_atlas.png'
A.save(out)
print('atlas', A.size, out)
print('\n'.join(gd))
print('BOSS_Y', by)
