# 🌳 Realtime Smart Durian Monitoring

แอปพลิเคชัน Flutter สำหรับติดตามสภาพแวดล้อมสวนทุเรียนแบบเรียลไทม์ ผ่านโปรโตคอล MQTT และฐานข้อมูล InfluxDB พร้อมการแสดงผลด้วยกราฟ ดัชนี VPD และพยากรณ์อากาศ 7 วันล่วงหน้า

---

## 📱 ภาพรวมโปรแกรม

โปรแกรมนี้พัฒนาสำหรับสวนทุเรียน **พรรณมณี** โดยรองรับการทำงานบน Android

### คุณสมบัติหลัก
- **แสดงข้อมูลเซ็นเซอร์แบบเรียลไทม์** — อุณหภูมิอากาศ, ความชื้นอากาศ, อุณหภูมิดิน, ความชื้นดิน
- **ดัชนี VPD (Vapor Pressure Deficit)** — วิเคราะห์สภาพแวดล้อมพร้อมคำแนะนำสำหรับทุเรียน
- **พยากรณ์อากาศ 7 วัน** — ดึงข้อมูลจาก TMD, OpenWeatherMap หรือ Open-Meteo
- **กราฟข้อมูลย้อนหลัง** — บันทึกและแสดงประวัติการวัดสูงสุด 7 วัน
- **โหมดจำลองข้อมูล (Mock Mode)** — ทำงานได้แม้ไม่มีการเชื่อมต่อ MQTT

---

## 📁 โครงสร้างโปรเจค

```
mobile_dashbaord-master/
├── .env                          # ค่าตัวแปรแวดล้อม (API Keys, Endpoints)
├── pubspec.yaml                  # Dependencies ของโปรเจค
├── assets/
│   ├── durian_icon.png           # ไอคอนทุเรียน
│   ├── durian_tree.jpg           # รูปต้นทุเรียน (ใช้ใน AppBar)
│   └── thailand_locations.json   # ฐานข้อมูลจังหวัด/อำเภอ/ตำบลของไทย
└── lib/
    ├── main.dart                 # จุดเริ่มต้นของแอป, Navigation, DashboardView
    ├── models/
    │   └── telemetry_model.dart  # Data Model: SensorTelemetry
    ├── pages/
    │   └── history_view.dart     # หน้าแสดงข้อมูลย้อนหลัง
    ├── services/
    │   ├── mqtt_service.dart     # เชื่อมต่อ MQTT Broker
    │   ├── database_service.dart # SQLite Local Database
    │   ├── influx_service.dart   # ดึงข้อมูลจาก InfluxDB
    │   └── weather_service.dart  # พยากรณ์อากาศ (TMD / OWM / Open-Meteo)
    └── widgets/
        ├── gauge_card.dart           # Widget กราฟวงกลม (Radial Gauge)
        ├── vpd_status_card.dart      # Widget แสดงสถานะ VPD
        ├── environment_details_card.dart # Widget รายละเอียดสภาพแวดล้อม
        ├── forecast_card.dart        # Widget พยากรณ์อากาศ
        └── relationship_chart.dart   # Widget กราฟ Scatter Plot
```

---

## ⚙️ ค่าตัวแปรแวดล้อม (`.env`)

| ตัวแปร | คำอธิบาย | ค่าเริ่มต้น |
|---|---|---|
| `MQTT_SERVER` | ที่อยู่ MQTT Broker | `sci-iot.ddns.net` |
| `MQTT_PORT` | พอร์ต MQTT | `1883` |
| `MQTT_TOPIC` | Topic ที่ subscribe | `durian_farm1/node_sensor` |
| `TMD_API_TOKEN` | Token สำหรับ กรมอุตุนิยมวิทยา (TMD) | — |
| `OPENWEATHERMAP_API_KEY` | API Key สำหรับ OpenWeatherMap | — |
| `INFLUX_URL` | URL ของ InfluxDB | `http://sci-iot.ddns.net:8086` |
| `INFLUX_TOKEN` | Token สำหรับ InfluxDB | — |
| `INFLUX_ORG` | Organization ของ InfluxDB | `sci-iot` |
| `INFLUX_BUCKET` | Bucket ของ InfluxDB | `durian_data` |

---

## 📦 Dependencies หลัก

| Package | เวอร์ชัน | หน้าที่ |
|---|---|---|
| `flutter_dotenv` | ^5.2.1 | อ่านค่าจากไฟล์ `.env` |
| `mqtt_client` | ^10.5.1 | เชื่อมต่อ MQTT Broker |
| `http` | ^1.2.1 | HTTP requests สำหรับ API ต่างๆ |
| `fl_chart` | ^0.66.0 | กราฟเส้นและ Scatter Plot |
| `syncfusion_flutter_gauges` | ^24.2.7 | กราฟวงกลม (Radial Gauge) |
| `sqflite` | ^2.3.0 | SQLite Local Database |
| `shared_preferences` | ^2.5.5 | บันทึกการตั้งค่าผู้ใช้ |
| `intl` | ^0.19.0 | จัดรูปแบบวันที่/เวลา (รองรับภาษาไทย) |

---

## 🗂️ อธิบาย Function ในแต่ละไฟล์

---

### `lib/main.dart`

ไฟล์หลักของแอป กำหนด Theme, Navigation และ Dashboard UI

| Function / Class | คำอธิบาย |
|---|---|
| `main()` | จุดเริ่มต้น — โหลด `.env`, เริ่มต้น SQLite, Sync ข้อมูลจาก InfluxDB |
| `DurianApp` | Root Widget กำหนด MaterialApp พร้อม Light/Dark Theme |
| `MainNavigationScreen` | Bottom Navigation ระหว่างหน้า "แผงควบคุม" และ "ข้อมูลย้อนหลัง" |
| `DashboardView` | หน้าหลัก — เชื่อมต่อ MQTT และแสดง Widget ทั้งหมด |
| `_updateRecentHistory()` | เก็บประวัติข้อมูลเซ็นเซอร์ล่าสุด 50 จุด สำหรับ Scatter Plot |

---

### `lib/models/telemetry_model.dart`

Data Model สำหรับข้อมูลเซ็นเซอร์ทั้งหมด

| Function / Property | คำอธิบาย |
|---|---|
| `SensorTelemetry` (class) | เก็บค่าเซ็นเซอร์ครบทุกชนิด: อุณหภูมิ, ความชื้น, ลม, แสง, EC, pH, N, P, K |
| `calculatedVpd` (getter) | คำนวณค่า VPD (kPa) จากสมการ Magnus: `es = 0.6108 × e^(17.27T / (T+237.3))` |
| `vpd` (getter) | คืนค่า VPD ที่คำนวณได้จาก `calculatedVpd` |
| `SensorTelemetry.fromJson()` | Factory constructor — แปลง JSON payload (ทั้งแบบ flat และ nested) เป็น object |
| `_toDouble()` | Helper — แปลง dynamic value เป็น double อย่างปลอดภัย |
| `toJson()` | แปลง object เป็น Map สำหรับบันทึกลงฐานข้อมูลหรือส่งผ่านเครือข่าย |

---

### `lib/services/mqtt_service.dart`

จัดการการเชื่อมต่อ MQTT Broker และ stream ข้อมูลเซ็นเซอร์ (Singleton)

| Function | คำอธิบาย |
|---|---|
| `connect()` | เชื่อมต่อ MQTT Broker โดยอ่านค่าจาก `.env` หากล้มเหลวจะเปิด Mock Mode อัตโนมัติ |
| `_onConnected()` | Callback เมื่อเชื่อมต่อสำเร็จ — subscribe topic และเริ่มรับข้อมูล |
| `_onDisconnected()` | Callback เมื่อขาดการเชื่อมต่อ — เปิด Mock Mode ทันที |
| `_onSubscribed()` | Callback เมื่อ subscribe topic สำเร็จ |
| `_processPayload()` | แปลง JSON payload เป็น `SensorTelemetry` → ส่งเข้า Stream → บันทึกลง SQLite |
| `emitTelemetry()` | ส่งข้อมูลเข้า stream โดยตรง (ใช้จาก InfluxService) |
| `disconnect()` | ตัดการเชื่อมต่อ MQTT และหยุด Mock Mode |
| `_startMockTelemetryStream()` | เริ่มจำลองข้อมูลทุก 10 วินาที (ใช้สูตรรอบวัน sin/cos) |
| `_stopMockTelemetryStream()` | หยุดการจำลองข้อมูล |
| `_generateAndSendMockData()` | สร้างข้อมูลจำลองที่สมจริง โดยคำนึงถึงรอบอุณหภูมิตามเวลาของวัน |

---

### `lib/services/database_service.dart`

จัดการ SQLite Local Database สำหรับเก็บประวัติข้อมูลเซ็นเซอร์ (Singleton)

| Function | คำอธิบาย |
|---|---|
| `database` (getter) | คืน instance ของ Database (สร้างใหม่ถ้ายังไม่มี) |
| `_initDatabase()` | เริ่มต้น SQLite DB ที่ path `sensor_history.db` |
| `_onCreate()` | สร้างตาราง `telemetry` พร้อม index บน timestamp |
| `insertTelemetry()` | บันทึกข้อมูลเซ็นเซอร์ 1 รายการ |
| `insertTelemetryBatch()` | บันทึกข้อมูลเป็นชุดใหญ่ด้วย batch transaction (ประสิทธิภาพสูง) |
| `getTelemetryHistory()` | ดึงข้อมูลระหว่างช่วงเวลา start–end |
| `getLatestTelemetryTimestamp()` | คืน timestamp ของข้อมูลล่าสุดในฐานข้อมูล |
| `getHistoryForPreset()` | ดึงข้อมูลตาม preset: `1h`, `24h`, `7d` |
| `clearHistory()` | ลบข้อมูลทั้งหมดในตาราง |
| `seedMockDataIfEmpty()` | เติมข้อมูลตัวอย่าง 48 จุด (ทุก 30 นาที ย้อนหลัง 24 ชม.) หากฐานข้อมูลว่าง |

---

### `lib/services/influx_service.dart`

ดึงข้อมูลย้อนหลังจาก InfluxDB และ sync เข้า SQLite (Singleton)

| Function | คำอธิบาย |
|---|---|
| `syncMissingData()` | ดึงข้อมูลที่ขาดหายจาก InfluxDB (ตั้งแต่ timestamp ล่าสุดใน SQLite) แล้วบันทึกลง SQLite |
| `_parseInfluxDbCsv()` | แปลง CSV response จาก InfluxDB Flux Query เป็น List\<SensorTelemetry\> |

**Flux Query ที่ใช้:**
```flux
from(bucket: "durian_data")
  |> range(start: <last_timestamp>)
  |> filter(fn: (r) => r["_measurement"] == "all_sensor_data")
  |> filter(fn: (r) => r["location"] == "farm1")
  |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
```

---

### `lib/services/weather_service.dart`

ดึงพยากรณ์อากาศ 7 วันล่วงหน้า พร้อมระบบ Fallback หลายระดับ (Singleton)

| Function | คำอธิบาย |
|---|---|
| `get7DayForecast()` | ดึงพยากรณ์ 7 วัน โดยลำดับความสำคัญ: TMD → OpenWeatherMap → Open-Meteo → Simulation |
| `_fetchTmdForecast()` | ดึงข้อมูลจาก กรมอุตุนิยมวิทยา (TMD) API พร้อม fallback ระดับ ตำบล→อำเภอ→จังหวัด |
| `_fetchOpenMeteoForecast()` | ดึงพยากรณ์จาก Open-Meteo (geocoding + forecast) |
| `_generateSimulatedForecast()` | สร้างพยากรณ์จำลองตามจังหวัด/อำเภอ/ตำบล (ใช้ seed แบบ deterministic) |
| `_extractTmdForecastLocations()` | แปลง JSON response จาก TMD (รองรับหลาย format) |
| `_mapTmdCondition()` | แปลง TMD condition code (1-8) เป็น condition string |
| `_mapTmdDescription()` | แปลง TMD condition code เป็นคำบรรยายภาษาไทย |
| `_estimateTmdRainChance()` | คำนวณโอกาสฝนตก (%) จาก TMD condition code และปริมาณฝน |
| `_mapOwmCondition()` | แปลง OpenWeatherMap condition string เป็น condition |
| `_mapWmoCodeToCondition()` | แปลง WMO weather code (Open-Meteo) เป็น condition string |
| `_buildLocationLabel()` | สร้าง label แสดงชื่อสถานที่ (ตำบล / อำเภอ / จังหวัด) |
| `_readDouble()` / `_readInt()` | Helper — อ่านค่าตัวเลขจาก Map แบบปลอดภัย รองรับหลาย key |

---

### `lib/pages/history_view.dart`

หน้าแสดงข้อมูลย้อนหลัง พร้อมกราฟและตารางบันทึก

| Function | คำอธิบาย |
|---|---|
| `_loadHistory()` | โหลดข้อมูลจาก SQLite ตาม preset ที่เลือก |
| `_clearHistory()` | ลบประวัติทั้งหมด พร้อม Dialog ยืนยัน |
| `_buildPresetButton()` | สร้างปุ่มเลือกช่วงเวลา: 1 ชั่วโมง / 24 ชั่วโมง / 7 วัน |
| `_buildLineChart()` | สร้างกราฟเส้น 2 เส้น (อุณหภูมิ + ความชื้น) สำหรับอากาศหรือดิน |
| `_buildVpdChart()` | สร้างกราฟเส้น VPD พร้อม area fill สีเขียว |
| `_buildLogTag()` | สร้าง tag แสดงข้อมูลย่อในตารางบันทึก |
| `_buildIndicatorDot()` | สร้าง legend dot สีสำหรับกราฟ |

---

### `lib/widgets/gauge_card.dart`

Widget แสดงค่าเซ็นเซอร์เป็นกราฟวงกลม (Radial Gauge)

| ส่วนประกอบ | คำอธิบาย |
|---|---|
| `GaugeCard` (Widget) | Responsive gauge card รองรับ title, value, min, max, unit, color, icon |
| `build()` | คำนวณขนาด gauge, font, icon แบบ responsive ตามความกว้างของ widget |

---

### `lib/widgets/vpd_status_card.dart`

Widget แสดงสถานะ VPD พร้อมคำแนะนำสำหรับทุเรียน

| ส่วนประกอบ | คำอธิบาย |
|---|---|
| `VpdThreshold` (class) | เก็บเกณฑ์ VPD แต่ละระดับ: min, max, status, meaning, action, color, icon |
| `VpdStatusCard` (Widget) | แสดงค่า VPD พร้อมระบุสถานะ 5 ระดับ และคำแนะนำการจัดการ |
| `thresholds` (static) | รายการเกณฑ์ VPD ทั้ง 5 ระดับ (Too Low / Low Stress / Optimal / High Stress / Danger) |
| `_getThreshold()` | ค้นหาเกณฑ์ที่ตรงกับค่า VPD ปัจจุบัน |

**เกณฑ์ VPD สำหรับทุเรียน:**

| ช่วง VPD | สถานะ | ความหมาย |
|---|---|---|
| 0.00 – 0.40 kPa | ต่ำเกินไป | อากาศชื้นจัด เสี่ยงโรครา |
| 0.40 – 0.80 kPa | เฝ้าระวังต่ำ | อากาศค่อนข้างชื้น |
| 0.81 – 1.40 kPa | **เหมาะสมที่สุด** | ช่วงทองของทุเรียน |
| 1.41 – 1.80 kPa | เริ่มวิกฤต | ควรเปิดระบบพ่นหมอก |
| > 1.80 kPa | วิกฤตรุนแรง | สั่งเปิดระบบพ่นหมอกเต็มกำลัง |

---

### `lib/widgets/environment_details_card.dart`

Widget แสดงรายละเอียดสภาพแวดล้อม แบ่งเป็น 2 การ์ด

| Widget | คำอธิบาย |
|---|---|
| `AirEnvironmentCard` | แสดงข้อมูลอากาศ: ความเร็วลม, ทิศทางลม, ความเข้มแสง (Lux), พลังงานแสงอาทิตย์ (W/m²) |
| `SoilEnvironmentCard` | แสดงข้อมูลดิน: VPD ในดิน, EC (µS/cm), pH, ไนโตรเจน (N), ฟอสฟอรัส (P), โพแทสเซียม (K) |
| `_EnvironmentTile` | Widget ย่อยสำหรับแต่ละรายการ (icon + label + value + unit) |

---

### `lib/widgets/forecast_card.dart`

Widget พยากรณ์อากาศ 7 วัน พร้อม dropdown เลือกพื้นที่

| Function | คำอธิบาย |
|---|---|
| `_loadLocations()` | โหลดข้อมูลจังหวัด/อำเภอ/ตำบลจาก `assets/thailand_locations.json` และดึงค่าที่บันทึกไว้ใน SharedPreferences |
| `_saveLocationSettings()` | บันทึกจังหวัด/อำเภอ/ตำบลที่เลือกลง SharedPreferences |
| `_updateDistricts()` | อัปเดตรายการอำเภอเมื่อเปลี่ยนจังหวัด |
| `_updateSubdistricts()` | อัปเดตรายการตำบลเมื่อเปลี่ยนอำเภอ |
| `_fetchForecast()` | เรียก `WeatherService.get7DayForecast()` พร้อมส่ง English location names |
| `_getWeatherIcon()` | คืน IconData ตามสภาพอากาศ (Sunny/Cloudy/Rainy/Thunderstorm/Windy) |
| `_getWeatherColor()` | คืนสีตามสภาพอากาศ |
| `_buildDropdown()` | สร้าง Dropdown แบบ styled สำหรับเลือกจังหวัด/อำเภอ/ตำบล |

---

### `lib/widgets/relationship_chart.dart`

Widget กราฟ Scatter Plot แสดงความสัมพันธ์ระหว่างอุณหภูมิและความชื้น

| ส่วนประกอบ | คำอธิบาย |
|---|---|
| `RelationshipChart` (Widget) | Scatter chart รองรับ: อากาศ (Temp vs RH) และ ดิน (Temp vs Moisture) |
| `build()` | คำนวณ min/max ของแกน X-Y อัตโนมัติ และแสดง tooltip เมื่อกดจุด |

---

## 🚧 ข้อจำกัดที่ยังพัฒนาไม่สมบูรณ์

> ⚠️ **ฟังก์ชันที่ยังไม่มีในโปรแกรม**

### การควบคุม Relay (เปิด/ปิดระบบรดน้ำ/พ่นหมอก)
ปัจจุบันโปรแกรม **ยังไม่มี** ฟังก์ชันสำหรับ:
- ส่งคำสั่งเปิด/ปิด Relay ผ่าน MQTT (Publish command)
- ปุ่มควบคุมระบบรดน้ำหรือพ่นหมอกจากแอป
- การทำงานแบบ Automation ที่จะสั่งเปิด Relay อัตโนมัติเมื่อค่า VPD เกินเกณฑ์

ปัจจุบันระบบทำได้เพียง **แจ้งเตือนด้วยข้อความ** (แสดงคำแนะนำใน VPD Card) แต่ไม่สามารถ **สั่งควบคุมอุปกรณ์จริง** ได้

---

## 🔭 แนวทางการพัฒนาต่อในอนาคต

### 1. 🔌 ระบบควบคุม Relay ผ่าน MQTT
เพิ่มฟังก์ชัน Publish MQTT command เพื่อเปิด/ปิด Relay ควบคุมระบบน้ำ เช่น:
```json
{"relay": "pump1", "state": "ON"}
```
- เพิ่มปุ่มในหน้า Dashboard สำหรับควบคุม Relay แต่ละตัว
- แสดงสถานะ Relay ปัจจุบัน (ON/OFF) แบบ Realtime

### 2. 🤖 ระบบ Automation (Rule-based Control)
- กำหนด Rule อัตโนมัติ เช่น "หาก VPD > 1.5 kPa → เปิดพ่นหมอก 5 นาที"
- กำหนดตารางเวลาการให้น้ำ (Schedule Irrigation)
- ปรับการทำงานตามพยากรณ์อากาศ (ถ้าฝนตก → งดรดน้ำ)

### 3. 📊 การส่งออกข้อมูล (Data Export)
- Export ประวัติเซ็นเซอร์เป็นไฟล์ CSV หรือ Excel
- แชร์รายงานสรุปประจำวัน/สัปดาห์ผ่าน Line หรือ Email

### 4. 🔔 การแจ้งเตือน (Push Notifications)
- ส่ง Push Notification เมื่อค่า VPD เข้าสู่โซนวิกฤต
- แจ้งเตือนเมื่อเซ็นเซอร์ขาดการส่งข้อมูล (offline)
- แจ้งเตือนเมื่อค่า pH หรือ EC ผิดปกติ

### 5. 📸 ระบบกล้อง (Camera Monitoring)
- เชื่อมต่อกล้อง IP Camera เพื่อดูภาพสวนแบบ Realtime
- บันทึกภาพอัตโนมัติเพื่อติดตามการเจริญเติบโตของต้นทุเรียน

### 6. 🌍 รองรับหลายแปลง/หลาย Node
- รองรับ MQTT Topic หลายช่องทางสำหรับหลาย Node Sensor
- เลือกดูข้อมูลแยกตามแปลงหรือจุดวัด

### 7. 🧠 AI / Machine Learning
- วิเคราะห์แนวโน้มโรคพืชจากข้อมูลสภาพแวดล้อม
- พยากรณ์ช่วงเวลาเหมาะสมสำหรับการดึงดอก/ติดผล
- แนะนำการจัดการปุ๋ยตามค่า N-P-K ในดิน

### 8. 📱 UI/UX ปรับปรุง
- เพิ่ม Widget แผนที่แสดงตำแหน่ง Node Sensor ในสวน
- Dark Mode ที่ปรับค่าสีได้ตามความต้องการ
- รองรับ Tablet layout แบบ multi-column

---

## 🚀 วิธีติดตั้งและรันโปรแกรม

### ความต้องการของระบบ
- Flutter SDK `^3.12.2`
- Dart SDK ที่ compatible กับ Flutter version
- Android Studio หรือ VS Code พร้อม Flutter Extension

### ขั้นตอนการติดตั้ง

```bash
# 1. Clone โปรเจค
git clone <repo-url>
cd mobile_dashbaord-master

# 2. ติดตั้ง dependencies
flutter pub get

# 3. แก้ไขค่าใน .env ให้ตรงกับ server ของคุณ

# 4. รันแอป
flutter run
```

### การ Build สำหรับ Android

```bash
flutter build apk --release
```

---

## 📝 หมายเหตุ

- ไฟล์ `.env` ถูกรวมเป็น asset ของแอป อย่าลืม **ไม่ commit** API Key จริงขึ้น Git Repository สาธารณะ
- เมื่อเชื่อมต่อ MQTT ไม่ได้ แอปจะเปลี่ยนเป็น **Mock Mode** โดยอัตโนมัติ แสดงข้อมูลจำลองที่สมจริงตามรอบของวัน
- ข้อมูล SQLite จะถูก Sync จาก InfluxDB ทุกครั้งที่เปิดแอป (เฉพาะส่วนที่ขาดหาย)
- ค่าเริ่มต้นพยากรณ์อากาศคือจังหวัด **จันทบุรี** (แหล่งปลูกทุเรียนที่สำคัญ)

---

*พัฒนาโดย: ทีมพัฒนาระบบ IoT สวนพรรณมณี*  
*เวอร์ชัน: 1.0.0 | อัปเดตล่าสุด: มิถุนายน 2569*
