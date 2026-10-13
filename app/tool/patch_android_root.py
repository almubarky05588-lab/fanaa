"""يجبر الإضافات القديمة (مثل geocoding) على البناء بـ Android SDK 35.
الاستخدام: python3 tool/patch_android_root.py android
"""
import os, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "android"

# ------------------------------------------------ build.gradle الجذري: مكتبات قديمة (مثل geocoding) تُبنى على Android 35
root_kts = os.path.join(ROOT, "build.gradle.kts")
root_groovy = os.path.join(ROOT, "build.gradle")
FORCE_SDK = 35
if os.path.exists(root_kts):
    r = open(root_kts, encoding="utf-8").read()
    if "fenaa-force-compileSdk" not in r:
        block = (f"// fenaa-force-compileSdk: بعض الإضافات القديمة مبنية على SDK 33\n"
                 "subprojects {\n"
                 "    afterEvaluate {\n"
                 "        if (project.name == \"app\") return@afterEvaluate\n"
                 "        val ext = extensions.findByName(\"android\") ?: return@afterEvaluate\n"
                 "        try {\n"
                 f"            ext.javaClass.getMethod(\"compileSdkVersion\", Int::class.javaPrimitiveType).invoke(ext, {FORCE_SDK})\n"
                 "        } catch (e: Exception) {\n"
                 "            println(\"fenaa: compileSdk not forced for ${project.name}\")\n"
                 "        }\n"
                 "    }\n"
                 "}\n\n")
        i = r.find("subprojects {")
        r = (r[:i] + block + r[i:]) if i >= 0 else (r + "\n" + block)
        open(root_kts, "w", encoding="utf-8").write(r)
    print("✅ build.gradle.kts (root)")
elif os.path.exists(root_groovy):
    r = open(root_groovy, encoding="utf-8").read()
    if "fenaa-force-compileSdk" not in r:
        block = ("// fenaa-force-compileSdk\n"
                 "subprojects {\n"
                 "    afterEvaluate { p ->\n"
                 f"        if (p.hasProperty('android')) {{ p.android.compileSdkVersion {FORCE_SDK} }}\n"
                 "    }\n"
                 "}\n\n")
        i = r.find("subprojects {")
        r = (r[:i] + block + r[i:]) if i >= 0 else (r + "\n" + block)
        open(root_groovy, "w", encoding="utf-8").write(r)
    print("✅ build.gradle (root)")
