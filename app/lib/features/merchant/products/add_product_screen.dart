import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../core/i18n/i18n.dart';
import '../../auth/phone_login_screen.dart' show EnglishDigitsFormatter;
import '../../../core/widgets/image_source_sheet.dart';

/// 19 إضافة منتج
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});
  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();
  final _desc = TextEditingController();
  final _light = TextEditingController();
  final _water = TextEditingController();
  final _temp = TextEditingController();
  String? _categoryId;
  final _sizes = <String>{tr('متوسط')};
  final _images = <(String, Uint8List)>[];
  bool _available = true;
  bool _saving = false;

  Future<void> _pick() async {
    if (_images.length >= 5) return;
    final source = await pickImageSource(context);
    if (source == null) return;
    final picker = ImagePicker();
    // الكاميرا: صورة وحدة كل مرة — الاستديو: عدة صور (حتى ٥)
    final files = source == ImageSource.camera
        ? [if (await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1600) case final x?) x]
        : await picker.pickMultiImage(imageQuality: 80, maxWidth: 1600, limit: 5 - _images.length);
    for (final f in files) {
      _images.add((f.name, await f.readAsBytes()));
    }
    setState(() {});
  }

  Future<void> _save(Nursery n, {bool draft = false}) async {
    final price = double.tryParse(_price.text.replaceAll(',', '.'));
    if (_name.text.trim().isEmpty || price == null) {
      showFnSnack(context, tr('أدخل اسم المنتج والسعر'), error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(catalogRepoProvider);
      final urls = <String>[];
      for (final (name, bytes) in _images) {
        urls.add(await repo.uploadProductImage(n.id, name, bytes));
      }
      final qty = int.tryParse(_qty.text) ?? 0;
      final ordered = [tr('صغير'), tr('متوسط'), tr('كبير')].where(_sizes.contains).toList();
      // الحجم المتوسط = السعر المدخل، الصغير −٣٥٪، الكبير +٤٥٪ (يعدّلها التاجر لاحقًا)
      double priceFor(String s) => s == tr('صغير') ? (price * .65).roundToDouble() : s == tr('كبير') ? (price * 1.45).roundToDouble() : price;
      await repo.createProduct({
        'nursery_id': n.id,
        'category_id': _categoryId,
        'name': _name.text.trim(),
        'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        'images': urls,
        'base_price': price,
        'stock': ordered.length > 1 ? 0 : qty,
        'care_light': _light.text.trim().isEmpty ? null : _light.text.trim(),
        'care_water': _water.text.trim().isEmpty ? null : _water.text.trim(),
        'care_temp': _temp.text.trim().isEmpty ? null : _temp.text.trim(),
        'is_available': !draft && _available,
      }, ordered.length > 1
          ? [for (var i = 0; i < ordered.length; i++) {'name': ordered[i], 'price': priceFor(ordered[i]), 'stock': qty, 'sort': i}]
          : const []);
      if (mounted) {
        showFnSnack(context, draft ? tr('حُفظ كمسودة') : tr('تمت إضافة المنتج'));
        context.pop();
      }
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = ref.watch(myNurseryProvider).valueOrNull;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    return Scaffold(
      appBar: FnAppBar(title: tr('إضافة منتج')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 24),
        children: [
          GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FnColors.primary, width: 1.5)),
              child: _images.isEmpty
                  ? Column(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.add_rounded, color: FnColors.deep)),
                      const SizedBox(height: 8),
                      Text(tr('أضف صور المنتج'), style: FnText.bodyStrong15),
                      Text(tr('حتى ٥ صور • JPG أو PNG'), style: FnText.caption11.muted),
                    ])
                  : SizedBox(
                      height: 76,
                      child: ListView(scrollDirection: Axis.horizontal, children: [
                        for (var i = 0; i < _images.length; i++)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: Stack(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_images[i].$2, width: 76, height: 76, fit: BoxFit.cover)),
                              Positioned(top: 2, left: 2, child: GestureDetector(
                                onTap: () => setState(() => _images.removeAt(i)),
                                child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white)),
                              )),
                            ]),
                          ),
                        if (_images.length < 5)
                          Container(width: 76, height: 76, decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.add_rounded, color: FnColors.deep)),
                      ]),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          _field(tr('اسم المنتج'), TextField(controller: _name, decoration: InputDecoration(hintText: tr('مثال: نبتة مونستيرا')))),
          _field(tr('القسم'), DropdownButtonFormField<String>(
            value: _categoryId,
            hint: Text(tr('اختر القسم'), style: FnText.body15.faint),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FnColors.faint),
            decoration: const InputDecoration(),
            items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(tr(c.nameAr), style: FnText.body15))],
            onChanged: (v) => setState(() => _categoryId = v),
          )),
          Row(children: [
            Expanded(child: _field(tr('السعر (ر.س)'), TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [const EnglishDigitsFormatter(), FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))], decoration: const InputDecoration(hintText: '0.00')))),
            const SizedBox(width: 12),
            Expanded(child: _field(tr('الكمية'), TextField(controller: _qty, keyboardType: TextInputType.number,
                inputFormatters: [const EnglishDigitsFormatter(), FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(hintText: '0')))),
          ]),
          _field(tr('الأحجام المتاحة'), Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in [tr('صغير'), tr('متوسط'), tr('كبير')])
              FnChip(label: s, selected: _sizes.contains(s), height: 36,
                  onTap: () => setState(() => _sizes.contains(s) ? (_sizes.length > 1 ? _sizes.remove(s) : null) : _sizes.add(s))),
          ])),
          _field(tr('العناية (اختياري)'), Column(children: [
            TextField(controller: _light, decoration: InputDecoration(hintText: tr('الإضاءة: ضوء غير مباشر'))),
            const SizedBox(height: 8),
            TextField(controller: _water, decoration: InputDecoration(hintText: tr('الري: مرة أسبوعيًا'))),
            const SizedBox(height: 8),
            TextField(controller: _temp, decoration: InputDecoration(hintText: tr('الحرارة: ٢٠–٣٠°'))),
          ])),
          _field(tr('الوصف'), TextField(controller: _desc, maxLines: 3, decoration: InputDecoration(hintText: tr('اكتب وصفًا مختصرًا ومعلومات العناية')))),
          FnCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), radius: 16,
            child: Row(children: [
              Expanded(child: Text(tr('متوفر للبيع فور الحفظ'), style: FnText.body15)),
              FnSwitch(value: _available, onChanged: (v) => setState(() => _available = v)),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: FnBottomBar(
        child: Row(children: [
          SizedBox(width: 110, child: FnButton(label: tr('مسودة'), color: FnColors.bgBase, textColor: FnColors.ink,
              onPressed: n == null || _saving ? null : () => _save(n, draft: true))),
          const SizedBox(width: 12),
          Expanded(child: FnButton(label: tr('حفظ المنتج'), loading: _saving, onPressed: n == null ? null : () => _save(n))),
        ]),
      ),
    );
  }

  Widget _field(String label, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: FnText.label13.muted),
          const SizedBox(height: 6),
          child,
        ]),
      );
}
