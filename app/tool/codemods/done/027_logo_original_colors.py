# Codemod 027: الشعار بألوانه الأصلية دائمًا (بدون تلوين) — اللون المُمرَّر يحدد الشفافية فقط
import sys, os

OLD = """        // لون محدد = الشعار بلون واحد (للخلفيات الملوّنة)، بدونه = ألوان الشعار الأصلية
        colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      );"""

NEW = """      );"""

def run(root):
    os.chdir(root)
    p = 'lib/core/widgets/fn_logo.dart'
    s = open(p, encoding='utf-8').read()
    if 'fenaa-original-colors' in s:
        print('027 already applied'); return
    assert s.count(OLD) == 1
    s = s.replace(OLD, NEW)
    old_head = "  Widget build(BuildContext context) => SvgPicture.asset("
    assert s.count(old_head) == 1
    s = s.replace(old_head,
        "  // fenaa-original-colors: الشعار دائمًا بألوانه الأصلية؛ شفافية اللون المُمرَّر (إن وُجد) تُطبَّق كشفافية فقط\n"
        "  Widget build(BuildContext context) => Opacity(\n"
        "        opacity: (color?.a ?? 1.0).clamp(0.0, 1.0),\n"
        "        child: SvgPicture.asset(")
    s = s.replace("        width: size,\n        height: size,\n      );",
                  "        width: size,\n        height: size,\n      ),\n      );", 1)
    open(p, 'w', encoding='utf-8').write(s)
    print('027 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
