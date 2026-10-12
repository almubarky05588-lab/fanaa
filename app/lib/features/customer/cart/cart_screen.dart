import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/coupon.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/coupon_repo.dart';
import '../../../data/repositories/order_repo.dart';
import '../checkout/checkout_state.dart';

/// 09 السلة
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key, this.nurseryId, this.isTab = false});
  final String? nurseryId;
  final bool isTab;
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _coupon = TextEditingController();
  String? _selectedNursery;
  CouponCheck? _applied;
  bool _checking = false;

  double _delivery(Cart c) {
    final n = c.nursery!;
    return (n.freeDeliveryOver != null && c.subtotal >= n.freeDeliveryOver!) ? 0.0 : n.deliveryFee;
  }

  /// الخصم الفعّال لهذه السلة فقط
  double _discountFor(Cart c) => (_applied?.ok == true && _applied?.nurseryId == c.nurseryId) ? _applied!.discount : 0;

  Future<void> _validate(Cart c, {bool silent = false}) async {
    final code = _coupon.text.trim();
    if (code.isEmpty) {
      setState(() => _applied = null);
      return;
    }
    setState(() => _checking = true);
    try {
      final r = await ref.read(couponRepoProvider).validate(nurseryId: c.nurseryId, code: code, subtotal: c.subtotal);
      if (!mounted) return;
      setState(() => _applied = r.ok ? r : null);
      if (!silent || !r.ok) {
        showFnSnack(context, r.ok ? '${r.message} — خصم ${Fmt.money(r.discount)}' : r.message, error: !r.ok);
      }
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _setQty(CartItem i, int q) async {
    await ref.read(orderRepoProvider).setQty(i.id, q);
    ref.invalidate(cartsProvider);
    // إعادة حساب الخصم على المجموع الجديد
    if (_applied != null) {
      final list = await ref.read(cartsProvider.future);
      final c = list.where((x) => x.nurseryId == _applied!.nurseryId).firstOrNull;
      if (c != null && mounted) await _validate(c, silent: true);
    }
  }

  Future<void> _clear(Cart c) async {
    await ref.read(orderRepoProvider).clearCart(c.id);
    setState(() => _applied = null);
    ref.invalidate(cartsProvider);
  }

  void _checkout(Cart c) {
    final discount = _discountFor(c);
    ref.read(checkoutDraftProvider.notifier).state = CheckoutDraft(
      nurseryId: c.nurseryId,
      nurseryName: c.nursery!.name,
      subtotal: c.subtotal,
      delivery: _delivery(c),
      discount: discount,
      coupon: discount > 0 ? _applied!.code : null,
    );
    context.push('/checkout/${c.nurseryId}');
  }

  @override
  Widget build(BuildContext context) {
    final carts = ref.watch(cartsProvider);
    return Scaffold(
      appBar: FnAppBar(
        title: 'السلة',
        showBack: !widget.isTab,
        action: carts.valueOrNull?.isNotEmpty == true
            ? GestureDetector(
                onTap: () {
                  final c = _current(carts.value!);
                  if (c != null) _clear(c);
                },
                child: Text('إفراغ السلة', style: FnText.label13.clay),
              )
            : null,
      ),
      body: carts.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(cartsProvider)),
        data: (list) {
          final c = _current(list);
          if (c == null) {
            return FnEmpty(
              title: 'سلتك فارغة',
              subtitle: 'تصفّح المشاتل وأضف نباتاتك المفضلة',
              icon: Icons.shopping_bag_outlined,
              action: SizedBox(width: 180, child: FnButton(label: 'تصفّح المتاجر', height: 50, onPressed: () => context.go('/stores'))),
            );
          }
          final n = c.nursery!;
          final delivery = _delivery(c);
          final discount = _discountFor(c);
          return ListView(
            padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 24),
            children: [
              if (list.length > 1) ...[
                SizedBox(
                  height: 40,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final x in list)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: FnChip(label: '${x.nursery?.name ?? ''} (${x.count})', selected: x.id == c.id,
                            onTap: () => setState(() => _selectedNursery = x.nurseryId)),
                      ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              FnCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                radius: 18,
                onTap: () => context.push('/store/${c.nurseryId}'),
                child: Row(children: [
                  Container(width: 34, height: 34, decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: FnLogoMark(size: 22, color: FnColors.deep, gradient: false))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(n.name, style: FnText.bodyStrong15)),
                  Text('${c.count} منتجات', style: FnText.caption11.muted),
                ]),
              ),
              const SizedBox(height: 14),
              for (final i in c.items) ...[
                _ItemRow(item: i, onQty: (q) => _setQty(i, q)),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  color: FnColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: discount > 0 ? Border.all(color: FnColors.primary, width: 1.2) : null,
                ),
                child: Row(children: [
                  if (discount > 0) ...[
                    const Icon(Icons.check_circle_rounded, size: 18, color: FnColors.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _coupon,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) { if (_applied != null) setState(() => _applied = null); },
                      onSubmitted: (_) => _validate(c),
                      decoration: InputDecoration(
                        hintText: 'أدخل كود الخصم', filled: false, isDense: true, contentPadding: EdgeInsets.zero,
                        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, hintStyle: FnText.body15.faint),
                    ),
                  ),
                  GestureDetector(
                    onTap: _checking
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            if (discount > 0) {
                              _coupon.clear();
                              setState(() => _applied = null);
                            } else {
                              _validate(c);
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(color: discount > 0 ? FnColors.bgBase : FnColors.soft, borderRadius: BorderRadius.circular(12)),
                      child: _checking
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: FnColors.deep))
                          : Text(discount > 0 ? 'إزالة' : 'تطبيق', style: discount > 0 ? FnText.label13.clay : FnText.label13.deep),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              FnCard(
                child: Column(children: [
                  FnKV('مجموع المنتجات', Fmt.money(c.subtotal)),
                  FnKV('رسوم التوصيل', delivery == 0 ? 'مجاني' : Fmt.money(delivery)),
                  if (discount > 0) FnKV('خصم الكوبون ${_applied!.code}', '− ${Fmt.money(discount)}', valueColor: FnColors.primary),
                  if (n.freeDeliveryOver != null && delivery > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('أضف ${Fmt.money(n.freeDeliveryOver! - c.subtotal)} للحصول على توصيل مجاني', style: FnText.caption11.primary),
                      ),
                    ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: FnDivider()),
                  FnKV('الإجمالي', Fmt.money((c.subtotal + delivery - discount).clamp(0, double.infinity)), strong: true),
                  Align(alignment: AlignmentDirectional.centerStart, child: Text('الأسعار شاملة ضريبة القيمة المضافة', style: FnText.caption11.faint)),
                ]),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: () {
        final list = carts.valueOrNull;
        final c = list == null ? null : _current(list);
        if (c == null) return null;
        final n = c.nursery!;
        final total = (c.subtotal + _delivery(c) - _discountFor(c)).clamp(0, double.infinity);
        final belowMin = c.subtotal < n.minOrder;
        return FnBottomBar(
          child: Row(children: [
            Expanded(
              child: FnButton(
                label: belowMin ? 'الحد الأدنى ${Fmt.moneyShort(n.minOrder)}' : 'إتمام الطلب',
                onPressed: belowMin ? null : () => _checkout(c),
              ),
            ),
            const SizedBox(width: 14),
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('الإجمالي', style: FnText.caption11.muted),
              Text(Fmt.moneyShort(total), style: FnText.heading18),
            ]),
          ]),
        );
      }(),
    );
  }

  Cart? _current(List<Cart> list) {
    if (list.isEmpty) return null;
    final want = _selectedNursery ?? widget.nurseryId;
    return list.where((c) => c.nurseryId == want).firstOrNull ?? list.first;
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onQty});
  final CartItem item;
  final ValueChanged<int> onQty;
  @override
  Widget build(BuildContext context) => FnCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          FnImage(url: item.product.cover, size: 72, radius: 16),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name, style: FnText.bodyStrong15, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (item.variant != null) Text('حجم ${item.variant!.name}', style: FnText.caption11.muted),
            const SizedBox(height: 4),
            Text(Fmt.moneyShort(item.unitPrice), style: FnText.label13.deep),
          ])),
          FnStepper(value: item.qty, vertical: true, onChanged: onQty),
        ]),
      );
}
