# Codemod 021: إزالة المفتاح المكرر «عميل» من قاموس الإنجليزي (أضافه 020 وهو موجود)
import sys, os, re, collections

def run(root):
    os.chdir(root)
    p = 'lib/core/i18n/en.dart'
    s = open(p, encoding='utf-8').read()
    dup = "  'عميل': 'Customer',\n"
    if s.count(dup) < 2:
        print('021 already applied'); return
    i = s.rindex(dup)          # نحذف آخر نسخة فقط
    s = s[:i] + s[i + len(dup):]
    open(p, 'w', encoding='utf-8').write(s)
    keys = re.findall(r"^  '((?:[^'\\]|\\.)*)':", s, flags=re.M)
    left = [k for k, c in collections.Counter(keys).items() if c > 1]
    assert not left, left
    print('021 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
