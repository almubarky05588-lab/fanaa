import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';

/// زر دائري أبيض 44 مع سهم الرجوع — يظهر يمين العنوان في التصميم (RTL)
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
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(radius ?? size / 2),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius ?? size / 2),
          child: Container(
            width: size, height: size, alignment: Alignment.center,
            decoration: shadow ? BoxDecoration(borderRadius: BorderRadius.circular(radius ?? size / 2), boxShadow: FnShadow.card) : null,
            child: child,
          ),
        ),
      );
}

/// شريط علوي مطابق للتصميم: العنوان + زر رجوع على اليمين، وإجراء اختياري على اليسار
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
            child: Row(
              children: [
                if (showBack) FnBackButton(onTap: onBack),
                if (showBack) const SizedBox(width: 12),
                Expanded(child: Text(title, style: FnText.title22)),
                if (action != null) action!,
              ],
            ),
          ),
        ),
      );
}

class FnCard extends StatelessWidget {
  const FnCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = FnRadius.card,
      this.color = FnColors.surface, this.shadow = false, this.onTap, this.border = false});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final bool shadow;
  final bool border;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? FnShadow.card : null,
        border: border ? Border.all(color: FnColors.border) : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: box),
    );
  }
}

/// شريحة فلتر — داكنة عند التحديد
class FnChip extends StatelessWidget {
  const FnChip({super.key, required this.label, this.selected = false, this.onTap, this.height = 38, this.shadow = false});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double height;
  final bool shadow;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? FnColors.deep : FnColors.surface,
            borderRadius: BorderRadius.circular(FnRadius.pill),
            boxShadow: shadow ? [const BoxShadow(color: Color(0x0F0B2E20), blurRadius: 6, offset: Offset(0, 2))] : null,
          ),
          child: Text(label, style: selected ? FnText.label13.onDark : FnText.label13),
        ),
      );
}

/// شارة صغيرة (مفتوح الآن / جديد / متوفر)
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

/// الزر الرئيسي — أخضر عميق، ارتفاع 58، قطر 18
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
  Widget build(BuildContext context) {
    final btn = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color, foregroundColor: textColor, disabledBackgroundColor: color.withValues(alpha: .55),
        minimumSize: Size(expanded ? double.infinity : 0, height),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: loading
          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: textColor))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: FnText.bodyStrong15.copyWith(color: textColor)),
              if (icon != null) ...[const SizedBox(width: 8), icon!],
            ]),
    );
    return btn;
  }
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
        style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, height), side: BorderSide(color: borderColor, width: 1.2),
            foregroundColor: textColor),
        child: Text(label, style: FnText.bodyStrong15.copyWith(color: textColor)),
      );
}

/// شريط سفلي ثابت للزر الرئيسي (أبيض بظل علوي)
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

/// عدّاد الكمية (− ١ +)
class FnStepper extends StatelessWidget {
  const FnStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.compact = false});
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final s = compact ? 26.0 : 34.0;
    Widget btn(IconData i, VoidCallback? f, {bool dark = false}) => Material(
          color: dark ? FnColors.deep : FnColors.surface,
          borderRadius: BorderRadius.circular(compact ? 9 : 12),
          child: InkWell(
            onTap: f, borderRadius: BorderRadius.circular(compact ? 9 : 12),
            child: SizedBox(width: s, height: s, child: Icon(i, size: compact ? 14 : 18, color: dark ? FnColors.surface : FnColors.ink)),
          ),
        );
    return Container(
      padding: EdgeInsets.all(compact ? 6 : 8),
      decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(compact ? 14 : 18)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove_rounded, value > min ? () => onChanged(value - 1) : null),
        SizedBox(width: compact ? 26 : 34, child: Text('$value', textAlign: TextAlign.center, style: FnText.bodyStrong15)),
        btn(Icons.add_rounded, () => onChanged(value + 1), dark: true),
      ]),
    );
  }
}

/// صف قائمة: أيقونة + عنوان يمينًا، قيمة + سهم في أقصى اليسار
class FnListRow extends StatelessWidget {
  const FnListRow({super.key, required this.title, this.subtitle, this.icon, this.value, this.trailing, this.onTap, this.iconColor = FnColors.deep});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(children: [
            if (icon != null) ...[
              Container(width: 38, height: 38, decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, size: 19, color: iconColor)),
              const SizedBox(width: 12),
            ],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: FnText.body15),
              if (subtitle != null) Text(subtitle!, style: FnText.caption11.muted),
            ])),
            if (value != null) Text(value!, style: FnText.caption11.muted),
            if (value != null) const SizedBox(width: 8),
            trailing ?? const Icon(Icons.chevron_left_rounded, size: 18, color: FnColors.faint),
          ]),
        ),
      );
}

class FnDivider extends StatelessWidget {
  const FnDivider({super.key, this.opacity = .7});
  final double opacity;
  @override
  Widget build(BuildContext context) => Divider(color: FnColors.border.withValues(alpha: opacity));
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

/// صورة منتج/متجر مع بديل العلامة عند عدم وجود صورة
class FnImage extends StatelessWidget {
  const FnImage({super.key, this.url, this.size, this.width, this.height, this.radius = 16, this.bg = FnColors.soft, this.markColor = FnColors.primary});
  final String? url;
  final double? size, width, height;
  final double radius;
  final Color bg;
  final Color markColor;
  @override
  Widget build(BuildContext context) {
    final w = size ?? width, h = size ?? height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: w, height: h, color: bg, alignment: Alignment.center,
        child: (url == null || url!.isEmpty)
            ? FractionallySizedBox(widthFactor: .6, heightFactor: .6, child: FnLogoMarkColored(color: markColor))
            : Image.network(url!, fit: BoxFit.cover, width: w, height: h,
                errorBuilder: (_, __, ___) => FractionallySizedBox(widthFactor: .6, heightFactor: .6, child: FnLogoMarkColored(color: markColor))),
      ),
    );
  }
}

class FnLogoMarkColored extends StatelessWidget {
  const FnLogoMarkColored({super.key, required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) => Center(child: _Mark(size: c.maxWidth, color: color)));
}

class _Mark extends StatelessWidget {
  const _Mark({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    // يستدعي العلامة من fn_logo.dart بدون تدرّج
    return FnLogoMarkProxy(size: size, color: color);
  }
}

/// وكيل بسيط لتجنّب الاستيراد الدائري
class FnLogoMarkProxy extends StatelessWidget {
  const FnLogoMarkProxy({super.key, required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => _LogoHolder.build(size, color);
}

abstract final class _LogoHolder {
  static Widget Function(double, Color) build = (s, c) => SizedBox(width: s, height: s);
  static void register(Widget Function(double, Color) b) => build = b;
}

/// يُستدعى مرة واحدة من main لربط العلامة
void registerLogoMark(Widget Function(double, Color) builder) => _LogoHolder.register(builder);

class FnLoading extends StatelessWidget {
  const FnLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: FnColors.primary));
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

void showFnSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? FnColors.clay : FnColors.deep));
}
