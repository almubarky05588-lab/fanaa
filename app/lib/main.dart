import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/i18n/i18n.dart';

Future<void> main() async {
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
      runApp(_StartupError(problems.join('\n')));
      return;
    }
    runApp(const ProviderScope(child: FenaaApp()));
  }, (e, st) {
    debugPrint('fenaa uncaught: $e\n$st');
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
