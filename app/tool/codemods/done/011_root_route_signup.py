"""Codemod 011: مسار "/" (يفتحه iOS عند تفعيل الروابط) يوجّه لشاشة البداية، ونص «حسابك يُنشأ تلقائيًا» بدل «سجّل الآن»."""
import sys, os

def ed(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:60])
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8').write(s)

def run(root):
    os.chdir(root)
    if "path: '/', redirect:" in open('lib/core/router/app_router.dart', encoding='utf-8').read():
        print('011 already applied'); return
    ed('lib/core/router/app_router.dart', [
        ("      final loc = state.matchedLocation;\n      if (loc == '/splash') return null;",
         "      final loc = state.matchedLocation;\n      // iOS يفتح التطبيق على \"/\" عند تفعيل الروابط العامة\n      if (state.uri.path == '/' || state.uri.path.isEmpty) return '/splash';\n      if (loc == '/splash') return null;"),
        ("    routes: [\n", "    routes: [\n      GoRoute(path: '/', redirect: (_, __) => '/splash'),\n"),
    ])
    ed('lib/features/auth/phone_login_screen.dart', [
        ("""                child: Text.rich(TextSpan(children: [
                  TextSpan(text: tr('ليس لديك حساب؟ '), style: FnText.label13.muted),
                  TextSpan(text: tr('سجّل الآن'), style: FnText.label13.primary),
                ])),""",
         """                child: Text(tr('أول مرة؟ حسابك يُنشأ تلقائيًا برقم جوالك'),
                    style: FnText.label13.muted, textAlign: TextAlign.center),"""),
    ])
    p = 'lib/core/i18n/en.dart'
    s = open(p, encoding='utf-8').read()
    s = s.replace("\n};\n", "\n  'أول مرة؟ حسابك يُنشأ تلقائيًا برقم جوالك': 'First time? Your account is created automatically with your number',\n};\n")
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 011 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
