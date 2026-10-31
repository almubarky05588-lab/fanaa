"""يولّد أيقونة تطبيق فناء (1024×1024) من نفس هندسة العلامة في Figma.
الاستخدام: python3 tool/make_icon.py assets/brand
"""
import math, os, sys
from PIL import Image, ImageDraw

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/brand"
S = 1024
SS = 4  # تنعيم الحواف بالتكبير
DEEP, PRIMARY, LIME, WHITE = (12, 62, 42), (21, 122, 78), (183, 224, 92), (255, 255, 255)
PTS = [(0, 0), (34, -8), (36, -42), (6, -58), (-6, -38), (-17, -18), (0, 0)]


def bez(p0, p1, p2, p3, n=60):
    return [((1-t)**3*p0[0] + 3*(1-t)**2*t*p1[0] + 3*(1-t)*t*t*p2[0] + t**3*p3[0],
             (1-t)**3*p0[1] + 3*(1-t)**2*t*p1[1] + 3*(1-t)*t*t*p2[1] + t**3*p3[1]) for t in [i/n for i in range(n+1)]]


def leaf(angle, scale, cx, cy):
    a = math.radians(angle)
    p = [(cx + x*scale*math.cos(a) - y*scale*math.sin(a), cy + x*scale*math.sin(a) + y*scale*math.cos(a)) for x, y in PTS]
    return bez(p[0], p[1], p[2], p[3]) + bez(p[3], p[4], p[5], p[6])[1:]


def mark_polys(size, ox, oy):
    k = size / 120
    polys = [leaf(8, 1.2*k, 60*k, 60*k), leaf(130, .94*k, 60*k, 60*k), leaf(248, .70*k, 60*k, 60*k)]
    xs = [x for pl in polys for x, _ in pl]
    ys = [y for pl in polys for _, y in pl]
    dx = ox + (size - (max(xs)-min(xs)))/2 - min(xs)
    dy = oy + (size - (max(ys)-min(ys)))/2 - min(ys)
    return [[(x+dx, y+dy) for x, y in pl] for pl in polys]


def gradient(w, h, c1, c2):
    g = Image.new("RGB", (w, h))
    px = g.load()
    for yy in range(h):
        for xx in range(w):
            t = min(1, max(0, (xx + yy) / (w + h)))
            px[xx, yy] = tuple(int(c1[i] + (c2[i]-c1[i])*t) for i in range(3))
    return g


def render(bg=True, mark_size=0.62):
    W = S*SS
    base = (gradient(256, 256, DEEP, PRIMARY).resize((W, W), Image.BICUBIC) if bg
            else Image.new("RGBA", (W, W), (0, 0, 0, 0))).convert("RGBA")
    mask = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(mask)
    m = W*mark_size
    for pl in mark_polys(m, (W-m)/2, (W-m)/2):
        d.polygon(pl, fill=255)
    fill = gradient(256, 256, LIME, WHITE).resize((W, W), Image.BICUBIC).convert("RGBA")
    base.paste(fill, (0, 0), mask)
    return base.resize((S, S), Image.LANCZOS)


# ------------------------------------------------ الشعار المعتمد (logo.svg) — يُرسم بدون مكتبات خارجية
def _svg_paths(svg_text):
    """يقرأ مسارات SVG (أوامر M/L/C/Z مطلقة) ويرجع [(لون, [مسارات فرعية كنقاط])]."""
    import re
    out = []
    for fill, d in re.findall(r'<path[^>]*fill="(#[0-9A-Fa-f]{6})"[^>]*d="([^"]+)"', svg_text):
        color = tuple(int(fill[i:i+2], 16) for i in (1, 3, 5))
        subs, cur, pos = [], [], (0.0, 0.0)
        for cmd, args in re.findall(r'([MLCZ])([^MLCZ]*)', d):
            n = [float(v) for v in re.findall(r'-?\d+(?:\.\d+)?', args)]
            if cmd == 'M':
                if cur: subs.append(cur)
                pos = (n[0], n[1]); cur = [pos]
            elif cmd == 'L':
                for i in range(0, len(n), 2):
                    pos = (n[i], n[i+1]); cur.append(pos)
            elif cmd == 'C':
                for i in range(0, len(n), 6):
                    pts = bez(pos, (n[i], n[i+1]), (n[i+2], n[i+3]), (n[i+4], n[i+5]), 16)
                    cur.extend(pts[1:]); pos = pts[-1]
            elif cmd == 'Z':
                if cur: subs.append(cur); cur = []
        if cur: subs.append(cur)
        out.append((color, subs))
    return out


def render_logo(svg_path, size, bg=(255, 255, 255), scale=0.70):
    from PIL import ImageChops
    W = size * SS
    img = Image.new("RGB", (W, W), bg)
    m = W * scale; off = (W - m) / 2; k = m / 1024
    for color, subs in _svg_paths(open(svg_path, encoding="utf-8").read()):
        mask = Image.new("1", (W, W), 0)
        for sub in subs:   # قاعدة evenodd: كل مسار فرعي يقلب ما تحته (يصنع الفراغات)
            one = Image.new("1", (W, W), 0)
            ImageDraw.Draw(one).polygon([(off + x*k, off + y*k) for x, y in sub], fill=1)
            mask = ImageChops.logical_xor(mask, one)
        img.paste(color, (0, 0), mask.convert("L"))
    return img.resize((size, size), Image.LANCZOS)


os.makedirs(OUT, exist_ok=True)
logo_svg = os.path.join(OUT, "logo.svg")
if os.path.exists(logo_svg):
    render_logo(logo_svg, S).save(os.path.join(OUT, "app_icon.png"))
    print("✅ app_icon.png من logo.svg")
else:
    render(True).convert("RGB").save(os.path.join(OUT, "app_icon.png"))
render(False, .50).save(os.path.join(OUT, "app_icon_fg.png"))
print("✅ icons written to", OUT)
