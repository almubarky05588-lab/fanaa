"""Codemod 016: شاشة البداية لا تعلّق — مهلة، وجلسة منتهية ← دخول من جديد، وانقطاع ← يكمل للتطبيق."""
import sys, os

NEW_ROUTE = '''  Future<void> _route() async {
    final auth = ref.read(supabaseProvider).auth;
    String target = '/auth/type';
    try {
      if (auth.currentUser == null) {
        target = (await AppPrefs.roleChoice()) == 'customer' ? '/home' : '/auth/type';
      } else {
        ref.invalidate(profileProvider);
        final p = await ref.read(profileProvider.future).timeout(const Duration(seconds: 8));
        target = p == null ? '/auth/type' : (p.isMerchant ? '/m/dashboard' : '/home');
      }
    } on AuthException {
      // الجلسة انتهت ولا يمكن تجديدها — دخول من جديد
      await auth.signOut().catchError((_) {});
      target = '/auth/type';
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST301' || e.message.toLowerCase().contains('jwt')) {
        await auth.signOut().catchError((_) {});
        target = '/auth/type';
      } else {
        target = '/home';
      }
    } catch (_) {
      // بطء أو انقطاع: نكمل بدل التعليق (الشاشات تعيد المحاولة بنفسها)
      target = '/home';
    }
    if (mounted) context.go(target);
  }
'''

def run(root):
    os.chdir(root)
    p = 'lib/features/auth/splash_screen.dart'
    s = open(p, encoding='utf-8').read()
    if 'PGRST301' in s:
        print('016 already applied'); return
    i = s.index('  Future<void> _route() async {')
    j = s.index('  @override\n  Widget build(BuildContext context)')
    s = s[:i] + NEW_ROUTE + '\n' + s[j:]
    s = s.replace("import 'package:go_router/go_router.dart';\n",
                  "import 'package:go_router/go_router.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';\n", 1)
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 016 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
