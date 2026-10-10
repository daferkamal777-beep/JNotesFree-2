# JNotes Free — مشروع Android / Flutter

هذه حزمة مصدر للتطبيق، وليست APK جاهزًا للتثبيت بعد.

## الموجود حاليًا
- واجهة عربية RTL متجاوبة للهاتف والتابلت.
- إنشاء ملاحظة ومحرر رسم.
- قلم، هايلايتر، ممحاة، ألوان وأحجام مختلفة.
- تراجع وصفحات متعددة.
- حفظ محلي للمحتوى المكتوب داخل المحرر.
- الوضع الفاتح/الليلي.

## بناء APK على Windows
يلزم تثبيت Flutter SDK وAndroid Studio/Android SDK، ثم فتح PowerShell داخل مجلد المشروع وتنفيذ:

```powershell
flutter create . --platforms=android
flutter pub get
flutter run
flutter build apk --release
```

مسار APK الناتج:
`build\app\outputs\flutter-apk\app-release.apk`

## خيار البناء السحابي
تم تضمين workflow في `.github/workflows/build-apk.yml`. بعد رفع المشروع إلى مستودع GitHub، افتح Actions وشغّل `Build Android APK`. بعد اكتمال البناء نزّل Artifact باسم `JNotesFree-Android-APK`.

## تنبيه صريح
هذه نواة V1 وليست بديلًا كاملًا عن Jnotes حتى الآن. استيراد PDF والتعليق عليه، إدراج الصور، Lasso، تصدير PDF، التسجيل الصوتي، OCR وميزات AI لم تُنفذ بعد. لا يلزم شراء اشتراك للتطبيق، لكن ميزات AI مستقبلًا قد تحتاج خدمة خارجية إن أُضيفت.
