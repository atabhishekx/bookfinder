# BookFinder — Project Presentation

> **Course:** Web & App Development (WAD) — ISE  
> **Project:** BookFinder — Mobile Book Discovery Application  
> **Team:** Abhishek Vishwakarma · Pranav Vishwakarma · Sanchita Warkad · Ankesh Yadav  
> **Suggested duration:** 8–10 minutes

---

## Slide 1 — Title

# **BookFinder**
### Discover your next favourite book

**A cross-platform mobile book discovery experience**

- Search millions of books
- Explore categories and trending titles
- Open rich book details
- Save a personal wishlist

**Built with Flutter + Node.js/Express + Open Library**

> **Presenter cue:** Open with the problem: “A catalogue can be huge, but discovering the right book should feel simple.”

---

## Slide 2 — The Problem

### Finding a book should be easier than searching a database

Readers often face:

- Too many titles and not enough useful discovery
- Inconsistent metadata across books and editions
- Search results without context or personalization
- No simple way to save interesting books for later

### Our opportunity

Turn an open catalogue into a focused mobile experience:

> **Discover → Explore → Read details → Save**

---

## Slide 3 — Our Solution

### BookFinder is a discovery-first book app

The home screen is a dashboard, not just a search box:

1. **Animated splash** establishes the product identity.
2. **Category distribution** shows what is available at a glance.
3. **Recommendations** combine trending and popular subjects.
4. **Book details** bring description, ratings, subjects, and editions together.
5. **Wishlist** keeps saved books available across app restarts.

### Success criteria

- Search is fast, paginated, and easy to browse.
- Important home data loads together.
- A saved book remains saved after closing and reopening the app.
- A single normalized model powers all screens.

---

## Slide 4 — Product Walkthrough

### The main user journey

```text
Launch
  ↓
Animated splash
  ↓
Home dashboard
  ├─ Search books ───────────────→ Search results → Book details
  ├─ Browse a category ──────────→ Category results → Book details
  ├─ Open a recommendation ──────→ Book details
  └─ Tap the heart ──────────────→ Wishlist / Favorites
```

### Screens delivered

| Screen | Purpose |
|---|---|
| `SplashScreen` | Branded opening animation |
| `HomeScreen` | Search, categories, distribution, recommendations, wishlist |
| `CategoryScreen` | Paginated books for one subject |
| `BookDetailsScreen` | Cover, description, ratings, subjects, editions |
| `FavoritesScreen` | Locally persisted wishlist |

> **Demo cue:** Follow this exact path during the live demo: search → details → heart → favorites.

---

## Slide 5 — Technology Stack

### Frontend

| Technology | Role |
|---|---|
| Flutter / Dart | Cross-platform UI |
| `http` | Calls the REST API |
| `provider` | Reactive wishlist state |
| `shared_preferences` | Local wishlist persistence |
| `flutter_svg` | Reusable `logo.svg` rendering |
| `intl` | Formatting values for display |

### Backend

| Technology | Role |
|---|---|
| Node.js 18+ | Server runtime |
| Express | REST API and routing |
| Axios | Open Library HTTP client |
| CORS | Frontend/backend communication |
| dotenv | Environment configuration |

### Data source

**Open Library API** provides search, trending works, subjects, editions, ratings, and cover images.

---

## Slide 6 — System Architecture

```text
┌───────────────────────────────────────────────────────────┐
│ Flutter mobile app                                       │
│ Screens → Widgets → ApiService → FavoritesProvider      │
│                 │                 │                      │
│                 │                 └─ SharedPreferences   │
└─────────────────┼─────────────────────────────────────────┘
                  │ HTTP / JSON
                  ▼
┌───────────────────────────────────────────────────────────┐
│ Node.js / Express backend                                │
│ routes/books.js → bookService.js → normalize.js          │
└─────────────────┼─────────────────────────────────────────┘
                  │ Axios
                  ▼
┌───────────────────────────────────────────────────────────┐
│ Open Library API                                         │
│ Search · Trending · Subjects · Works · Editions · Ratings│
└───────────────────────────────────────────────────────────┘
```

### Why use a backend?

- Keeps third-party API integration in one place
- Validates and bounds request parameters
- Converts inconsistent upstream data into a stable app model
- Gives the frontend a clean, project-owned API

---

## Slide 7 — API Design

### Project API (`/api`)

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/health` | Check server availability |
| `GET` | `/books/search?q=&page=&limit=` | Paginated search |
| `GET` | `/books/trending?limit=` | Trending titles |
| `GET` | `/books/subject/:subject` | Category browsing |
| `GET` | `/books/:workId` | Full work details |
| `GET` | `/books/categories` | Counts and percentages |
| `GET` | `/books/recommendations` | Curated mixed feed |

### Example: request validation

```js
const { q, page = 1, limit = 20 } = req.query;

if (!q || !q.trim()) {
  return res.status(400).json({
    error: 'Validation error',
    message: 'Query parameter "q" is required and cannot be empty'
  });
}

const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
```

**Result:** predictable requests, bounded page sizes, and clearer client errors.

---

## Slide 8 — Data Normalization

### The app should not depend on raw upstream response shapes

Open Library responses can contain missing fields, different author formats, and multiple description formats. The backend maps them into one `Book` shape:

```js
const results = docs.map(doc => ({
  id: doc.key,
  title: doc.title || 'Unknown Title',
  authors: doc.author_name || [],
  first_publish_year: doc.first_publish_year || null,
  cover_id: doc.cover_i || null,
  edition_count: doc.edition_count || null,
  subjects: doc.subject ? doc.subject.slice(0, 10) : [],
  ratings_average: doc.ratings_average || null
}));
```

### Benefits

- UI widgets receive consistent fields
- Null or missing values do not break a screen
- Formatting decisions stay out of the presentation layer
- Search, category, and recommendation cards can reuse the same model

---

## Slide 9 — Home Dashboard Performance

### Independent requests load in parallel

```dart
final results = await Future.wait([
  _apiService.getCategories(),
  _apiService.getRecommendations(limit: 12),
]);

if (!mounted) return;
setState(() {
  _categories = results[0] as List<BookCategory>;
  _recommendations = results[1] as List<Book>;
  _isLoadingHome = false;
});
```

### What this achieves

- Categories and recommendations do not wait for each other
- One loading state controls the dashboard
- `mounted` prevents updating a disposed screen
- Retry/error state is shown when the home request fails

**Design principle:** fetch independent data concurrently, then render one coherent experience.

---

## Slide 10 — Recommendations & Category Intelligence

### Recommendations combine multiple signals

The backend requests:

- Daily trending books
- Popular fiction
- Popular science

Then it de-duplicates results and adds a reason label:

```js
const seen = new Set();
const recommendations = [];

const pushBook = (doc, reason) => {
  if (!doc.key || seen.has(doc.key)) return;
  seen.add(doc.key);
  recommendations.push({
    id: doc.key,
    title: doc.title || 'Unknown Title',
    reason
  });
};
```

### Category distribution

- 16 predefined subjects are queried in parallel.
- Each subject contributes a `work_count`.
- Counts are converted into a percentage of the total.
- Categories are sorted from largest to smallest.

This gives the home screen both **discovery content** and **catalogue insight**.

---

## Slide 11 — Wishlist State & Offline Persistence

### One provider keeps the UI synchronized

```dart
Future<void> toggleFavorite(Book book) async {
  final index = _favorites.indexWhere((b) => b.id == book.id);

  if (index >= 0) {
    _favorites.removeAt(index);
  } else {
    _favorites.insert(0, book);
  }

  await _saveFavorites();
  notifyListeners();
}
```

### User benefit

- Heart actions work from cards and details
- Home and Favorites update immediately
- Saved books survive app restarts
- No login is required for the core wishlist experience

**State flow:** `BookCard` → `FavoritesProvider` → `SharedPreferences` → all listening screens.

---

## Slide 12 — UI & UX Highlights

### Product polish

- Reusable `AppLogo` renders the same SVG across the app
- Elastic scale, rotation, glow, and fade animations on launch
- Horizontal cards make recommendations easy to scan
- Progress bars communicate category share visually
- Loading, error, and empty states make network behaviour understandable
- Responsive layouts support mobile and web targets

### Reusable building blocks

`AppLogo` · `BookCard` · `CategoryDistribution` · `RecommendedBooksSection` · `WishlistSection` · `LoadingState` · `ErrorState` · `EmptyState`

> **Visual suggestion:** Place screenshots of the splash, home dashboard, details, and favorites screen in a 2×2 grid on this slide.

---

## Slide 13 — Development Decisions & Challenges

### Challenge → decision → result

| Challenge | Engineering decision | Result |
|---|---|---|
| Raw API data is inconsistent | Normalize responses in the backend | Stable frontend model |
| Large categories can be slow | Use longer subject timeout and clean `502` errors | Better failure feedback |
| Home needs multiple data sources | Use `Future.wait` | Faster initial dashboard |
| Recommendations may overlap | De-duplicate using a `Set` | Cleaner feed |
| Wishlist should work without accounts | Store serialized books locally | Useful offline-friendly feature |

### Development approach

1. Build the API contract.
2. Create reusable Flutter models and widgets.
3. Connect screens through `ApiService`.
4. Add state persistence and error states.
5. Polish animations and the branded visual system.

---

## Slide 14 — Demonstration Plan

### A 90-second live demo

1. Launch the app and show the animated logo.
2. Point out categories, distribution, and recommendations on Home.
3. Search for a book such as **“The Hobbit”**.
4. Open the details page and show cover, authors, rating, and subjects.
5. Tap the heart icon.
6. Open Favorites and show the saved book.
7. Restart or refresh the app to demonstrate persistence.

### Backup plan

If the external API is slow, show the architecture slide and explain that the backend returns a controlled error instead of exposing a raw stack trace.

---

## Slide 15 — Running the Project

### Backend

```bash
cd bookfinder/backend
npm install
npm start
# API: http://localhost:3000
```

### Frontend

```bash
cd bookfinder/frontend
flutter pub get
flutter run
```

### Repository structure

```text
bookfinder/
├── backend/
│   └── src/
│       ├── routes/
│       ├── services/
│       └── utils/normalize.js
└── frontend/
    ├── lib/screens/
    ├── lib/widgets/
    ├── lib/models/
    └── lib/services/api_service.dart
```

---

## Slide 16 — Conclusion & Future Scope

### What we delivered

- A polished cross-platform book discovery app
- A clean Flutter → Express → Open Library architecture
- Search, categories, recommendations, details, and wishlist
- Reusable components, validation, normalization, and persistence
- A branded experience from splash screen to saved collection

### What comes next

- Account-based cloud wishlist synchronization
- Personalized recommendations from reading history
- Redis caching and cursor-based pagination
- Dark mode, localization, and social sharing
- Book previews and read-online integrations where available

## Thank you

### Questions?

**BookFinder — Discover your next favourite book.**

