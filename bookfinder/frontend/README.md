# BookFinder

BookFinder is a cross-platform Flutter application for discovering books through the
[Open Library](https://openlibrary.org/) catalogue. It provides a richer experience
than a basic search screen by combining search, category browsing, recommendations,
book details, and a locally persisted wishlist.

The Flutter app communicates with a separate Node.js/Express backend. The backend
fetches Open Library data, validates requests, and normalizes responses into a
consistent format for the app.

## Features

- Animated branded splash screen
- Book search with paginated results
- Browse books by category
- Category distribution with book counts and percentages
- Recommendations from trending, fiction, and science collections
- Book details including covers, authors, descriptions, ratings, subjects, and editions
- Wishlist/favorites saved locally with `shared_preferences`
- Reusable loading, error, empty-state, book-card, and logo components
- Flutter support for mobile, web, desktop, and other supported targets

## Project structure

```text
bookfinder/
├── backend/
│   ├── src/
│   │   ├── routes/       # REST API routes
│   │   ├── services/     # Open Library integration
│   │   └── utils/        # Response normalization
│   └── package.json
└── frontend/
    ├── lib/
    │   ├── models/       # Book and wishlist models
    │   ├── screens/      # App screens
    │   ├── services/     # API client
    │   ├── utils/        # API and app constants
    │   └── widgets/      # Reusable UI components
    ├── assets/images/    # App assets, including logo.svg
    └── pubspec.yaml
```

## Prerequisites

Install the following before running the project:

- Flutter SDK with Dart 3.0 or later
- Node.js 18 or later
- npm
- A Flutter-supported device, emulator, or browser

Check the installed tools:

```bash
flutter --version
node --version
npm --version
flutter doctor
```

## Run the project locally

The backend must be running before launching the Flutter app.

### 1. Start the backend

From the repository root:

```bash
cd backend
npm install
npm start
```

The API starts at:

```text
http://localhost:3000
```

For automatic restart during development, use:

```bash
npm run dev
```

The backend reads `PORT` and `NODE_ENV` from environment variables. The default
port is `3000`, so no environment file is required for a basic local run.

### 2. Install frontend dependencies

Open another terminal and run:

```bash
cd frontend
flutter pub get
```

### 3. Run the Flutter app

List available targets:

```bash
flutter devices
```

Run on the selected/default target:

```bash
flutter run
```

Examples:

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d <device-id>
```

## API configuration

The frontend API URL is defined in:

```text
lib/utils/constants.dart
```

The default configuration is:

```dart
const String baseUrl = 'http://localhost:3000/api';
```

This works when the app runs on the same computer as the backend, such as Flutter
web or a desktop target.

For an Android emulator, `localhost` refers to the emulator itself. Use the host
machine alias instead:

```dart
const String baseUrl = 'http://10.0.2.2:3000/api';
```

For a physical device, replace the host with the computer's local network IP and
make sure both devices are connected to the same network:

```dart
const String baseUrl = 'http://YOUR-COMPUTER-IP:3000/api';
```

## Main API endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/health` | Check backend availability |
| `GET` | `/api/books/search?q=&page=&limit=` | Search books |
| `GET` | `/api/books/trending?limit=` | Get trending books |
| `GET` | `/api/books/subject/:subject` | Browse a category |
| `GET` | `/api/books/:workId` | Get book details |
| `GET` | `/api/books/categories` | Get category counts |
| `GET` | `/api/books/recommendations?limit=` | Get recommendations |

Quick health check:

```text
http://localhost:3000/api/health
```

## Useful development commands

```bash
# Format Dart files
dart format lib

# Analyze the Flutter project
flutter analyze

# Run Flutter tests
flutter test

# Build a web release
flutter build web
```

## Troubleshooting

### The app cannot load books

1. Confirm the backend terminal shows `BookFinder API running on http://localhost:3000`.
2. Open `http://localhost:3000/api/health` in a browser.
3. Check that `baseUrl` in `lib/utils/constants.dart` matches the device type.
4. Confirm the device can reach the computer running the backend.

### Android emulator cannot connect to the backend

Change `localhost` to `10.0.2.2` in `lib/utils/constants.dart`, then restart the
Flutter app.

### Port 3000 is already in use

This usually means the backend is already running. Check it first:

```powershell
Invoke-WebRequest http://localhost:3000/api/health
```

If the response contains `"service":"BookFinder API"`, do not start a second
backend process. Use the existing server. Otherwise, find the process using the
port:

```powershell
Get-NetTCPConnection -LocalPort 3000 -State Listen |
  Select-Object LocalPort, OwningProcess
```

Stop only the process ID returned by that command, then start the backend again:

```powershell
Stop-Process -Id <process-id> -Force
cd ..\backend
npm start
```

### Dependencies are missing

Run the dependency installation commands again:

```bash
cd backend
npm install

cd ../frontend
flutter pub get
```

## Data and privacy

Book metadata and cover images are retrieved from Open Library. Wishlist data is
stored locally on the device using `shared_preferences`; the application does not
require an account for saving favorites.

## Team

- Abhishek Vishwakarma
- Pranav Vishwakarma
- Sanchita Warkad
- Ankesh Yadav
