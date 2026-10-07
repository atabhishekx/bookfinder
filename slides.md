# BookFinder — Project Presentation

> **Course:** Web & App Development (WAD) — ISE
> **Project Title:** BookFinder — Mobile Book Discovery Application
> **Group Members:**
> | Roll No. | Name |
> |----------|------|
> | 52 | Abhishek Vishwakarma |
> | 53 | Pranav Vishwakarma |
> | 54 | Sanchita Warkad |
> | 55 | Ankesh Yadav |

---

## Slide 1 — Title Slide

### **BookFinder**
#### *Discover Your Next Favorite Book*

- A cross-platform mobile book discovery application
- Built with **Flutter** (frontend) + **Node.js / Express** (backend)
- Powered by the **Open Library** open API
- Live features: animated splash, category-wise distribution, recommendations, wishlist

**Group 52–55**
- 52 · Abhishek Vishwakarma
- 53 · Pranav Vishwakarma
- 54 · Sanchita Warkad
- 55 · Ankesh Yadav

---

## Slide 2 — Introduction & Overview

### What is BookFinder?
BookFinder is a book discovery app that lets users search, browse, and save books they love.
Instead of a plain search box, the home screen is a rich dashboard:

- **Animated splash screen** with the app logo on every launch
- **Category-wise distribution** of books (16 categories with counts + percentage bars)
- **Recommended for you** section (trending + popular picks)
- **Your Wishlist** — books the user heart-saves, persisted locally
- Full **book details** (description, ratings, editions, subjects)

### Why it matters
- Millions of books are hard to discover; a single search box is not enough.
- Open Library provides free, legal access to a huge catalogue (20M+ works).
- A custom backend keeps API keys/logic server-side and normalizes messy data.

---

## Slide 3 — Problem Statement & Objectives

### Problem
- Readers struggle to find new books matching their interests.
- Raw Open Library responses are inconsistent and hard to consume directly from a mobile app.
- No personalized "home" experience — just a search field.

### Objectives
1. Build a polished, animated mobile UI with a reusable brand logo (`logo.svg`).
2. Create a REST backend that proxies & normalizes Open Library data.
3. Show **category-wise distribution** ready on the home screen.
4. Show **recommended** books and a persistent **wishlist**.
5. Support deep book details (editions, ratings, subjects).

### Success criteria
- App opens with a logo animation → home dashboard loads with categories, recommendations, and wishlist.
- Search returns paginated results; tapping a book shows full details.

---

## Slide 4 — Technology Stack

### Frontend (Flutter / Dart)
| Package | Purpose |
|---------|---------|
| `flutter` (SDK 3.47+, Dart 3.13) | UI framework |
| `http` | REST calls to our backend |
| `provider` | State management (FavoritesProvider) |
| `shared_preferences` | Persist wishlist locally |
| `flutter_svg` | Render `logo.svg` everywhere |
| `intl` | Date/number formatting |

### Backend (Node.js)
| Package | Purpose |
|---------|---------|
| `express` | REST API server |
| `axios` | HTTP client to Open Library |
| `cors` | Cross-origin access |
| `dotenv` | Environment configuration |

### External API
- **Open Library** (`openlibrary.org`) — search, trending, subjects, works, editions, ratings, covers.

---

## Slide 5 — System Architecture

```
                 ┌──────────────────────────────┐
                 │        FLUTTER APP           │
                 │  Splash → Home → Details     │
                 │  (provider + shared_prefs)   │
                 └──────────────┬───────────────┘
                                │  HTTP (JSON)
                                │  http://localhost:3000/api
                                ▼
                 ┌──────────────────────────────┐
                 │   NODE.JS / EXPRESS BACKEND  │
                 │  routes/books.js             │
                 │  services/bookService.js     │
                 │  utils/normalize.js          │
                 └──────────────┬───────────────┘
                                │  axios
                                ▼
                 ┌──────────────────────────────┐
                 │      OPEN LIBRARY API        │
                 │  search.json / trending /    │
                 │  subjects / works / covers   │
                 └──────────────────────────────┘
```

### Data flow
1. UI triggers `ApiService` → backend endpoint.
2. Backend calls Open Library, normalizes the response (`normalize.js`).
3. Clean JSON returns to the app → UI rebuilds via `Provider`.
4. Wishlist writes go to `SharedPreferences` (offline-first).

---

## Slide 6 — API Details

### Our Backend Endpoints (`/api`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Service health check |
| GET | `/api/books/search?q=&page=&limit=` | Search books (paginated) |
| GET | `/api/books/trending?limit=` | Trending books |
| GET | `/api/books/subject/:subject?page=&limit=` | Books by category |
| GET | `/api/books/:workId` | Full book details |
| GET | `/api/books/categories` | **16 categories + counts + % distribution** |
| GET | `/api/books/recommendations?limit=` | **Recommended books (trending + popular)** |
| GET | `/logo.svg` | Serves the app logo |

### Open Library endpoints consumed
- `GET /search.json` — full-text search
- `GET /trending/daily.json` — daily trending works
- `GET /subjects/{subject}.json` — category books + `work_count`
- `GET /works/{id}.json`, `/editions.json`, `/ratings.json` — details
- `https://covers.openlibrary.org/b/id/{coverId}-{S|M|L}.jpg` — cover images

### Sample response (categories)
```json
{ "categories": [
    { "name": "History", "subject": "history", "emoji": "🏛️",
      "bookCount": 2559352, "percentage": 72.5 },
    { "name": "Biography", "subject": "biography", "emoji": "👤",
      "bookCount": 916244, "percentage": 26.0 }
  ], "total": 16 }
```

---

## Slide 7 — Application Flow

### App launch flow
1. **Splash screen** — `logo.svg` scales/rotates in with an elastic curve, glow fades up, app name + tagline slide in, pulsing dots, then a fade transition into the main app.
2. **Home screen** loads → `Future.wait` fetches **categories** + **recommendations** in parallel.
3. User sees: welcome banner → category distribution → recommendations → wishlist.

### User journeys
- **Search:** type query → `onSubmitted` → `/search` → paginated `ListView` (infinite scroll via `ScrollController`).
- **Browse category:** tap a category card → `CategoryScreen` → `/subject/:subject` → book list.
- **Wishlist:** tap heart → `FavoritesProvider.toggleFavorite()` → saved to `SharedPreferences` → shown in "Your Wishlist" + "Favorites" tab.
- **Details:** tap a book → `BookDetailsScreen` → `/books/:workId` → description, rating bar, subjects, editions.

### State management
- `ChangeNotifierProvider` exposes `FavoritesProvider` (load/save/toggle/remove/clear).
- `context.watch` rebuilds UI when favorites change.

---

## Slide 8 — Key Features & Screens

### Screens
1. **SplashScreen** — animated logo opening sequence.
2. **HomeScreen** — search bar + dashboard sections.
3. **CategoryScreen** — all books inside one category (paginated).
4. **BookDetailsScreen** — cover, rating, description, subjects, editions.
5. **FavoritesScreen** — the saved wishlist with clear-all.

### Home screen sections (the dashboard)
- **Welcome banner** — gradient card with logo + tagline.
- **Browse by Category** — horizontal category cards (emoji, name, book count).
- **Category Distribution chart** — horizontal progress bars with % share per category.
- **Recommended for You** — horizontal cover cards with a "reason" chip (e.g., *Trending now*, *Popular in Fiction*).
- **Your Wishlist** — horizontal covers with a heart badge to remove.

### Reusable components
`AppLogo` (SVG logo), `BookCard`, `CategoryDistribution`, `RecommendedBooksSection`, `WishlistSection`, `LoadingState`, `ErrorState`, `EmptyState`.

---

## Slide 9 — Implementation Highlights

### Logo everywhere (`logo.svg`)
- Single source of truth: `assets/images/logo.svg` (also served by backend at `/logo.svg`).
- Rendered with `flutter_svg` in: splash, home app bar, home banner, favorites app bar, book details app bar, and web favicon (`web/index.html` + `web/manifest.json`).

### Opening animation
- `AnimationController` + `CurvedAnimation` (elasticOut, easeOutCubic).
- Logo: scale 0→1 + rotate −0.35→0 rad + glow opacity.
- Text: slide-up + fade; ambient radial glow; pulsing loading dots.
- Exit: fade-out → `PageRouteBuilder` fade into `MainNavigation`.

### Category-wise distribution (ready on home)
- Backend aggregates `work_count` for 16 subjects in parallel (`Promise.allSettled`), computes each category's `%` share, sorts by count.
- Frontend renders both **category cards** and a **distribution bar chart**.

### Recommendations
- Backend merges **trending daily** + **popular fiction** + **popular science**, de-duplicates by work key, and tags each book with a `reason`.

### Wishlist
- `FavoritesProvider` + `SharedPreferences` → persists across app restarts; heart toggle anywhere updates all screens instantly.

---

## Slide 10 — Conclusion & Future Scope

### Conclusion
- Delivered a complete, animated, category-driven book discovery app.
- Clean separation: Flutter UI ↔ Express backend ↔ Open Library data.
- Home screen is a ready dashboard: **categories distribution + recommendations + wishlist**, all using the branded `logo.svg` and a polished opening animation.

### Future scope
- User accounts & cloud-synced wishlist (Firebase / Supabase).
- Personalized recommendations using reading history (ML).
- Book previews / read-online via Open Library read API.
- Dark mode, multi-language (i18n), and social sharing.
- Caching layer (Redis) + pagination cursors for scale.

### How to run
```bash
# Backend
cd bookfinder/backend
npm install
npm start            # http://localhost:3000

# Frontend
cd bookfinder/frontend
flutter pub get
flutter run          # connects to http://localhost:3000/api
```

---

*Prepared by Group 52–55: Abhishek Vishwakarma · Pranav Vishwakarma · Sanchita Warkad · Ankesh Yadav*
