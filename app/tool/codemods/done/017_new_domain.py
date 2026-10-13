# Codemod 017: نطاق الموقع الجديد fanaa-15r.pages.dev (روابط المشاركة وروابط التطبيق وتعبئة الرمز)
import sys, os

OLD, NEW = 'fenaa.netlify.app', 'fanaa-15r.pages.dev'
FILES = [
    'tool/patch_ios.py',
    'lib/features/customer/store/store_screen.dart',
    'lib/features/customer/payment/pay_webview_screen.dart',
]

def run(root):
    os.chdir(root)
    n = 0
    for p in FILES:
        s = open(p, encoding='utf-8').read()
        if OLD in s:
            open(p, 'w', encoding='utf-8').write(s.replace(OLD, NEW))
            n += 1
    print('017 applied (%d files)' % n if n else '017 already applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
