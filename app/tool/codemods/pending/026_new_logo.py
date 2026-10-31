# Codemod 026: (+ أيقونة التطبيق من logo.svg)
# Codemod 026: الشعار الجديد (بيت ونبتة) داخل التطبيق — كل أماكن الشعار تعرض assets/brand/logo.svg
# بلونه الأصلي، أو بلون واحد لو طُلب لون (مثل الشعار الفاتح على الأخضر)
import sys, os

OLD = """  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(color: color, gradient: gradient),
      );"""

NEW = """  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/brand/logo.svg',
        width: size,
        height: size,
        // لون محدد = الشعار بلون واحد (للخلفيات الملوّنة)، بدونه = ألوان الشعار الأصلية
        colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      );"""

MAKE_ICON_OLD = 'os.makedirs(OUT, exist_ok=True)\nrender(True).convert("RGB").save(os.path.join(OUT, "app_icon.png"))\n'
MAKE_ICON_NEW = '# ------------------------------------------------ الشعار المعتمد (logo.svg) — يُرسم بدون مكتبات خارجية\ndef _svg_paths(svg_text):\n    """يقرأ مسارات SVG (أوامر M/L/C/Z مطلقة) ويرجع [(لون, [مسارات فرعية كنقاط])]."""\n    import re\n    out = []\n    for fill, d in re.findall(r\'<path[^>]*fill="(#[0-9A-Fa-f]{6})"[^>]*d="([^"]+)"\', svg_text):\n        color = tuple(int(fill[i:i+2], 16) for i in (1, 3, 5))\n        subs, cur, pos = [], [], (0.0, 0.0)\n        for cmd, args in re.findall(r\'([MLCZ])([^MLCZ]*)\', d):\n            n = [float(v) for v in re.findall(r\'-?\\d+(?:\\.\\d+)?\', args)]\n            if cmd == \'M\':\n                if cur: subs.append(cur)\n                pos = (n[0], n[1]); cur = [pos]\n            elif cmd == \'L\':\n                for i in range(0, len(n), 2):\n                    pos = (n[i], n[i+1]); cur.append(pos)\n            elif cmd == \'C\':\n                for i in range(0, len(n), 6):\n                    pts = bez(pos, (n[i], n[i+1]), (n[i+2], n[i+3]), (n[i+4], n[i+5]), 16)\n                    cur.extend(pts[1:]); pos = pts[-1]\n            elif cmd == \'Z\':\n                if cur: subs.append(cur); cur = []\n        if cur: subs.append(cur)\n        out.append((color, subs))\n    return out\n\n\ndef render_logo(svg_path, size, bg=(255, 255, 255), scale=0.70):\n    from PIL import ImageChops\n    W = size * SS\n    img = Image.new("RGB", (W, W), bg)\n    m = W * scale; off = (W - m) / 2; k = m / 1024\n    for color, subs in _svg_paths(open(svg_path, encoding="utf-8").read()):\n        mask = Image.new("1", (W, W), 0)\n        for sub in subs:   # قاعدة evenodd: كل مسار فرعي يقلب ما تحته (يصنع الفراغات)\n            one = Image.new("1", (W, W), 0)\n            ImageDraw.Draw(one).polygon([(off + x*k, off + y*k) for x, y in sub], fill=1)\n            mask = ImageChops.logical_xor(mask, one)\n        img.paste(color, (0, 0), mask.convert("L"))\n    return img.resize((size, size), Image.LANCZOS)\n\n\nos.makedirs(OUT, exist_ok=True)\nlogo_svg = os.path.join(OUT, "logo.svg")\nif os.path.exists(logo_svg):\n    render_logo(logo_svg, S).save(os.path.join(OUT, "app_icon.png"))\n    print("✅ app_icon.png من logo.svg")\nelse:\n    render(True).convert("RGB").save(os.path.join(OUT, "app_icon.png"))\n'


def run(root):
    os.chdir(root)
    p = 'lib/core/widgets/fn_logo.dart'
    s = open(p, encoding='utf-8').read()
    if "assets/brand/logo.svg" in s:
        print('026 already applied'); return
    assert s.count(OLD) == 1
    s = s.replace(OLD, NEW)
    s = s.replace("import 'package:flutter/material.dart';\n",
                  "import 'package:flutter/material.dart';\nimport 'package:flutter_svg/flutter_svg.dart';\n", 1)
    # الرسّام القديم لم يعد مستخدمًا — نبقيه بدون تحذير
    s = s.replace("class _MarkPainter extends CustomPainter {", "// ignore: unused_element\nclass _MarkPainter extends CustomPainter {", 1)
    open(p, 'w', encoding='utf-8').write(s)
    p = 'tool/make_icon.py'
    s = open(p, encoding='utf-8').read()
    if 'render_logo' not in s:
        assert s.count(MAKE_ICON_OLD) == 1
        s = s.replace(MAKE_ICON_OLD, MAKE_ICON_NEW)
        open(p, 'w', encoding='utf-8').write(s)
    print('026 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
