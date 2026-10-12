import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fn_widgets.dart';

/// شاشة مؤقتة للمسارات التي لم تُبن بعد
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key, this.showBack = true});
  final String title;
  final bool showBack;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: FnAppBar(title: title, showBack: showBack),
        body: Center(child: Text('قيد الإنشاء', style: FnText.body15.muted)),
      );
}
