"""يرفع الإضافات القديمة (مثل geocoding) لتُبنى على Android SDK 36 — يرفع القديم فقط ولا ينزّل الأحدث.
الاستخدام: python3 tool/patch_android_root.py android
"""
import os, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "android"
FORCE_SDK = 36

KTS_BLOCK = """// fenaa-force-compileSdk: بعض الإضافات القديمة مبنية على SDK أقدم
subprojects {
    afterEvaluate {
        if (project.name == "app") return@afterEvaluate
        val ext = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val cur = (ext.javaClass.getMethod("getCompileSdkVersion").invoke(ext) as? String)
                ?.removePrefix("android-")?.toIntOrNull() ?: 0
            if (cur < __SDK__) ext.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType).invoke(ext, __SDK__)
        } catch (e: Exception) {
            println("fenaa: compileSdk not forced for ${project.name}")
        }
    }
}

""".replace("__SDK__", str(FORCE_SDK))

GROOVY_BLOCK = """// fenaa-force-compileSdk
subprojects {
    afterEvaluate { p ->
        if (p.name != 'app' && p.hasProperty('android')) {
            def cur = (p.android.compileSdkVersion ?: 'android-0').toString().replace('android-', '')
            if ((cur.isInteger() ? cur as int : 0) < __SDK__) { p.android.compileSdkVersion __SDK__ }
        }
    }
}

""".replace("__SDK__", str(FORCE_SDK))

for name, block in (("build.gradle.kts", KTS_BLOCK), ("build.gradle", GROOVY_BLOCK)):
    path = os.path.join(ROOT, name)
    if not os.path.exists(path):
        continue
    r = open(path, encoding="utf-8").read()
    if "fenaa-force-compileSdk" not in r:
        i = r.find("subprojects {")
        r = (r[:i] + block + r[i:]) if i >= 0 else (r + "\n" + block)
        open(path, "w", encoding="utf-8").write(r)
    print(f"✅ {name} (root)")
    break

# ------------------------------------------------ تعطيل الضغط (R8) في نسخة الإصدار
# يشيل أحيانًا أجزاء تحتاجها الإضافات فيتوقف التطبيق عند التشغيل
for name in ("build.gradle.kts", "build.gradle"):
    path = os.path.join(ROOT, "app", name)
    if not os.path.exists(path):
        continue
    g = open(path, encoding="utf-8").read()
    if "fenaa-no-shrink" not in g:
        kts = name.endswith(".kts")
        line = ("            // fenaa-no-shrink\n            isMinifyEnabled = false\n            isShrinkResources = false\n"
                if kts else "            // fenaa-no-shrink\n            minifyEnabled false\n            shrinkResources false\n")
        i = g.find("release {", g.find("buildTypes"))
        if i >= 0:
            j = i + len("release {")
            g = g[:j] + "\n" + line + g[j:]
            open(path, "w", encoding="utf-8").write(g)
    print(f"✅ app/{name}: بدون ضغط")
    break
