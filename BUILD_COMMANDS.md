# 🛠️ คำสั่ง Build — Flutter Mobile Dashboard

## 📋 ขั้นตอนก่อน Build (ควรทำทุกครั้ง)

```bash
# 1. ล้าง build cache เก่า
flutter clean

# 2. ดึง dependencies ใหม่
flutter pub get

# 3. ตรวจสอบว่าไม่มี error ใน code
flutter analyze
```

---

## 🤖 Android

### APK (แนะนำสำหรับแชร์/ติดตั้งทั่วไป)

```bash
# Build APK — Release (เล็ก + เร็ว สำหรับใช้งานจริง)
flutter build apk --release

# Build APK — แยกตาม CPU architecture (ไฟล์เล็กลง)
flutter build apk --split-per-abi --release

# Build APK — Debug (สำหรับทดสอบ)
flutter build apk --debug
```

📁 ไฟล์ output อยู่ที่:
```
build\app\outputs\flutter-apk\
├── app-release.apk          ← APK รวม (ใช้กับทุก device)
├── app-arm64-v8a-release.apk
├── app-armeabi-v7a-release.apk
└── app-x86_64-release.apk
```

### App Bundle (สำหรับ Google Play Store)

```bash
flutter build appbundle --release
```

📁 output: `build\app\outputs\bundle\release\app-release.aab`

---

## 🌐 Web

```bash
# Build สำหรับ Web
flutter build web --release

# Build Web พร้อมระบุ base href (กรณี deploy ใน subdirectory)
flutter build web --base-href /dashboard/
```

📁 output: `build\web\`

---

## 🖥️ Windows

```bash
flutter build windows --release
```

📁 output: `build\windows\x64\runner\Release\`

---

## ▶️ รันทดสอบบน Device / Emulator

```bash
# รันบน device ที่เชื่อมต่ออยู่ (debug mode)
flutter run

# รันแบบ release mode บน device จริง
flutter run --release

# ดูรายการ device ที่เชื่อมต่อ
flutter devices

# รันบน device ที่ระบุ
flutter run -d <device-id>
```

---

## 🔧 คำสั่งอื่นๆ ที่มีประโยชน์

| คำสั่ง | ความหมาย |
|---|---|
| `flutter doctor` | ตรวจสอบ environment ว่าพร้อม build หรือไม่ |
| `flutter clean` | ล้าง build cache ทั้งหมด |
| `flutter pub get` | ดึง packages ที่ระบุใน `pubspec.yaml` |
| `flutter pub outdated` | ดู packages ที่มีเวอร์ชันใหม่กว่า |
| `flutter analyze` | ตรวจสอบ code หา warning/error |
| `flutter test` | รัน unit tests |
| `flutter upgrade` | อัปเดต Flutter SDK |

---

## 🚀 ขั้นตอน Build APK สำหรับ Project นี้ (แนะนำ)

```bash
# Step 1: ล้าง cache
flutter clean

# Step 2: ดึง packages
flutter pub get

# Step 3: ตรวจสอบ code
flutter analyze

# Step 4: Build APK
flutter build apk --split-per-abi --release
```

> **หมายเหตุ:** ต้องมี Android SDK และ Java (JDK) ติดตั้งไว้ก่อน
> ตรวจสอบด้วยคำสั่ง `flutter doctor`
