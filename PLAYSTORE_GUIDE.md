# 🚀 คู่มือการนำแอปขึ้น Google Play Store
### สวนพรรณมณี Dashboard — Flutter App

---

## 📋 สารบัญ

1. [สิ่งที่ต้องเตรียมก่อน](#1-สิ่งที่ต้องเตรียมก่อน)
2. [เปลี่ยน Application ID](#2-เปลี่ยน-application-id)
3. [สร้าง Signing Keystore](#3-สร้าง-signing-keystore)
4. [ตั้งค่า Release Signing](#4-ตั้งค่า-release-signing)
5. [Build App Bundle (AAB)](#5-build-app-bundle-aab)
6. [สมัคร Google Play Console](#6-สมัคร-google-play-console)
7. [สร้าง App ใหม่ใน Play Console](#7-สร้าง-app-ใหม่ใน-play-console)
8. [อัปโหลด AAB](#8-อัปโหลด-aab)
9. [กรอก Store Listing](#9-กรอก-store-listing)
10. [Content Rating & Data Safety](#10-content-rating--data-safety)
11. [ส่ง Review และ Publish](#11-ส่ง-review-และ-publish)
12. [การอัปเดตแอปในอนาคต](#12-การอัปเดตแอปในอนาคต)

---

## 1. สิ่งที่ต้องเตรียมก่อน

| รายการ | รายละเอียด |
|--------|-----------|
| **Google Account** | บัญชี Gmail สำหรับเปิด Play Console |
| **ค่าสมัคร** | $25 USD (ชำระครั้งเดียวตลอดชีพ) |
| **Java JDK** | ต้องติดตั้งเพื่อสร้าง Keystore (ตรวจสอบด้วย `java -version`) |
| **Flutter SDK** | เวอร์ชันปัจจุบันของโปรเจค |
| **App Icon** | ขนาด 512×512px รูปแบบ PNG |
| **Screenshots** | อย่างน้อย 2 ภาพ (Phone), อาจต้องมี Tablet ด้วย |

> ⚠️ **สำคัญ:** ทำขั้นตอนที่ 2–4 ให้เสร็จก่อน จึงค่อย build

---

## 2. เปลี่ยน Application ID

> ⛔ ปัจจุบัน Application ID คือ `com.example.phanmanee`  
> Google Play Store **ไม่อนุญาต** ให้ใช้ `com.example` เด็ดขาด

### แก้ไขไฟล์ `android/app/build.gradle.kts`

```diff
 defaultConfig {
-    applicationId = "com.example.phanmanee"
+    applicationId = "th.phanmanee.duriandashboard"
     minSdk = flutter.minSdkVersion
     targetSdk = flutter.targetSdkVersion
     versionCode = flutter.versionCode
     versionName = flutter.versionName
 }
```

**รูปแบบที่แนะนำ:**
```
th.{ชื่อองค์กร}.{ชื่อแอป}
```
ตัวอย่าง: `th.phanmanee.duriandashboard`

> ⚠️ **Application ID เปลี่ยนไม่ได้หลังจาก Publish ครั้งแรก** — เลือกให้ดี

### อัปเดต Version ใน `pubspec.yaml`

```yaml
version: 1.0.0+1
#        ─┬─ ─┬─
#          │   └─ versionCode (ต้องเพิ่มทุกครั้งที่อัปโหลด)
#          └──── versionName (แสดงบน Play Store)
```

---

## 3. สร้าง Signing Keystore

> ⚠️ **เก็บไฟล์ keystore ไว้อย่างดีที่สุด!**  
> หากไฟล์นี้สูญหาย จะไม่สามารถอัปเดตแอปบน Play Store ได้อีกเลย

### รันคำสั่งใน PowerShell

```powershell
keytool -genkey -v `
  -keystore C:\Users\parinya_j\phanmanee-release-key.jks `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias phanmanee-key
```

### ข้อมูลที่ต้องกรอกระหว่างสร้าง

```
Enter keystore password:  ← ตั้งรหัสผ่าน (จำไว้!)
Re-enter new password:    ← ยืนยันรหัสผ่าน
What is your first and last name?  → ชื่อนักพัฒนา เช่น Parinya J
What is your organizational unit?  → Dashboard Team
What is the name of your organization?  → Phanmanee Farm
What is the name of your City or Locality?  → Chanthaburi
What is the name of your State or Province?  → Chanthaburi
What is the two-letter country code?  → TH
Is CN=..., OU=..., O=..., L=..., ST=..., C=TH correct? → yes
```

---

## 4. ตั้งค่า Release Signing

### 4.1 สร้างไฟล์ `android/key.properties`

```properties
storePassword=รหัสผ่านของ keystore
keyPassword=รหัสผ่านของ keystore
keyAlias=phanmanee-key
storeFile=C:\\Users\\parinya_j\\phanmanee-release-key.jks
```

> 🔒 เพิ่มบรรทัดนี้ใน `android/.gitignore` เพื่อไม่ให้ขึ้น Git:
> ```
> key.properties
> ```

### 4.2 แก้ไข `android/app/build.gradle.kts`

เพิ่มส่วน import และ signingConfig ดังนี้:

```kotlin
import java.util.Properties

// โหลด key.properties
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

android {
    // ... ส่วนที่มีอยู่เดิม ...

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // เปลี่ยนจาก debug เป็น release
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

## 5. Build App Bundle (AAB)

```powershell
flutter build appbundle --release
```

ไฟล์ AAB จะอยู่ที่:
```
build\app\outputs\bundle\release\app-release.aab
```

> **ทำไมต้อง AAB ไม่ใช่ APK?**  
> Google Play ต้องการ `.aab` (Android App Bundle) ซึ่ง Google จะ generate APK ที่เหมาะสมสำหรับแต่ละ device โดยอัตโนมัติ ทำให้ขนาดแอปเล็กลงสำหรับผู้ใช้

### ตรวจสอบก่อน Build

```powershell
# ตรวจสอบว่าไม่มี error
flutter analyze

# ตรวจสอบ dependencies
flutter pub get
```

---

## 6. สมัคร Google Play Console

1. ไปที่ [https://play.google.com/console](https://play.google.com/console)
2. กด **"Get started"** แล้ว Sign in ด้วย Google Account
3. กรอกข้อมูลนักพัฒนา:
   - **Account type**: Individual (บุคคล) หรือ Organization (องค์กร)
   - **Developer name**: ชื่อที่จะแสดงบน Play Store
   - **Contact email**: อีเมลสำหรับรับการแจ้งเตือน
4. ชำระค่าสมัคร **$25 USD** ผ่านบัตรเครดิต
5. รอการยืนยัน identity ผ่านทาง email (**1–3 วัน**)

---

## 7. สร้าง App ใหม่ใน Play Console

1. เข้า Play Console → กด **"Create app"**
2. กรอกข้อมูล:

   | Field | ค่าที่แนะนำ |
   |-------|------------|
   | App name | สวนพรรณมณี Dashboard |
   | Default language | Thai - ไทย |
   | App or game | App |
   | Free or paid | Free |

3. ยอมรับ Developer Program Policies และ US export laws
4. กด **"Create app"**

---

## 8. อัปโหลด AAB

### แนะนำ: เริ่มจาก Internal Testing ก่อน

1. ไปที่ **Testing → Internal testing**
2. กด **"Create new release"**
3. ในส่วน **App bundles** กด **"Upload"** แล้วเลือกไฟล์ `app-release.aab`
4. รอ Google วิเคราะห์ไฟล์ (1–2 นาที)
5. กรอก **Release name** เช่น `v1.0.0`
6. กรอก **Release notes** (ภาษาไทยได้):
   ```
   - เวอร์ชันแรก
   - แสดงข้อมูลสภาพแวดล้อมแบบ real-time
   - รองรับ MQTT และ InfluxDB
   ```
7. กด **"Save"** แล้ว **"Review release"** จากนั้น **"Start rollout to Internal testing"**

---

## 9. กรอก Store Listing

ไปที่ **Grow → Store presence → Main store listing**

### ข้อมูลที่ต้องกรอก

#### App Details
```
App name:         สวนพรรณมณี Dashboard
Short description: ติดตามสภาพแวดล้อมสวนทุเรียนแบบ real-time (≤80 ตัวอักษร)
Full description:  [อธิบาย feature ทั้งหมด ≤4000 ตัวอักษร]
```

**ตัวอย่าง Full Description:**
```
📊 สวนพรรณมณี Dashboard — ระบบติดตามสภาพแวดล้อมสวนทุเรียนแบบ Real-time

ฟีเจอร์หลัก:
• ติดตามอุณหภูมิอากาศและความชื้นแบบ real-time
• ข้อมูลสภาพดิน (อุณหภูมิ, ความชื้น, EC, pH, N-P-K)
• ทิศทางและความเร็วลมพร้อมเข็มทิศ
• ดัชนี VPD (Vapor Pressure Deficit)
• พยากรณ์อากาศ 7 วัน
• ประวัติข้อมูลย้อนหลัง
• รองรับ Dark Mode
```

#### App Icon
- ขนาด: **512 × 512 px**
- รูปแบบ: PNG (ไม่มี alpha/transparency)

#### Feature Graphic
- ขนาด: **1024 × 500 px**
- แสดงบน Play Store ด้านบนของหน้าแอป

#### Screenshots (Phone)
- ต้องมีอย่างน้อย **2 ภาพ** สูงสุด 8 ภาพ
- ขนาดแนะนำ: **1080 × 1920 px** (portrait)
- ถ่าย screenshot จากแอปจริง หรือใช้ emulator

---

## 10. Content Rating & Data Safety

### Content Rating
1. ไปที่ **Policy → App content → Content rating**
2. กด **"Start questionnaire"**
3. เลือกหมวด: **Utilities** หรือ **Productivity**
4. ตอบคำถาม (ส่วนใหญ่ตอบ "ไม่" สำหรับแอป dashboard)
5. กด **"Save"** → **"Submit"**

### Data Safety
1. ไปที่ **Policy → App content → Data safety**
2. แจ้งข้อมูลที่แอปเก็บ:

   | ข้อมูล | เก็บหรือไม่ |
   |--------|------------|
   | Location | ❌ ไม่เก็บ |
   | Personal info | ❌ ไม่เก็บ |
   | Device identifiers | ❌ ไม่เก็บ |
   | App activity | ✅ เก็บ (ข้อมูล sensor เฉพาะในเครื่อง) |

---

## 11. ส่ง Review และ Publish

### ตรวจสอบ Dashboard ให้ครบ

ไปที่ **Dashboard** ใน Play Console และตรวจสอบว่าทุกหัวข้อมีเครื่องหมาย ✅ ครบ:
- [ ] App content
- [ ] Store listing
- [ ] Content ratings
- [ ] Data safety
- [ ] Target audience
- [ ] App release

### ส่ง Production

1. ไปที่ **Testing → Production**
2. กด **"Create new release"** → อัปโหลด AAB เดิม
3. กด **"Review release"** → **"Start rollout to Production"**
4. รอ Google review: **1–7 วัน** (ครั้งแรก), **ไม่กี่ชั่วโมง** (ครั้งต่อไป)

---

## 12. การอัปเดตแอปในอนาคต

ทุกครั้งที่อัปเดต ต้องทำขั้นตอนนี้:

### 1. เพิ่ม versionCode ใน `pubspec.yaml`

```yaml
# ตัวอย่าง: จาก 1.0.0+1 → 1.0.1+2
version: 1.0.1+2
```

> `versionCode` (ตัวเลขหลัง `+`) **ต้องเพิ่มขึ้นทุกครั้ง** มิฉะนั้น Play Store จะไม่รับ

### 2. Build AAB ใหม่

```powershell
flutter build appbundle --release
```

### 3. อัปโหลดและ Publish

ทำซ้ำขั้นตอนที่ 8 และ 11 โดยใช้ไฟล์ AAB ใหม่

---

## 🗓️ ไทม์ไลน์โดยรวม

```
วันที่ 1  │ แก้ App ID + สร้าง Keystore + ตั้งค่า Signing + Build AAB
วันที่ 1  │ สมัคร Play Console + ชำระ $25
วันที่ 2–4│ รอยืนยัน identity จาก Google
วันที่ 4  │ สร้าง App + อัปโหลด AAB + กรอก Store Listing
วันที่ 4  │ กรอก Content Rating + Data Safety + ส่ง Review
วันที่ 5–11│ รอ Google Review (ครั้งแรก)
✅ แอปปรากฏบน Play Store
```

---

## 🆘 ปัญหาที่พบบ่อย

| ปัญหา | วิธีแก้ |
|-------|---------|
| `com.example` ไม่ผ่าน | เปลี่ยน Application ID ตามขั้นตอนที่ 2 |
| Upload ล้มเหลว: versionCode ซ้ำ | เพิ่มเลข `+X` ใน pubspec.yaml |
| Signing error | ตรวจสอบ path ใน `key.properties` ให้ถูกต้อง |
| Review ถูก Reject | อ่าน email จาก Google อย่างละเอียด แล้วแก้ไขตามที่ระบุ |
| App crash หลัง publish | ใช้ Internal testing ทดสอบก่อนเสมอ |

---

*คู่มือนี้เขียนสำหรับโปรเจค สวนพรรณมณี Dashboard — Flutter 3.x / Android*
