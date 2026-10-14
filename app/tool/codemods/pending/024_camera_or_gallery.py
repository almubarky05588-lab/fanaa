# Codemod 024: صور المنتج والشعار والغلاف — اختيار بين الكاميرا والاستديو
import sys, os

def ed(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:70])
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8').write(s)

def add_import(p, line):
    s = open(p, encoding='utf-8').read()
    if line in s:
        return
    i = s.rfind("\nimport ", 0, s.find('\nclass '))
    j = s.index(';\n', i) + 2
    open(p, 'w', encoding='utf-8').write(s[:j] + line + s[j:])

def run(root):
    os.chdir(root)
    p = 'lib/features/merchant/products/add_product_screen.dart'
    if 'pickImageSource' in open(p, encoding='utf-8').read():
        print('024 already applied'); return
    ed(p, [(
        "    final files = await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1600, limit: 5 - _images.length);\n",
        "    final source = await pickImageSource(context);\n"
        "    if (source == null) return;\n"
        "    final picker = ImagePicker();\n"
        "    // الكاميرا: صورة وحدة كل مرة — الاستديو: عدة صور (حتى ٥)\n"
        "    final files = source == ImageSource.camera\n"
        "        ? [if (await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1600) case final x?) x]\n"
        "        : await picker.pickMultiImage(imageQuality: 80, maxWidth: 1600, limit: 5 - _images.length);\n",
    )])
    add_import(p, "import '../../../core/widgets/image_source_sheet.dart';\n")

    p = 'lib/features/merchant/settings/merchant_settings_screen.dart'
    ed(p, [(
        "    final x = await ImagePicker().pickImage(\n      source: ImageSource.gallery,",
        "    final source = await pickImageSource(context);\n"
        "    if (source == null) return null;\n"
        "    final x = await ImagePicker().pickImage(\n      source: source,",
    )])
    add_import(p, "import '../../../core/widgets/image_source_sheet.dart';\n")

    p = 'lib/core/i18n/en.dart'
    s = open(p, encoding='utf-8').read()
    for k, v in (('التقاط صورة', 'Take a photo'), ('اختيار من الاستديو', 'Choose from library')):
        if f"  '{k}':" not in s:
            s = s.replace("\n};\n", f"\n  '{k}': '{v}',\n}};\n")
    open(p, 'w', encoding='utf-8').write(s)
    print('024 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
