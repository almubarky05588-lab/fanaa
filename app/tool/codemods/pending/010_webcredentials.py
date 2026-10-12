"""Codemod 010: صلاحية webcredentials ليعبّي iOS رمز التحقق تلقائيًا (رسائل @fenaa.netlify.app #1234)."""
import sys, os

def run(root):
    os.chdir(root)
    p = 'tool/patch_ios.py'
    s = open(p, encoding='utf-8').read()
    old = '[f"applinks:{LINK_HOST}"]'
    if 'webcredentials:' in s:
        print('010 already applied'); return
    assert s.count(old) == 1
    s = s.replace(old, '[f"applinks:{LINK_HOST}", f"webcredentials:{LINK_HOST}"]')
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 010 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
