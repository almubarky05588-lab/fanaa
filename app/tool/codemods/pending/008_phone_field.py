"""Codemod 008: حقل الجوال — الضغط في أي مكان من الصندوق يفتح الكيبورد، فتح تلقائي، وفلتر لا يلمس حالة الكتابة."""
import sys, os

NEW_CLASS = "class PhoneField extends StatefulWidget {\n  const PhoneField({super.key, required this.controller, this.onChanged, this.onSubmitted, this.autofocus = true});\n  final TextEditingController controller;\n  final ValueChanged<String>? onChanged;\n  final ValueChanged<String>? onSubmitted;\n  final bool autofocus;\n  @override\n  State<PhoneField> createState() => _PhoneFieldState();\n}\n\nclass _PhoneFieldState extends State<PhoneField> {\n  final _focus = FocusNode();\n\n  @override\n  void dispose() {\n    _focus.dispose();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) => GestureDetector(\n        // الضغط في أي مكان من الصندوق يفتح الكيبورد\n        behavior: HitTestBehavior.opaque,\n        onTap: () => _focus.requestFocus(),\n        child: Container(\n          height: 58,\n          padding: const EdgeInsets.all(8),\n          decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(FnRadius.field)),\n          child: Directionality(\n            textDirection: TextDirection.ltr,\n            child: Row(children: [\n              Container(\n                height: 42,\n                padding: const EdgeInsets.symmetric(horizontal: 12),\n                decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(10)),\n                child: Row(children: [\n                  ClipRRect(borderRadius: BorderRadius.circular(3),\n                      child: SvgPicture.asset('assets/brand/flag_sa.svg', width: 24, height: 16, fit: BoxFit.cover)),\n                  const SizedBox(width: 8),\n                  Text('+966', style: FnText.label13),\n                ]),\n              ),\n              const SizedBox(width: 10),\n              Expanded(\n                child: TextField(\n                  controller: widget.controller,\n                  focusNode: _focus,\n                  autofocus: widget.autofocus,\n                  onChanged: widget.onChanged,\n                  onSubmitted: widget.onSubmitted,\n                  keyboardType: TextInputType.phone,\n                  textAlign: TextAlign.left,\n                  style: FnText.body15,\n                  inputFormatters: const [EnglishDigitsFormatter(), SaudiMobileFormatter()],\n                  decoration: InputDecoration(\n                    hintText: '5X XXX XXXX',\n                    hintStyle: FnText.body15.faint,\n                    filled: false, isDense: true, border: InputBorder.none, enabledBorder: InputBorder.none,\n                    focusedBorder: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12),\n                  ),\n                ),\n              ),\n            ]),\n          ),\n        ),\n      );\n}\n\n"

def run(root):
    os.chdir(root)
    p = 'lib/features/auth/phone_login_screen.dart'
    s = open(p, encoding='utf-8').read()
    if '_PhoneFieldState' in s:
        print('008 already applied'); return
    i = s.index('class PhoneField extends StatelessWidget {')
    j = s.index('/// يحوّل الأرقام العربية')
    s = s[:i] + NEW_CLASS + s[j:]
    old = "    if (d.length > 9) d = d.substring(0, 9);\n    return TextEditingValue("
    assert s.count(old) == 1
    s = s.replace(old, "    if (d.length > 9) d = d.substring(0, 9);\n    // بدون تغيير فعلي: نرجّع القيمة كما هي (لا نلمس حالة الكتابة عند iOS)\n    if (d == newValue.text) return newValue;\n    return TextEditingValue(")
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 008 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
