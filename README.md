# 📡 FreeTier Radar

> **Discover, track, and build with the most generous free tiers on the internet.**

A developer/indie-hacker companion app that scans, aggregates, and organizes generous free tiers across cloud hosts, AI APIs, databases, auth engines, and creative assets. Highlights "No Credit Card Required" services and alerts you when pricing tiers change.

---

## 🏗️ Architecture

```
freetier-radar/
├── backend/                        # Python FastAPI backend
│   ├── main.py                     # FastAPI app + endpoints + scheduler
│   ├── models.py                   # SQLModel ORM + Pydantic schemas
│   ├── database.py                 # SQLite engine + session management
│   ├── diff_engine.py              # Content hashing + change detection
│   ├── seed_data.py                # 25+ real service entries
│   ├── requirements.txt            # Python dependencies
│   └── scrapers/
│       └── github_freedev_parser.py  # free-for-dev markdown parser
│
└── mobile/                         # Flutter Android app
    ├── pubspec.yaml
    ├── analysis_options.yaml
    └── lib/
        ├── main.dart               # App entry + bottom navigation
        ├── theme/
        │   └── app_theme.dart      # Catppuccin Mocha dark theme
        ├── models/
        │   └── service_model.dart  # Dart data classes
        ├── services/
        │   └── api_service.dart    # Dio HTTP client
        ├── providers/
        │   └── services_provider.dart  # Riverpod state management
        ├── screens/
        │   ├── home_screen.dart           # Explore feed
        │   ├── alerts_screen.dart         # Change timeline
        │   └── stack_calculator_screen.dart  # Indie Stack Builder
        └── widgets/
            ├── service_card.dart          # Service list card
            ├── service_detail_modal.dart  # Bottom sheet detail view
            └── filter_bar.dart            # Category filter chips
```

---

## 🚀 Quick Start

### Backend

```bash
cd backend/

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Seed the database with 25+ real services
python seed_data.py

# Start the API server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The API is now available at `http://localhost:8000`. Try:
- `GET http://localhost:8000/api/v1/services` — list all services
- `GET http://localhost:8000/api/v1/services?category=AI_ML` — filter by category
- `GET http://localhost:8000/api/v1/services?no_credit_card=true` — no CC required
- `GET http://localhost:8000/api/v1/services?query=supabase` — search
- `GET http://localhost:8000/api/v1/alerts/deprecations` — change alerts
- `POST http://localhost:8000/api/v1/admin/scrape` — trigger manual scrape
- Interactive docs: `http://localhost:8000/docs`

### Mobile App (Flutter)

```bash
cd mobile/

# Install dependencies
flutter pub get

# Run on connected device / emulator (debug)
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK (fat APK, all ABIs)
flutter build apk --release

# Build release APK (split per ABI — recommended for distribution)
flutter build apk --release --split-per-abi
```

APKs will be generated at:
```
mobile/build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk    (most modern phones)
├── app-armeabi-v7a-release.apk  (older phones)
└── app-x86_64-release.apk      (emulators)
```

> **Note:** The Flutter app defaults to `http://10.0.2.2:8000` as the API base URL,
> which maps to the host machine's localhost from the Android emulator. For physical
> devices, update the `defaultBaseUrl` in `lib/services/api_service.dart` to your
> server's IP address.

---

## 📱 Features

### 1. Explore Feed
- Search bar with 300ms debounce
- "Radar of the Week" spotlight banner
- Category filter chips (AI/ML, Databases, Hosting, Auth, Storage, APIs, Creative)
- "No CC Required" toggle filter
- Pull-to-refresh

### 2. Service Cards
- Category badge with icon
- Short description (2-line truncation)
- Free tier limits in monospaced code style (JetBrains Mono)
- Status chips: "No CC" (green), "Hard Cap" (blue), "Updated" (orange), "Deprecated" (red)
- Bookmark toggle + Direct link button

### 3. Service Detail Modal
- Draggable bottom sheet with full service information
- Credit card warning banner
- Change log display
- Hard cap indicator
- Actions: Visit Site, Copy Link, Bookmark, Share

### 4. Deprecation Alerts
- Timeline-style display of tier changes
- Color-coded: 🔴 Downgrade, 🟢 Upgrade, 🟠 Policy Change
- Relative timestamps

### 5. Indie Stack Calculator
- Select Frontend Host + Database + Auth Provider
- Dropdown with no-CC indicator per service
- Combined summary with warnings
- "Export as Markdown" to share sheet
- "Save Stack" to bookmarks

---

## 🎨 Design System

**Catppuccin Mocha** dark theme:

| Role | Color | Hex |
|------|-------|-----|
| Surface | Base | `#1E1E2E` |
| Background | Mantle | `#181825` |
| Card | Surface0 | `#313244` |
| Primary | Blue | `#89B4FA` |
| Secondary | Green | `#A6E3A1` |
| Error | Red | `#F38BA8` |
| Warning | Peach | `#FAB387` |
| Text | Text | `#CDD6F4` |
| Subtext | Subtext0 | `#A6ADC8` |

- **Body text:** Inter
- **Code/limits:** JetBrains Mono

---

## 🔧 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x, Dart 3.1+ |
| State | Riverpod (flutter_riverpod) |
| HTTP | Dio 5.x |
| Backend | Python 3.11+, FastAPI |
| Database | SQLite via SQLModel |
| Scraping | httpx + regex parsing |
| Scheduler | APScheduler (12-hour intervals) |

---

## 📋 API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/services` | List services (paginated, filterable) |
| GET | `/api/v1/services/{id}` | Get single service |
| GET | `/api/v1/alerts/deprecations` | List recent changes |
| POST | `/api/v1/admin/scrape` | Trigger manual scrape |

### Query Parameters for `/api/v1/services`

| Param | Type | Description |
|-------|------|-------------|
| `category` | string | Filter by category enum |
| `no_credit_card` | bool | Only show no-CC services |
| `query` | string | Search name + description |
| `status` | string | Filter by ACTIVE/DEPRECATED/CHANGED_RECENTLY |
| `page` | int | Page number (default 1) |
| `page_size` | int | Items per page (default 20, max 100) |

---

## 📜 License

MIT — built for the indie hacker community.
