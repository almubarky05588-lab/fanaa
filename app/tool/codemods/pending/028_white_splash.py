# Codemod 028: شاشة البداية — خلفية بيضاء والشعار بألوانه الأصلية في المنتصف وبحجم مناسب
import sys, os

OLD = """  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: FnColors.deep,
        body: Center(child: FnLogoLockup(markSize: 56, markColor: FnColors.lime)),
      );"""

NEW = """  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.white,
        // الشعار بألوانه الأصلية (بدون تلوين) في منتصف الشاشة
        body: Center(child: FnLogoMark(size: 160)),
      );"""

def run(root):
    os.chdir(root)
    p = 'lib/features/auth/splash_screen.dart'
    s = open(p, encoding='utf-8').read()
    if 'FnLogoMark(size: 160)' in s:
        print('028 already applied'); return
    assert s.count(OLD) == 1
    s = s.replace(OLD, NEW)
    open(p, 'w', encoding='utf-8').write(s)
    print('028 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
