"""Codemod: يحوّل كل النصوص العربية إلى tr() ويفعّل التبديل بين العربية والإنجليزية. يُشغَّل مرة واحدة من ci_ios.sh."""

import re, sys, json, os

AR = re.compile(r'[\u0600-\u06FF]')

def find_string_end(s, i):
    """s[i] بداية سلسلة (' أو "). يرجع (نهاية_بعد_الإغلاق, قائمة_الأجزاء) — الأجزاء: ('t', نص) أو ('e', تعبير)"""
    q = s[i]
    if s.startswith(q*3, i):
        return None  # نصوص ثلاثية — نتجاهلها
    j = i + 1
    parts, buf = [], ''
    while j < len(s):
        c = s[j]
        if c == '\\':
            buf += s[j:j+2]; j += 2; continue
        if c == q:
            if buf: parts.append(('t', buf))
            return j + 1, parts
        if c == '$':
            if s[j+1:j+2] == '{':
                if buf: parts.append(('t', buf)); buf = ''
                k = j + 2; depth = 1
                while k < len(s) and depth:
                    ch = s[k]
                    if ch in "'\"":
                        r = find_string_end(s, k)
                        if r is None: return None
                        k = r[0]; continue
                    if ch == '{': depth += 1
                    elif ch == '}': depth -= 1
                    k += 1
                parts.append(('e', s[j+2:k-1])); j = k; continue
            m = re.match(r'\$([A-Za-z_]\w*)', s[j:])
            if m:
                if buf: parts.append(('t', buf)); buf = ''
                parts.append(('e', m.group(1))); j += len(m.group(0)); continue
        if c == '\n':
            return None
        buf += c; j += 1
    return None

KEYS = {}

def transform_expr(code):
    """يحوّل النصوص العربية داخل تعبير (للنصوص المتداخلة في ${})"""
    return transform(code, top=False)[0]

def build_tr(parts, q):
    tpl, args = '', []
    for kind, v in parts:
        if kind == 't': tpl += v
        else:
            tpl += '{%d}' % len(args); args.append(transform_expr(v).strip())
    key = tpl
    KEYS[key] = KEYS.get(key, 0) + 1
    lit = q + key + q
    return f"tr({lit})" if not args else f"tr({lit}, [{', '.join(args)}])"

def transform(s, top=True):
    out, i, n = [], 0, len(s)
    tr_positions = []
    while i < n:
        c = s[i]
        # التعليقات
        if s.startswith('//', i):
            j = s.find('\n', i); j = n if j < 0 else j
            out.append(s[i:j]); i = j; continue
        if s.startswith('/*', i):
            j = s.find('*/', i); j = n if j < 0 else j + 2
            out.append(s[i:j]); i = j; continue
        # نص خام r'...'
        if c == 'r' and i + 1 < n and s[i+1] in "'\"" and (i == 0 or not (s[i-1].isalnum() or s[i-1] == '_')):
            q = s[i+1]; j = s.find(q, i + 2)
            out.append(s[i:j+1]); i = j + 1; continue
        if c in "'\"":
            r = find_string_end(s, i)
            if r is None:
                out.append(c); i += 1; continue
            end, parts = r
            raw = s[i:end]
            texts = ''.join(v for k, v in parts if k == 't')
            line_start = s.rfind('\n', 0, i) + 1
            line = s[line_start:i]
            skip = (not AR.search(texts)) or line.lstrip().startswith('import ')
            if skip:
                # قد يحتوي تعبيرًا داخليًا بعربي
                if any(k == 'e' and AR.search(v) for k, v in parts):
                    rebuilt = c + ''.join(v if k == 't' else '${' + transform_expr(v) + '}' for k, v in parts) + c
                    out.append(rebuilt)
                else:
                    out.append(raw)
                i = end; continue
            tr_positions.append(len(''.join(out)))
            out.append(build_tr(parts, c)); i = end; continue
        out.append(c); i += 1
    return ''.join(out), tr_positions

# -------- إزالة const المانعة: نمشي للخلف من كل tr( ونزيل const من الأقواس المحيطة
DECL_CONST = re.compile(r'(static\s+const|^\s*const\s+\w+(\s*<[^>]*>)?\s+\w+\s*=|^\s*const\s+\w+\s*=)', re.M)

def strip_consts(s):
    changed = True
    while changed:
        changed = False
        for m in re.finditer(r'\btr\(', s):
            pos = m.start()
            depth = 0; k = pos - 1
            while k >= 0:
                ch = s[k]
                if ch in ')]}': depth += 1
                elif ch in '([{':
                    if depth == 0:
                        # قوس مفتوح يحيط بـ tr — هل قبله const ؟
                        pre = s[max(0, k-120):k]
                        mm = re.search(r'\bconst\s*([A-Za-z_][\w.]*\s*(<[^>]*>)?\s*)?$', pre)
                        if mm and ch in '([{':
                            st = k - (len(pre) - mm.start())
                            s = s[:st] + s[st+len('const'):].lstrip(' ') if False else s[:st] + s[st:].replace('const', '', 1).lstrip() if False else s[:st] + re.sub(r'^const\s*', '', s[st:], count=1)
                            changed = True
                            break
                    else:
                        depth -= 1
                elif ch == ';' and depth == 0:
                    break
                k -= 1
            if changed: break
    return s

def in_const_decl(s, pos):
    """هل الموضع داخل مُهيّئ static const / const متغيّر؟"""
    stmt_start = max(s.rfind(';', 0, pos), s.rfind('}\n', 0, pos))
    head = s[stmt_start+1:pos]
    return bool(re.search(r'(static\s+const\s|^\s*const\s+[\w<>?,\s]+=)', head, re.M)) and '=>' not in head.split('=',1)[0]

def process(path):
    src = open(path, encoding='utf-8').read()
    if not AR.search(src): return False
    new, poss = transform(src)
    # ارجع النصوص داخل تعريفات const كما هي (تُترجم عند الاستخدام)
    for m in reversed(list(re.finditer(r"tr\(('(?:[^'\\]|\\.)*'|\"(?:[^\"\\]|\\.)*\")\)", new))):
        if in_const_decl(new, m.start()):
            new = new[:m.start()] + m.group(1) + new[m.end():]
    new = strip_consts(new)
    if new == src: return False
    if 'tr(' in new and "core/i18n/i18n.dart" not in new:
        rel = os.path.relpath('lib/core/i18n/i18n.dart', os.path.dirname(path)).replace(os.sep, '/')
        lines = new.split('\n')
        imps = [i for i, l in enumerate(lines) if l.startswith('import ')]
        lines.insert(imps[-1] + 1 if imps else 0, f"import '{rel}';")
        new = '\n'.join(lines)
    open(path, 'w', encoding='utf-8').write(new)
    return True


# ======================================================= تعديلات يدوية بعد اللفّ
def ed(p, pairs, imp=False):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) >= 1, (p, a[:70])
        s = s.replace(a, b)
    if imp and 'core/i18n/i18n.dart' not in s:
        rel = os.path.relpath('lib/core/i18n/i18n.dart', os.path.dirname(p)).replace(os.sep, '/')
        lines = s.split('\n'); imps = [i for i, l in enumerate(lines) if l.startswith('import ')]
        lines.insert(imps[-1] + 1, f"import '{rel}';"); s = '\n'.join(lines)
    open(p, 'w', encoding='utf-8').write(s)

def manual():
    L = 'lib/'
    ed(L+'features/customer/account/payment_methods_screen.dart', [("title: _methods[i].$2, subtitle: _methods[i].$3,", "title: tr(_methods[i].$2), subtitle: tr(_methods[i].$3),")])
    ed(L+'features/customer/account/support_screen.dart', [("title: Text(_faq[i].$1,", "title: Text(tr(_faq[i].$1),"), ("children: [Text(_faq[i].$2,", "children: [Text(tr(_faq[i].$2),")])
    ed(L+'features/customer/account/legal_screen.dart', [("Text(s.$1, style", "Text(tr(s.$1), style"), ("Text(s.$2, style", "Text(tr(s.$2), style")])
    ed(L+'features/customer/checkout/checkout_screen.dart', [("child: Text(labels[i],", "child: Text(tr(labels[i]),")])
    ed(L+'features/merchant/dashboard/merchant_dashboard_screen.dart', [("Text(dayLetters[days[i].weekday - 1],", "Text(tr(dayLetters[days[i].weekday - 1]),")])
    ed(L+'core/widgets/fn_bottom_nav.dart', [("Text(item.label, style:", "Text(tr(item.label), style:")], imp=True)
    ed(L+'features/customer/home/home_screen.dart', [("Text(c.nameAr, style:", "Text(tr(c.nameAr), style:")], imp=True)
    ed(L+'features/customer/store/store_screen.dart', [("cats[p.categoryId!] = p.categoryName!;", "cats[p.categoryId!] = tr(p.categoryName!);")], imp=True)
    ed(L+'features/customer/widgets/product_card.dart', [("Text(p.categoryName!, style:", "Text(tr(p.categoryName!), style:")], imp=True)
    ed(L+'features/merchant/products/add_product_screen.dart', [("child: Text(c.nameAr, style:", "child: Text(tr(c.nameAr), style:")], imp=True)
    ed(L+'core/widgets/fn_widgets.dart', [
        ("  return (m?.group(1) ?? tr('حدث خطأ غير متوقع')).trim();", "  return m == null ? tr('حدث خطأ غير متوقع') : tr(m.group(1)!.trim());"),
        ("alignment: value ? Alignment.centerLeft : Alignment.centerRight,", "alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,")])
    ed(L+'core/utils/format.dart', [
        ("DateFormat('d MMMM yyyy', 'ar')", "DateFormat('d MMMM yyyy', AppLang.isEn ? 'en' : 'ar')"),
        ("DateFormat('h:mm a', 'ar')", "DateFormat('h:mm a', AppLang.isEn ? 'en' : 'ar')")])
    ed(L+'features/auth/otp_screen.dart', [("Align(alignment: Alignment.centerRight, child: FnBackButton", "Align(alignment: AlignmentDirectional.centerStart, child: FnBackButton")])
    ed(L+'features/customer/orders/tracking_screen.dart', [("Positioned(top: top + 12, right: FnSpace.page, child: FnBackButton", "PositionedDirectional(top: top + 12, start: FnSpace.page, child: FnBackButton")])
    ed(L+'features/auth/phone_login_screen.dart', [
        ("Align(alignment: Alignment.centerRight, child: FnBackButton", "Align(alignment: AlignmentDirectional.centerStart, child: FnBackButton"),
        ("""  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(FnRadius.pill)),""",
         """  Widget build(BuildContext context) => GestureDetector(
      onTap: () => showLanguageSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(FnRadius.pill)),"""),
        ("""          const Icon(Icons.language_rounded, size: 16, color: FnColors.deep),
        ]),
      );
}""", """          const Icon(Icons.language_rounded, size: 16, color: FnColors.deep),
        ]),
      ));
}"""),
        ("import '../../data/repositories/auth_repo.dart';\n", "import '../../data/repositories/auth_repo.dart';\nimport '../customer/account/account_screen.dart' show showLanguageSheet;\n")])
    p = L+'features/customer/account/account_screen.dart'; s = open(p, encoding='utf-8').read()
    i = s.index('/// اختيار اللغة'); j = s.index('class _AccountScreenState')
    s = s[:i] + LANG_SHEET + s[j:]
    open(p, 'w', encoding='utf-8').write(s)
    ed(L+'features/customer/cart/cart_screen.dart', [("r.ok ? tr('{0} — خصم {1}', [r.message, Fmt.money(r.discount)]) : r.message",
        "r.ok ? tr('{0} — خصم {1}', [tr(r.message), Fmt.money(r.discount)]) : tr(r.message)")])
    p = L+'app.dart'; s = open(p, encoding='utf-8').read()
    a = s[s.index("    final router = ref.watch(appRouterProvider);"):s.rindex("  }\n}")]
    s = s.replace(a, APP_BUILD).replace("import 'core/config/env.dart';\n", "import 'core/config/env.dart';\nimport 'core/i18n/i18n.dart';\n", 1)
    open(p, 'w', encoding='utf-8').write(s)
    ed(L+'main.dart', [("  await initializeDateFormatting('ar');\n", "  await initializeDateFormatting('ar');\n  await initializeDateFormatting('en');\n  await AppLang.load();\n"),
        ("import 'core/config/env.dart';\n", "import 'core/config/env.dart';\nimport 'core/i18n/i18n.dart';\n")])

LANG_SHEET = "/// اختيار اللغة — يُحفظ ويعيد بناء التطبيق كاملًا باللغة الجديدة\nvoid showLanguageSheet(BuildContext context) => showModalBottomSheet<void>(\n      context: context,\n      builder: (ctx) {\n        Widget opt(String code, String label) => FnListRow(\n              title: label,\n              trailing: AppLang.code.value == code\n                  ? const Icon(Icons.check_circle_rounded, color: FnColors.primary, size: 20)\n                  : const Icon(Icons.circle_outlined, color: FnColors.border, size: 20),\n              onTap: () {\n                Navigator.pop(ctx);\n                if (AppLang.code.value != code) AppLang.set(code);\n              },\n            );\n        return SafeArea(\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),\n            child: Column(mainAxisSize: MainAxisSize.min, children: [\n              Container(width: 44, height: 5, decoration: BoxDecoration(color: FnColors.border, borderRadius: BorderRadius.circular(3))),\n              Padding(padding: const EdgeInsets.all(14), child: Text(tr('اللغة'), style: FnText.heading18)),\n              opt('ar', 'العربية'),\n              const FnDivider(),\n              opt('en', 'English'),\n            ]),\n          ),\n        );\n      },\n    );\n\n"
APP_BUILD = "    final router = ref.watch(appRouterProvider);\n    // تغيير اللغة يعيد بناء التطبيق كاملًا (المفتاح) مع الحفاظ على الشاشة الحالية في الموجّه\n    return ValueListenableBuilder<String>(\n      valueListenable: AppLang.code,\n      builder: (context, lang, _) {\n        final en = lang == 'en';\n        return MaterialApp.router(\n          key: ValueKey(lang),\n          title: en ? 'Fenaa' : Env.appName,\n          debugShowCheckedModeBanner: false,\n          theme: AppTheme.light,\n          routerConfig: router,\n          locale: en ? const Locale('en') : const Locale('ar', 'SA'),\n          supportedLocales: const [Locale('ar', 'SA'), Locale('en')],\n          localizationsDelegates: const [\n            GlobalMaterialLocalizations.delegate,\n            GlobalWidgetsLocalizations.delegate,\n            GlobalCupertinoLocalizations.delegate,\n          ],\n          builder: (context, child) => Directionality(\n            textDirection: en ? TextDirection.ltr : TextDirection.rtl,\n            child: child ?? const SizedBox.shrink(),\n          ),\n        );\n      },\n    );\n"

def run(app_root):
    os.chdir(app_root)
    if 'tr(' in open('lib/app.dart', encoding='utf-8').read() or 'AppLang' in open('lib/app.dart', encoding='utf-8').read():
        print('i18n already applied'); return
    n = 0
    for dp, _, fs in os.walk('lib'):
        for f in fs:
            p = os.path.join(dp, f)
            if f.endswith('.dart') and '/core/i18n/' not in p and process(p): n += 1
    manual()
    print(f'✅ i18n: {n} files wrapped, {len(KEYS)} strings')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
