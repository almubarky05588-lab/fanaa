import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/location/location_picker.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/order_repo.dart';
import '../../../core/i18n/i18n.dart';

/// العناوين المحفوظة + إضافة عنوان
class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key, this.openAdd = false});
  final bool openAdd;
  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) WidgetsBinding.instance.addPostFrameCallback((_) => _add());
  }

  /// الخريطة أولًا (العميل يحدّد نقطة التوصيل بنفسه) ثم التفاصيل معبّأة من الخريطة
  Future<void> _add() async {
    final place = await pickLocation(context, title: tr('حدّد موقع التوصيل'));
    if (place == null || !mounted) return;
    final label = TextEditingController(text: tr('المنزل'));
    final line = TextEditingController(text: place.street ?? '');
    final district = TextEditingController(text: place.district ?? '');
    final city = TextEditingController(text: place.city ?? tr('الرياض'));
    final notes = TextEditingController();
    bool saving = false;
    final saved = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('عنوان جديد'), style: FnText.heading18),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place_rounded, size: 14, color: FnColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(tr('تم تحديد الموقع على الخريطة'), style: FnText.caption11.muted)),
            ]),
            const SizedBox(height: 14),
            for (final (c, h) in [(label, tr('اسم العنوان (المنزل، العمل)')), (line, tr('الشارع ورقم المبنى')), (district, tr('الحي')), (city, tr('المدينة')), (notes, tr('ملاحظات للمندوب (اختياري)'))])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(controller: c, decoration: InputDecoration(hintText: h, fillColor: FnColors.bgBase)),
              ),
            const SizedBox(height: 6),
            FnButton(label: tr('حفظ العنوان'), loading: saving, onPressed: () async {
              if (city.text.trim().isEmpty) return;
              setSheet(() => saving = true);
              try {
                await ref.read(orderRepoProvider).addAddress(
                      label: label.text.trim().isEmpty ? tr('المنزل') : label.text.trim(),
                      line: line.text.trim().isEmpty ? (place.summary.isEmpty ? tr('موقع محدد على الخريطة') : place.summary) : line.text.trim(),
                      district: district.text.trim(), city: city.text.trim(),
                      notes: notes.text.trim(), lat: place.lat, lng: place.lng, isDefault: true);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                setSheet(() => saving = false);
                if (ctx.mounted) showFnSnack(ctx, fnErrorText(e), error: true);
              }
            }),
          ]),
        ),
      )),
    );
    if (saved == true) ref.invalidate(addressesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final addrs = ref.watch(addressesProvider);
    return Scaffold(
      appBar: FnAppBar(
        title: tr('العناوين المحفوظة'),
        action: FnIconButton(color: FnColors.deep, radius: 14, size: 40, onTap: _add, child: const Icon(Icons.add_rounded, color: Colors.white, size: 20)),
      ),
      body: addrs.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(addressesProvider)),
        data: (list) => list.isEmpty
            ? FnEmpty(title: tr('لا توجد عناوين'), icon: Icons.location_off_outlined,
                action: SizedBox(width: 180, child: FnButton(label: tr('أضف عنوانًا'), height: 50, onPressed: _add)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => FnCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.location_on_outlined, color: FnColors.deep, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(list[i].label, style: FnText.bodyStrong15),
                      Text(tr('{0}، {1}', [list[i].line, list[i].full]), style: FnText.caption11.muted),
                    ])),
                    if (list[i].isDefault) FnBadge(tr('افتراضي')),
                  ]),
                ),
              ),
      ),
    );
  }
}
