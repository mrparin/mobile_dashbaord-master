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

### เตรียมไฟล์ Signing สำหรับ Google Play

> ทำครั้งแรกก่อน build release สำหรับ Play Store และเก็บรหัสผ่าน/keystore ให้ปลอดภัย ห้าม commit ไฟล์เหล่านี้เข้า Git

```powershell
# สร้าง upload keystore
& "C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe" -genkey -v -keystore upload-keystore-v2.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

สร้างไฟล์ `android/key.properties`

```properties
storePassword=รหัสผ่านที่ตั้งไว้
keyPassword=รหัสผ่านที่ตั้งไว้
keyAlias=upload
storeFile=../../upload-keystore-v2.jks
```

ตรวจสอบว่า `.gitignore` มีรายการนี้:

```gitignore
upload-keystore*.jks
key.properties
```

ถ้ารัน Gradle โดยตรงแล้วหา Java ไม่เจอ ให้กำหนด `JAVA_HOME` ชั่วคราวก่อน:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio1\jbr"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
```

### Build AAB สำหรับอัปโหลดขึ้น Play Console

```bash
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
```

ไฟล์ที่ใช้อัปโหลดใน Play Console:

```text
build\app\outputs\bundle\release\app-release.aab
```

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

---

## 📦 ขั้นตอนนำแอปขึ้น Google Play Store

### 1. ตั้งค่า Package Name

โปรเจกต์นี้ใช้ package name:

```text
com.smiledevstudio.phanmanee
```

ตรวจสอบในไฟล์:

```text
android/app/build.gradle.kts
android/app/src/main/kotlin/com/smiledevstudio/phanmanee/MainActivity.kt
```

### 2. สร้างแอปใน Play Console

ใน Google Play Console กด **สร้างแอป** แล้วกรอก:

```text
ชื่อแอป: phanmanee
ชื่อแพ็กเกจ: com.smiledevstudio.phanmanee
ภาษาเริ่มต้น: ไทย - th
แอปหรือเกม: แอป
ฟรีหรือเสียเงิน: ฟรี
```

ติ๊กยอมรับ policy, Play App Signing และ export laws ให้ครบ

### 3. กรอก App Content

รายการที่ต้องกรอกใน Play Console:

```text
นโยบายความเป็นส่วนตัว
รายละเอียดการลงชื่อเข้าใช้: ไม่
โฆษณา: ไม่ แอปไม่มีโฆษณา
การจัดประเภทเนื้อหา: ประเภทแอปอื่นๆ ทั้งหมด
กลุ่มเป้าหมาย: 18 ปีขึ้นไป
ความปลอดภัยของข้อมูล
แอปของรัฐบาล: ไม่
รหัสโฆษณา: ไม่
แอปสุขภาพ: แอปไม่มีฟีเจอร์ด้านสุขภาพ
```

Privacy Policy URL ที่ใช้:

```text
https://docs.google.com/document/d/e/2PACX-1vSL4JvyJ3lIMEdw2UDvhaYLPXtXmYrlXHUcNdYT9gmyXlvTfyhhtUykRFXdM6W28DhD69OBF4bvlGDL/pub
```

### 4. กรอก Data Safety

คำตอบที่ใช้กับแอปนี้:

```text
แอปรวบรวมหรือแชร์ข้อมูลผู้ใช้ที่จำเป็นหรือไม่: ใช่
ข้อมูลทั้งหมดเข้ารหัสระหว่างส่งหรือไม่: ไม่
รองรับการสร้างบัญชีหรือไม่: แอปไม่อนุญาตให้ผู้ใช้สร้างบัญชี
ประเภทข้อมูล: ตำแหน่งโดยประมาณ
ข้อมูลนี้ถูกรวบรวมหรือแชร์หรือไม่: รวบรวมแล้ว + แชร์แล้ว
ประมวลผลชั่วคราวหรือไม่: ใช่
จำเป็นหรือผู้ใช้เลือกได้: ผู้ใช้สามารถเลือกได้
วัตถุประสงค์: ฟังก์ชันการทำงานของแอป
```

### 5. ตั้งค่าร้านค้าและ Store Listing

หมวดหมู่:

```text
แอปหรือเกม: แอป
หมวดหมู่: เครื่องมือ
```

ข้อมูลติดต่อ:

```text
อีเมล: cdsmile@gmail.com
โทรศัพท์: +66816384110
เว็บไซต์: เว้นว่างได้ถ้าไม่มี
```

คำอธิบายสั้น:

```text
แดชบอร์ดติดตามสภาพแวดล้อมสวนทุเรียนและพยากรณ์อากาศ
```

คำอธิบายเต็ม:

```text
Phanmanee เป็นแอปแดชบอร์ดสำหรับติดตามข้อมูลสภาพแวดล้อมของสวนทุเรียน แสดงข้อมูลจากเซ็นเซอร์ เช่น อุณหภูมิอากาศ ความชื้นอากาศ อุณหภูมิดิน ความชื้นในดิน และค่า VPD เพื่อช่วยให้ผู้ดูแลสวนตรวจสอบสภาพแวดล้อมได้สะดวก

แอปมีหน้าประวัติข้อมูลสำหรับดูแนวโน้มย้อนหลัง กราฟแสดงความสัมพันธ์ของข้อมูล และพยากรณ์อากาศล่วงหน้าเพื่อช่วยประกอบการดูแลสวน

เหมาะสำหรับเกษตรกร ผู้ดูแลสวน และผู้ที่ต้องการติดตามข้อมูลสภาพแวดล้อมของสวนทุเรียนผ่านมือถือ
```

ไฟล์ภาพที่เตรียมไว้ในโปรเจกต์:

```text
store_assets/play_icon_512.png
store_assets/feature_graphic_1024x500.png
store_assets/phone_screenshot_dashboard_1080x1920.png
store_assets/phone_screenshot_history_1080x1920.png
```

### 6. สร้าง Closed Testing

ไปที่:

```text
ทดสอบและเผยแพร่ > การทดสอบ > การทดสอบแบบปิด
```

ตั้งค่า track `Alpha`:

```text
ประเทศ/ภูมิภาค: ไทย
ผู้ทดสอบ: รายชื่ออีเมล phanmanee testers
อีเมลรับ feedback: cdsmile@gmail.com
```

ต้องมี tester อย่างน้อย 12 คนสำหรับบัญชีนักพัฒนาใหม่ ก่อนขอเผยแพร่ production จริง

### 7. อัปโหลด App Bundle

ใน track `Alpha` กด **สร้างรุ่นใหม่** แล้วอัปโหลด:

```text
build\app\outputs\bundle\release\app-release.aab
```

Release notes:

```html
<th>
เพิ่มรุ่นทดสอบแรกของ Phanmanee

- แสดงแดชบอร์ดข้อมูลสภาพแวดล้อมสวนทุเรียน
- แสดงข้อมูลอุณหภูมิ ความชื้น ดิน และค่า VPD
- เพิ่มหน้าประวัติข้อมูลและกราฟแนวโน้ม
- เพิ่มพยากรณ์อากาศสำหรับช่วยวางแผนดูแลสวน
</th>
```

จากนั้นกด:

```text
ถัดไป > ส่งรุ่นไปให้ Google ตรวจสอบ > ส่งการเปลี่ยนแปลงเข้ารับการตรวจสอบ
```

### 8. ส่งลิงก์ให้ Tester

หลังสถานะ track เป็น **เผยแพร่แล้ว**:

```text
ทดสอบและเผยแพร่ > การทดสอบ > การทดสอบแบบปิด > Alpha > ผู้ทดสอบ
```

กด **คัดลอกลิงก์** ใต้หัวข้อ:

```text
วิธีที่ผู้ทดสอบเข้าร่วมการทดสอบของคุณ
```

ส่งลิงก์ให้ tester ในรายการ `phanmanee testers` กดเข้าร่วมและติดตั้งแอปจาก Google Play

### 9. เงื่อนไขก่อน Production

สำหรับบัญชีใหม่ ให้ทำ closed testing อย่างน้อย:

```text
ผู้ทดสอบอย่างน้อย 12 คน
ระยะเวลาอย่างน้อย 14 วัน
```

เมื่อครบเงื่อนไข จึงสมัครสิทธิ์เผยแพร่เวอร์ชันใช้งานจริงได้
