import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
export 'fn_image.dart';

/// زر دائري أبيض مع سهم الرجوع — يظهر يمين العنوان (RTL)
class FnBackButton extends StatelessWidget {
  const FnBackButton({super.key, this.onTap, this.size = 44});
  final VoidCallback? onTap;
  final double size;
  @override
  Widget build(BuildContext context) => FnIconButton(
        size: size,
        onTap: onTap ?? () => context.canPop() ? context.pop() : context.go('/'),
        child: const Icon(Icons.chevron_right_rounded, size: 24, color: FnColors.ink),
      );
}

class FnIconButton extends StatelessWidget {
  const FnIconButton({super.key, required this.child, this.onTap, this.size = 44, this.color = FnColors.surface,
      this.radius, this.shadow = false});
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final double? radius;
  final bool shadow;
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? size / 2);
    return Container(
      decoration: BoxDecoration(borderRadius: r, boxShadow: shadow ? FnShadow.card : null),
      child: Material(
        color: color,
        borderRadius: r,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          child: SizedBox(width: size, height: size, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// شريط علوي: زر رجوع يمينًا ثم العنوان، وإجراء اختياري يسارًا
class FnAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FnAppBar({super.key, required this.title, this.showBack = true, this.action, this.onBack});
  final String title;
  final bool showBack;
  final Widget? action;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 0),
          child: SizedBox(
            height: 56,
            child: Row(children: [
              if (showBack) FnBackButton(onTap: onBack),
              if (showBack) const SizedBox(width: 12),
              Expanded(child: Text(title, style: FnText.title22)),
              if (action != null) action!,
            ]),
          ),
        ),
      );
}

class FnCard extends StatelessWidget {
  const FnCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = FnRadius.card,
      this.color = FnColors.surface, this.shadow = false, this.onTap, this.border = false, this.borderColor = FnColors.border});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final bool shadow;
  final bool border;
  final Color borderColor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? FnShadow.card : null,
        border: border ? Border.all(color: borderColor, width: borderColor == FnColors.border ? 1 : 1.5) : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: box));
  }
}

class FnChip extends StatelessWidget {
  const FnChip({super.key, required this.label, this.selected = false, this.onTap, this.height = 38, this.shadow = false, this.small = false});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double height;
  final bool shadow;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final st = small ? FnText.caption11 : FnText.label13;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: small ? 32 : height,
        padding: EdgeInsets.symmetric(horizontal: small ? 14 : 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? FnColors.deep : FnColors.surface,
          borderRadius: BorderRadius.circular(FnRadius.pill),
          boxShadow: shadow ? const [BoxShadow(color: Color(0x0F0B2E20), blurRadius: 6, offset: Offset(0, 2))] : null,
        ),
        child: Text(label, style: selected ? st.onDark : (small ? st.muted : st)),
      ),
    );
  }
}

class FnBadge extends StatelessWidget {
  const FnBadge(this.label, {super.key, this.bg = FnColors.soft, this.fg = FnColors.deep});
  final String label;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(FnRadius.pill)),
        child: Text(label, style: FnText.caption11.copyWith(color: fg)),
      );
}

class FnButton extends StatelessWidget {
  const FnButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon, this.height = 58,
      this.color = FnColors.deep, this.textColor = FnColors.surface, this.expanded = true});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? icon;
  final double height;
  final Color color;
  final Color textColor;
  final bool expanded;
  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color, foregroundColor: textColor,
          disabledBackgroundColor: color.withValues(alpha: .5), disabledForegroundColor: textColor.withValues(alpha: .8),
          minimumSize: Size(expanded ? double.infinity : 0, height),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FnRadius.md)),
        ),
        child: loading
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: textColor))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: FnText.bodyStrong15.copyWith(color: textColor)),
                if (icon != null) ...[const SizedBox(width: 8), IconTheme(data: IconThemeData(color: textColor), child: icon!)],
              ]),
      );
}

class FnGhostButton extends StatelessWidget {
  const FnGhostButton({super.key, required this.label, this.onPressed, this.height = 54, this.borderColor = FnColors.border,
      this.textColor = FnColors.ink});
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color borderColor;
  final Color textColor;
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, height),
          side: BorderSide(color: borderColor, width: 1.2),
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: FnText.bodyStrong15.copyWith(color: textColor)),
      );
}

class FnBottomBar extends StatelessWidget {
  const FnBottomBar({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: FnColors.surface, boxShadow: FnShadow.bar),
        padding: const EdgeInsets.fromLTRB(FnSpace.page, 14, FnSpace.page, 10),
        child: SafeArea(top: false, child: child),
      );
}

/// عدّاد الكمية — أفقي (صفحة المنتج) أو عمودي مضغوط (السلة)
class FnStepper extends StatelessWidget {
  const FnStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.vertical = false});
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final bool vertical;
  @override
  Widget build(BuildContext context) {
    final s = vertical ? 26.0 : 34.0;
    final r = vertical ? 9.0 : 12.0;
    Widget btn(IconData i, VoidCallback? f, {bool dark = false}) => Material(
          color: dark ? FnColors.deep : FnColors.surface,
          borderRadius: BorderRadius.circular(r),
          child: InkWell(
            onTap: f, borderRadius: BorderRadius.circular(r),
            child: SizedBox(width: s, height: s,
                child: Icon(i, size: vertical ? 14 : 18, color: dark ? FnColors.surface : (f == null ? FnColors.faint : FnColors.ink))),
          ),
        );
    final children = [
      btn(Icons.add_rounded, () => onChanged(value + 1), dark: true),
      SizedBox(width: vertical ? s : 34, height: vertical ? 24 : null,
          child: Center(child: Text('$value', style: vertical ? FnText.label13 : FnText.bodyStrong15))),
      btn(Icons.remove_rounded, value > min ? () => onChanged(value - 1) : null),
    ];
    return Container(
      padding: EdgeInsets.all(vertical ? 6 : 8),
      decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(vertical ? 14 : 18)),
      child: vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: children)
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// صف قائمة: أيقونة + عنوان يمينًا، والقيمة ثم السهم في أقصى اليسار
class FnListRow extends StatelessWidget {
  const FnListRow({super.key, required this.title, this.subtitle, this.icon, this.value, this.trailing, this.onTap,
      this.iconColor = FnColors.deep, this.titleStyle});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;
  final TextStyle? titleStyle;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(children: [
            if (icon != null) ...[
              Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, size: 19, color: iconColor)),
              const SizedBox(width: 12),
            ],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: titleStyle ?? FnText.body15),
              if (subtitle != null) Text(subtitle!, style: FnText.caption11.muted),
            ])),
            if (value != null) ...[Text(value!, style: FnText.caption11.muted), const SizedBox(width: 8)],
            trailing ?? const Icon(Icons.chevron_left_rounded, size: 18, color: FnColors.faint),
          ]),
        ),
      );
}

class FnDivider extends StatelessWidget {
  const FnDivider({super.key, this.indent = 0});
  final double indent;
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, indent: indent, endIndent: indent, color: FnColors.border.withValues(alpha: .7));
}

class FnSectionTitle extends StatelessWidget {
  const FnSectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: FnText.heading18)),
        if (action != null) GestureDetector(onTap: onAction, child: Text(action!, style: FnText.label13.primary)),
      ]);
}

/// صف مفتاح/قيمة لملخّصات المبالغ
class FnKV extends StatelessWidget {
  const FnKV(this.k, this.v, {super.key, this.strong = false, this.valueColor});
  final String k, v;
  final bool strong;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(k, style: strong ? FnText.heading18 : FnText.body15.muted)),
          Text(v, style: (strong ? FnText.heading18.deep : FnText.bodyStrong15).copyWith(color: valueColor)),
        ]),
      );
}

class FnLoading extends StatelessWidget {
  const FnLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: FnColors.primary, strokeWidth: 2.4));
}

class FnEmpty extends StatelessWidget {
  const FnEmpty({super.key, required this.title, this.subtitle, this.icon = Icons.eco_outlined, this.action});
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 72, height: 72, decoration: const BoxDecoration(color: FnColors.soft, shape: BoxShape.circle),
                child: Icon(icon, color: FnColors.deep, size: 32)),
            const SizedBox(height: 16),
            Text(title, style: FnText.heading18, textAlign: TextAlign.center),
            if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: FnText.body15.muted, textAlign: TextAlign.center)],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}

class FnError extends StatelessWidget {
  const FnError({super.key, this.onRetry});
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => FnEmpty(
        title: 'تعذّر التحميل',
        subtitle: 'تحقّق من الاتصال وحاول مجددًا',
        icon: Icons.wifi_off_rounded,
        action: onRetry == null ? null : SizedBox(width: 160, child: FnButton(label: 'إعادة المحاولة', height: 48, onPressed: onRetry)),
      );
}

class FnSwitch extends StatelessWidget {
  const FnSwitch({super.key, required this.value, this.onChanged, this.lime = false});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool lime;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44, height: 26, padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? (lime ? FnColors.lime : FnColors.deep) : FnColors.border,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: value ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(width: 20, height: 20,
              decoration: BoxDecoration(color: lime && value ? FnColors.deep : FnColors.surface, shape: BoxShape.circle)),
        ),
      );
}

void showFnSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? FnColors.clay : FnColors.deep));
}

/// يستخرج رسالة الخطأ العربية القادمة من دوال قاعدة البيانات
String fnErrorText(Object e) {
  final s = e.toString();
  final m = RegExp(r'message: ([^,]+)').firstMatch(s);
  return (m?.group(1) ?? 'حدث خطأ غير متوقع').trim();
}
