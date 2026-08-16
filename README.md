# SmartBin (Uber for Smart Bins)

SmartBin is an IoT smart-waste-bin system: an ultrasonic sensor on the bin reports fill level to a backend, and a mobile app lets users check bin status and (eventually) pay for collection via M-Pesa. The repo has three parts that talk to each other over HTTP:

```
ESP32 (firmware)  --HTTP POST-->  Django (backend/API)  <--HTTP-->  App (Flutter)
   sensor.cpp            /api/bins/readings                bin_status.dart / dashboard.dart
   mpesa.cpp              /api/users/*                       login.dart / member_onboard.dart
```

- **[ESP32/](ESP32/)** — C++ firmware for the physical bin unit: reads the ultrasonic sensor and posts readings to Django; a separate keypad+LCD sketch drives an M-Pesa STK push flow.
- **[Django/](Django/)** — REST API and database (Supabase/PostgreSQL) that stores sensor readings and user accounts.
- **[App/](App/)** — Flutter mobile app end users install; shows live bin fill level and handles registration/login.

Data flows one way for sensing (device → backend → app polls it) and the app talks to the backend directly for auth. There's no direct link between the ESP32 and the app.

---

## Repository layout

### [ESP32/](ESP32/)
Arduino/C++ firmware, meant to be opened in the Arduino IDE or PlatformIO (no build config is checked in yet).

| File | Purpose |ii
|---|---|
| [sensor.cpp](ESP32/sensor.cpp) | Reads distance from an ultrasonic sensor (TRIG on GPIO5, ECHO on GPIO18), computes it every loop, and `POST`s `{device_id, distance_cm}` to `/api/bins/readings` every 5s over Wi-Fi. Authenticates with an `X-Device-Key` header that must match Django's `DEVICE_API_KEY`. |
| [mpesa.cpp](ESP32/mpesa.cpp) | Drives a 4x3 keypad + 16x2 I2C LCD to collect a phone number and amount, triggers an STK push against a separate payments API (`/api/stkpush`, port 5000 — not part of this repo), and polls `/api/stkpush/status/<id>` until the payment resolves. |

**Before flashing:** update `ssid`/`password` (Wi-Fi), the backend host/IP in `api_readings` / `api_stkpush`, and `device_key` (must match `DEVICE_API_KEY` in `Django/.env`) for your own network. Required libraries: `WiFi`, `HTTPClient`, `ArduinoJson`, and for `mpesa.cpp` also `Keypad` and `LiquidCrystal_I2C`.

> ⚠️ **Security note:** both files currently have real-looking Wi-Fi credentials and a device key hardcoded and committed to git. Treat those as compromised, rotate the Wi-Fi password and `DEVICE_API_KEY`, and move future secrets into a `secrets.h` that's gitignored rather than committing them directly.

### [Django/](Django/)
The backend API. Full setup/config instructions live in **[Django/README.md](Django/README.md)** — summary below.

| Path | Purpose |
|---|---|
| [config/](Django/config/) | Project settings, root URL conf (`/admin/`, `/api/...`). |
| [bins/](Django/bins/) | `SensorReading` model + fill-percent calculation; `POST /api/bins/readings` (device-key auth, used by the ESP32) and `GET /api/bins/latest` (used by the app). |
| [users/](Django/users/) | `User` model with password hashing and a simple bearer token; `POST /api/users/register`, `POST /api/login`, `GET /api/users/me`. |
| [manage.py](Django/manage.py) / [requirements.txt](Django/requirements.txt) | Standard Django entry point and dependencies. |
| [.env.example](Django/.env.example) | Template for `DATABASE_URL`, `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `DEVICE_API_KEY` — copy to `.env` and fill in. |

Quick start:
```bash
cd Django
python -m venv venv && venv\Scripts\activate      # Windows
pip install -r requirements.txt
cp .env.example .env                                # then edit .env
python manage.py migrate
python manage.py runserver
```

### [App/](App/)
Flutter mobile client (internal package name `kanisaapp` — inherited from an earlier template, the app itself is SmartBin-specific).

| Path | Purpose |
|---|---|
| [lib/main.dart](App/lib/main.dart) | App entry point. |
| [lib/screen/](App/lib/screen/) | UI screens: [login.dart](App/lib/screen/login.dart) / [member_onboard.dart](App/lib/screen/member_onboard.dart) (auth), [dashboard.dart](App/lib/screen/dashboard.dart) / [base_dashboard.dart](App/lib/screen/base_dashboard.dart) / [member_dashboard.dart](App/lib/screen/member_dashboard.dart) (post-login shell), [bin_status.dart](App/lib/screen/bin_status.dart) (polls `/api/bins/latest` every 30s and shows fill level). |
| [lib/method/api.dart](App/lib/method/api.dart) | HTTP helper wrapping calls to the Django API + shared snackbar UI feedback. |
| [lib/config/server.dart](App/lib/config/server.dart) | `Config.baseUrl` — the Django API base URL. **Must point at your machine's LAN IP**, not `localhost`, so a phone/emulator can reach it. |
| [lib/components/](App/lib/components/) | Reusable widgets: splash screen, welcome/onboarding, responsive layout helper, accessibility dialog. |
| [lib/services/notification_service.dart](App/lib/services/notification_service.dart) | Firebase Cloud Messaging + local notifications setup. |
| [lib/theme/](App/lib/theme/) | Theme controller / light-dark switching. |

Quick start:
```bash
cd App
flutter pub get
# edit lib/config/server.dart to point at your running Django instance
flutter run
```

---

## Running the full stack locally

1. Start **Django** (`Django/`) and note the LAN IP of the machine it's running on (not `127.0.0.1` — the phone/emulator and the ESP32 both need to reach it over the network).
2. Point **App/lib/config/server.dart** `baseUrl` and **ESP32** `api_readings`/`device_key` at that same host and `DEVICE_API_KEY`.
3. Run the Flutter app (`flutter run`) and flash the ESP32 (`ESP32/sensor.cpp`). The app's bin status screen polls `/api/bins/latest`; the ESP32 posts to `/api/bins/readings` every 5s.

## Contributing

Each folder is a separate toolchain (Python/Django, Flutter/Dart, Arduino/C++) — there's no monorepo build step tying them together. Open the relevant subfolder in its native tool (VS Code + Python venv for `Django/`, Android Studio/VS Code with the Flutter plugin for `App/`, Arduino IDE or PlatformIO for `ESP32/`) and see that subfolder's notes above.
