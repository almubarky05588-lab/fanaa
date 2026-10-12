import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/location/location.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/order_repo.dart';

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

  Future<void> _add() async {
    final label = TextEditingController(text: 'المنزل');
    final line = TextEditingController();
    final district = TextEditingController();
    final city = TextEditingController(text: 'الرياض');
    final notes = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('عنوان جديد', style: FnText.heading18),
            const SizedBox(height: 4),
            Text('سنستخدم موقعك الحالي لتحديد نقطة التوصيل', style: FnText.caption11.muted),
            const SizedBox(height: 14),
            for (final (c, h) in [(label, 'اسم العنوان (المنزل، العمل)'), (line, 'الشارع ورقم المبنى'), (district, 'الحي'), (city, 'المدينة'), (notes, 'ملاحظات للمندوب (اختياري)')])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(controller: c, decoration: InputDecoration(hintText: h, fillColor: FnColors.bgBase)),
              ),
            const SizedBox(height: 6),
            FnButton(label: 'حفظ العنوان', onPressed: () async {
              if (line.text.trim().isEmpty || city.text.trim().isEmpty) return;
              final loc = await ref.read(currentLocationProvider.future);
              await ref.read(orderRepoProvider).addAddress(
                    label: label.text.trim(), line: line.text.trim(), district: district.text.trim(), city: city.text.trim(),
                    notes: notes.text.trim(), lat: loc.lat, lng: loc.lng, isDefault: true);
              if (ctx.mounted) Navigator.pop(ctx, true);
            }),
          ]),
        ),
      ),
    );
    if (saved == true) ref.invalidate(addressesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final addrs = ref.watch(addressesProvider);
    return Scaffold(
      appBar: FnAppBar(
        title: 'العناوين المحفوظة',
        action: FnIconButton(color: FnColors.deep, radius: 14, size: 40, onTap: _add, child: const Icon(Icons.add_rounded, color: Colors.white, size: 20)),
      ),
      body: addrs.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(addressesProvider)),
        data: (list) => list.isEmpty
            ? FnEmpty(title: 'لا توجد عناوين', icon: Icons.location_off_outlined,
                action: SizedBox(width: 180, child: FnButton(label: 'أضف عنوانًا', height: 50, onPressed: _add)))
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
                      Text('${list[i].line}، ${list[i].full}', style: FnText.caption11.muted),
                    ])),
                    if (list[i].isDefault) const FnBadge('افتراضي'),
                  ]),
                ),
              ),
      ),
    );
  }
}
