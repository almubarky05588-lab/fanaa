# Codemod 025: تشغيل محمي — كل خطوة لها مهلة، وأي خطأ يظهر على الشاشة بدل التعليق على شاشة البداية
import sys, os

ORIG = """Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  await AppLang.load();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey);
  runApp(const ProviderScope(child: FenaaApp()));
}
"""

NEW = """Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final problems = <String>[];
    // كل خطوة محمية بمهلة — فشل خطوة لا يعلّق التطبيق على شاشة البداية
    Future<bool> step(String name, Future<void> Function() run) async {
      try {
        await run().timeout(const Duration(seconds: 12));
        return true;
      } catch (e) {
        problems.add('$name: $e');
        debugPrint('fenaa startup [$name] failed: $e');
        return false;
      }
    }

    await step('orientation', () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    await step('intl-ar', () => initializeDateFormatting('ar'));
    await step('intl-en', () => initializeDateFormatting('en'));
    await step('lang', AppLang.load);
    final ok = await step('supabase', () => Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey));

    if (!ok) {
      runApp(_StartupError(problems.join('\\n')));
      return;
    }
    runApp(const ProviderScope(child: FenaaApp()));
  }, (e, st) {
    debugPrint('fenaa uncaught: $e\\n$st');
    // خطأ قبل أول شاشة → نعرضه بدل الشاشة البيضاء
    if (WidgetsBinding.instance.rootElement == null) runApp(_StartupError('$e'));
  });
}

/// شاشة تظهر لو فشل تشغيل التطبيق — فيها نص الخطأ للتشخيص
class _StartupError extends StatelessWidget {
  const _StartupError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F3EE),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 40),
                  const Text('تعذّر تشغيل فناء', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0B2E20))),
                  const SizedBox(height: 8),
                  const Text('صوّر هذه الشاشة وأرسلها للدعم', style: TextStyle(fontSize: 15, color: Color(0xFF5D6B63))),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: SelectableText(message, style: const TextStyle(fontSize: 13, color: Color(0xFF8A3B1A))),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
"""

def run(root):
    os.chdir(root)
    p = 'lib/main.dart'
    s = open(p, encoding='utf-8').read()
    if '_StartupError' in s:
        print('025 already applied'); return
    assert s.count(ORIG) == 1
    s = s.replace(ORIG, NEW)
    s = s.replace("import 'package:flutter/material.dart';\n", "import 'dart:async';\nimport 'package:flutter/material.dart';\n", 1)
    open(p, 'w', encoding='utf-8').write(s)
    print('025 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
