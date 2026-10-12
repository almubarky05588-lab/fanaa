"""يجهّز مشروع iOS المولَّد: الاسم، الأذونات، مفتاح الخرائط، الحد الأدنى للنظام.
الاستخدام: GOOGLE_MAPS_IOS_KEY=... python3 tool/patch_ios.py ios
"""
import os, plistlib, re, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "ios"
MAPS_KEY = os.environ.get("GOOGLE_MAPS_IOS_KEY", "").strip() or "NO_KEY_SET"
MIN_IOS = "15.0"  # Flutter 3.47 و GoogleMaps 9 يتطلبان iOS 15

p = os.path.join(ROOT, "Runner", "Info.plist")
with open(p, "rb") as f:
    info = plistlib.load(f)
info.update({
    "CFBundleDisplayName": "فناء",
    "CFBundleName": "فناء",
    "CFBundleDevelopmentRegion": "ar",
    "NSLocationWhenInUseUsageDescription": "نستخدم موقعك لعرض المشاتل القريبة منك وتحديد عنوان التوصيل",
    "NSCameraUsageDescription": "لتصوير المنتجات وإضافتها إلى متجرك",
    "NSPhotoLibraryUsageDescription": "لاختيار صور المنتجات من مكتبة الصور",
    "LSApplicationQueriesSchemes": ["tel", "https", "comgooglemaps"],
    "ITSAppUsesNonExemptEncryption": False,
    "UIStatusBarStyle": "UIStatusBarStyleDarkContent",
})
info["UISupportedInterfaceOrientations"] = ["UIInterfaceOrientationPortrait"]
info.pop("UISupportedInterfaceOrientations~ipad", None)
with open(p, "wb") as f:
    plistlib.dump(info, f)
print("✅ Info.plist")

p = os.path.join(ROOT, "Runner", "AppDelegate.swift")
src = open(p, encoding="utf-8").read()
if "import GoogleMaps" not in src:
    src = src.replace("import UIKit", "import UIKit\nimport GoogleMaps", 1)
if "GMSServices.provideAPIKey" not in src:
    i = src.find("return super.application(")
    if i < 0:
        sys.exit("❌ لم أجد return super.application في AppDelegate")
    line_start = src.rfind("\n", 0, i) + 1
    indent = src[line_start:i]
    src = src[:line_start] + f'{indent}GMSServices.provideAPIKey("{MAPS_KEY}")\n' + src[line_start:]
open(p, "w", encoding="utf-8").write(src)
print("✅ AppDelegate.swift")

p = os.path.join(ROOT, "Podfile")
if os.path.exists(p):
    s = open(p, encoding="utf-8").read()
    s = re.sub(r"^#?\s*platform :ios, '[^']*'", f"platform :ios, '{MIN_IOS}'", s, count=1, flags=re.M)
    if "platform :ios" not in s:
        s = f"platform :ios, '{MIN_IOS}'\n" + s
    open(p, "w", encoding="utf-8").write(s)
    print("✅ Podfile")

p = os.path.join(ROOT, "Runner.xcodeproj", "project.pbxproj")
s = open(p, encoding="utf-8").read()
s = re.sub(r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;", f"IPHONEOS_DEPLOYMENT_TARGET = {MIN_IOS};", s)
open(p, "w", encoding="utf-8").write(s)
print("✅ project.pbxproj")
