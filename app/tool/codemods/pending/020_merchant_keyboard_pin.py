# Codemod 020: متجر واحد للتاجر (لا تكرار عند الإنشاء)، إنزال الكيبورد بالضغط خارج الخانات،
# خلفية شفافة لخانات الرمز، و«مستخدم» ← «عميل»
import sys, os

def ed(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:70])
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8').write(s)

def run(root):
    os.chdir(root)
    p = 'lib/features/merchant/setup/merchant_setup_screen.dart'
    if 'existing == null' in open(p, encoding='utf-8').read():
        print('020 already applied'); return

    # ١) إنشاء المتجر: لا ينشئ متجرًا ثانيًا، وينتظر تحديث البيانات قبل الانتقال
    ed(p, [
        ("      final row = await c.from('nurseries').insert({",
         "      // لو عنده متجر أصلًا (محاولة سابقة انحفظت) لا ننشئ متجرًا ثانيًا\n"
         "      final existing = await c.from('nurseries').select('id').eq('owner_id', user.id).limit(1).maybeSingle();\n"
         "      if (existing == null) {\n"
         "      final row = await c.from('nurseries').insert({"),
        ("      await c.from('nursery_payout').insert({'nursery_id': row['id'], 'iban': iban});\n      ref.invalidate(myNurseryProvider);",
         "      await c.from('nursery_payout').insert({'nursery_id': row['id'], 'iban': iban});\n"
         "      }\n"
         "      // ننتظر بيانات المتجر الجديدة قبل اللوحة (وإلا ترجع اللوحة لهذه الشاشة)\n"
         "      await ref.refresh(myNurseryProvider.future);"),
    ])
    ed('lib/data/repositories/catalog_repo.dart', [(
        "    final j = await _c.from('nurseries').select(nurseryCols).eq('owner_id', uid).maybeSingle();",
        "    final j = await _c.from('nurseries').select(nurseryCols).eq('owner_id', uid)\n"
        "        .order('created_at').limit(1).maybeSingle();",
    )])

    # ٢) الضغط في أي مكان فاضي ينزّل الكيبورد
    ed('lib/app.dart', [(
        "          builder: (context, child) => Directionality(\n"
        "            textDirection: en ? TextDirection.ltr : TextDirection.rtl,\n"
        "            child: child ?? const SizedBox.shrink(),\n"
        "          ),",
        "          builder: (context, child) => GestureDetector(\n"
        "            // الضغط خارج خانات الكتابة ينزّل الكيبورد\n"
        "            behavior: HitTestBehavior.translucent,\n"
        "            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),\n"
        "            child: Directionality(\n"
        "              textDirection: en ? TextDirection.ltr : TextDirection.rtl,\n"
        "              child: child ?? const SizedBox.shrink(),\n"
        "            ),\n"
        "          ),",
    )])

    # ٣) خانات الرمز: بدون خلفية بيضاء خلفها
    ed('lib/features/auth/otp_screen.dart', [
        ("                child: PinCodeTextField(\n                  appContext: context,",
         "                child: Theme(\n"
         "                  // الخانة المخفية خلف المربعات تاخذ تعبئة الخانات العادية — نلغيها\n"
         "                  data: Theme.of(context).copyWith(\n"
         "                    inputDecorationTheme: const InputDecorationTheme(filled: false, border: InputBorder.none,\n"
         "                        enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),\n"
         "                  ),\n"
         "                  child: PinCodeTextField(\n                  appContext: context,\n                  backgroundColor: Colors.transparent,"),
        ("                  onCompleted: (_) => _verify(),\n                ),\n              ),",
         "                  onCompleted: (_) => _verify(),\n                ),\n                ),\n              ),"),
    ])

    # ٤) «مستخدم» ← «عميل»
    ed('lib/features/auth/account_type_screen.dart', [("title: tr('مستخدم'),", "title: tr('عميل'),")])
    ed('lib/features/auth/phone_login_screen.dart', [("tr('تسجيل الدخول كمستخدم')", "tr('تسجيل الدخول كعميل')")])
    ed('lib/data/repositories/auth_repo.dart', [("سجّل الدخول من «مستخدم»", "سجّل الدخول من «عميل»")])
    p = 'lib/core/i18n/en.dart'
    s = open(p, encoding='utf-8').read()
    s = s.replace("\n};\n", "\n  'عميل': 'Customer',\n  'تسجيل الدخول كعميل': 'Sign in as a customer',\n"
                  "  'هذا الرقم مسجّل كعميل — سجّل الدخول من «عميل»': 'This number is registered as a customer — sign in as \"Customer\"',\n};\n")
    open(p, 'w', encoding='utf-8').write(s)
    print('020 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
