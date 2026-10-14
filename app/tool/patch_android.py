"""يجهّز مشروع أندرويد المولَّد: الاسم، الصلاحيات، مفتاح الخرائط، الرجوع من الدفع، روابط المشاركة، الحد الأدنى للنظام، التوقيع.
الاستخدام: GOOGLE_MAPS_ANDROID_KEY=... python3 tool/patch_android.py android
"""
import os, re, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "android"
# مفتاح خرائط قوقل لأندرويد (يوضع داخل ملف التطبيق أصلًا — يُفضّل قفله على الحزمة sa.almubarky.fenaa)
ANDROID_MAPS_KEY = "AIzaSyBgtm2HsISKec-VRlPjHBSkz3pD83pujms"
MAPS_KEY = (os.environ.get("GOOGLE_MAPS_ANDROID_KEY") or ANDROID_MAPS_KEY).strip()
LINK_HOST = "fanaa-15r.pages.dev"
MIN_SDK = 23

# ------------------------------------------------ AndroidManifest.xml
p = os.path.join(ROOT, "app", "src", "main", "AndroidManifest.xml")
s = open(p, encoding="utf-8").read()

s = re.sub(r'android:label="[^"]*"', 'android:label="فناء"', s, count=1)

perms = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.CAMERA",
]
block = "".join(f'    <uses-permission android:name="{x}"/>\n' for x in perms if x not in s)
if block:
    s = s.replace("<application", block + "    <application", 1)

app_extra = f'''
        <meta-data android:name="com.google.android.geo.API_KEY" android:value="{MAPS_KEY}"/>
        <!-- الرجوع من صفحة الدفع (fenaa://pay/...) -->
        <activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true">
            <intent-filter android:label="flutter_web_auth_2">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="fenaa"/>
            </intent-filter>
        </activity>
'''
if "com.google.android.geo.API_KEY" not in s:
    s = s.replace("    </application>", app_extra + "    </application>", 1)

links = f'''            <!-- روابط مشاركة المتاجر والمنتجات تفتح التطبيق -->
            <meta-data android:name="flutter_deeplinking_enabled" android:value="true"/>
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="https" android:host="{LINK_HOST}" android:pathPrefix="/store"/>
                <data android:scheme="https" android:host="{LINK_HOST}" android:pathPrefix="/product"/>
            </intent-filter>
'''
if "flutter_deeplinking_enabled" not in s:
    i = s.index('android:name=".MainActivity"')
    j = s.index("</activity>", i)
    s = s[:j] + links + "        " + s[j:]

queries = '''        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="geo"/></intent>
'''
if 'android:scheme="tel"' not in s:
    if "<queries>" in s:
        s = s.replace("<queries>", "<queries>\n" + queries, 1)
    else:
        s = s.replace("</manifest>", "    <queries>\n" + queries + "    </queries>\n</manifest>", 1)

open(p, "w", encoding="utf-8").write(s)
print("✅ AndroidManifest.xml")

# ------------------------------------------------ build.gradle(.kts): الحد الأدنى + التوقيع
kts = os.path.join(ROOT, "app", "build.gradle.kts")
groovy = os.path.join(ROOT, "app", "build.gradle")
if os.path.exists(kts):
    g = open(kts, encoding="utf-8").read()
    g = re.sub(r"minSdk\s*=\s*[^\n]+", f"minSdk = {MIN_SDK}", g, count=1)
    if "keyProps" not in g:
        # الاستيراد أول الملف، وتحميل المفاتيح بعد كتلة plugins (Kotlin DSL لا يسمح بشيء قبلها)
        props = ("\nval keyProps = Properties().apply {\n"
                 "    val f = rootProject.file(\"key.properties\")\n"
                 "    if (f.exists()) f.inputStream().use { load(it) }\n"
                 "}\n")
        m = re.search(r"plugins\s*\{[^}]*\}\n", g)
        g = g[:m.end()] + props + g[m.end():] if m else props + g
        g = "import java.util.Properties\n\n" + g
        g = g.replace("android {", """android {
    signingConfigs {
        create("release") {
            if (keyProps.isNotEmpty()) {
                storeFile = file(keyProps["storeFile"] as String)
                storePassword = keyProps["storePassword"] as String
                keyAlias = keyProps["keyAlias"] as String
                keyPassword = keyProps["keyPassword"] as String
                storeType = "pkcs12"
            }
        }
    }""", 1)
        g = g.replace('signingConfig = signingConfigs.getByName("debug")',
                      'signingConfig = if (keyProps.isNotEmpty()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")')
    open(kts, "w", encoding="utf-8").write(g)
    print("✅ build.gradle.kts")
elif os.path.exists(groovy):
    g = open(groovy, encoding="utf-8").read()
    g = re.sub(r"minSdk(Version)?\s+[^\n]+", f"minSdkVersion {MIN_SDK}", g, count=1)
    if "keyProps" not in g:
        g = ("def keyProps = new Properties()\n"
             "def keyFile = rootProject.file('key.properties')\n"
             "if (keyFile.exists()) { keyFile.withInputStream { keyProps.load(it) } }\n\n") + g
        g = g.replace("android {", """android {
    signingConfigs {
        release {
            if (!keyProps.isEmpty()) {
                storeFile file(keyProps['storeFile'])
                storePassword keyProps['storePassword']
                keyAlias keyProps['keyAlias']
                keyPassword keyProps['keyPassword']
                storeType 'pkcs12'
            }
        }
    }""", 1)
        g = g.replace("signingConfig signingConfigs.debug",
                      "signingConfig keyProps.isEmpty() ? signingConfigs.debug : signingConfigs.release")
    open(groovy, "w", encoding="utf-8").write(g)
    print("✅ build.gradle")
