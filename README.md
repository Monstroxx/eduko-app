# Eduko App

Cross-platform school management app. Built with Flutter for Android, iOS, and Web.

Companion app for [eduko-backend](https://github.com/Monstroxx/eduko-backend).

## Features

- **Dashboard** — Daily overview: next lesson, substitutions, pending excuses, upcoming appointments
- **Timetable** — Day and week views with subject colors, A/B week support
- **Substitutions** — Color-coded cards (cancellation, room change, teacher sub, extra lesson)
- **Attendance** — Batch recording with status chips (teacher/admin only)
- **Excuses** — Create, submit, approve/reject with date picker and attestation toggle
- **Lesson Content** — Browse topics and homework per lesson
- **Appointments** — Filterable by type (exam, test, event)
- **Profile** — Stats, role badge, logout
- **Settings** — Theme switcher, language (DE/EN), server URL, sync, cache management
- **Offline-First** — Local SQLite via Drift with background sync (5min TTL)
- **Connectivity Awareness** — Offline banner when no network

## Tech Stack

- **Framework:** Flutter 3.27+ (Dart 3.5+)
- **State Management:** Riverpod
- **Navigation:** GoRouter with auth guard
- **Networking:** Dio with JWT interceptor
- **Local Database:** Drift (SQLite) with platform-aware connection (FFI for mobile, WebDatabase for web)
- **Auth:** JWT stored in Flutter Secure Storage
- **UI:** Material 3 with custom theme and Google Fonts

## Getting Started

### Prerequisites

- Flutter SDK 3.27+
- An [eduko-backend](https://github.com/Monstroxx/eduko-backend) instance

### Setup

```bash
git clone https://github.com/Monstroxx/eduko-app.git
cd eduko-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
# Mobile (Android/iOS)
flutter run

# Web
flutter run -d chrome

# Build web release
flutter build web --release
```

### Server Connection

On first launch, enter your Eduko backend URL (e.g., `http://192.168.1.100:8080`). The app verifies the connection before proceeding to login.

## Architecture

```
lib/
  core/
    api/                # Dio client + ApiService (all endpoints)
    auth/               # AuthNotifier (login/logout, secure storage)
    config/             # App config (server URL)
    database/
      app_database.dart # Drift schema (9 cached tables)
      sync_service.dart # API → SQLite sync with TTL
      connection/       # Platform-aware DB connection (native/web)
    i18n/               # Locale management
    models/             # 13 JSON-serializable data models
    providers/          # Riverpod providers (all offline-first)
    router/             # GoRouter with auth redirect
    theme/              # Material 3 theme + status colors
  features/
    auth/               # Login + Server Setup screens
    dashboard/          # Dashboard with summary cards
    timetable/          # Day + week views with entry cards
    substitutions/      # Date-navigable substitution list
    attendance/         # Class selector + batch status toggles
    excuses/            # List, detail (approve/reject), create
    lessons/            # Lesson content browser
    appointments/       # Type-filtered appointment list
    profile/            # User info + stats
    settings/           # Theme, language, server, sync
    home/               # Shell with bottom navigation + offline banner
```

## Offline-First Pattern

1. Provider reads from local Drift database
2. Background sync fires (non-blocking)
3. If local cache is empty, waits for first sync
4. Mutations call API, then force-sync + invalidate providers
5. Sync metadata tracks staleness per table (5min TTL)

## Testing

```bash
flutter analyze    # Static analysis (0 warnings)
flutter test       # Unit tests (TODO)
```

## License

MIT — see [LICENSE](LICENSE).
