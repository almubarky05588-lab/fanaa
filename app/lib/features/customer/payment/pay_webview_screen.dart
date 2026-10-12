import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';

/// صفحة الدفع من ماي فاتورة داخل التطبيق — تُغلق تلقائيًا عند الرجوع لروابط fenaa.netlify.app/pay/
/// ترجع true لو وصل لرابط النجاح (التأكيد الفعلي يتم بالخادم بعدها)
class PayWebViewScreen extends StatefulWidget {
  const PayWebViewScreen({super.key, required this.url});
  final String url;

  static Future<bool?> open(BuildContext context, String url) => Navigator.of(context, rootNavigator: true)
      .push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => PayWebViewScreen(url: url)));

  @override
  State<PayWebViewScreen> createState() => _PayWebViewScreenState();
}

class _PayWebViewScreenState extends State<PayWebViewScreen> {
  static const _returnPrefix = 'https://fenaa.netlify.app/pay/';
  late final WebViewController _c;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (r) {
          if (r.url.startsWith(_returnPrefix)) {
            Navigator.pop(context, r.url.startsWith('${_returnPrefix}done'));
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: FnColors.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.close_rounded, color: FnColors.ink), onPressed: () => Navigator.pop(context, false)),
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline_rounded, size: 16, color: FnColors.primary),
            const SizedBox(width: 6),
            Text(tr('دفع آمن ومشفّر'), style: FnText.bodyStrong15),
          ]),
        ),
        body: Stack(children: [
          WebViewWidget(controller: _c),
          if (_loading) const FnLoading(),
        ]),
      );
}
