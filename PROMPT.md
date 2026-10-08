# Build: SnapSort — Smart Screenshot Organizer (Flutter, Android)

> Working name "SnapSort" — rename freely. Package id: `com.yourname.snapsort` (replace).

## 1. Goal

Build a production-quality Android app in Flutter that turns a messy screenshot folder into an organized, searchable, actionable library — **100% on-device, no backend, no paid APIs, no accounts**.

Pitch: *"Your screenshots, finally useful. Search, act on and clean up, all private, all on your phone."*

Three core promises:
1. **Find**: search any screenshot by the text inside it.
2. **Act**: one tap to open a link, call or WhatsApp a number, copy an OTP, open an address in Maps.
3. **Clean**: detect screenshots that are no longer needed (old OTPs, duplicates, delivered orders) and free storage, showing "X MB freed".

The UI must feel **premium, smooth and modern** — think Linear / Arc / Things 3 polish on Android. 60fps everywhere, no jank during scanning.

## 2. Hard constraints

- Flutter (latest stable), Dart null-safe, Material 3. **Android only** for v1 (minSdk 24, target latest).
- Fully offline. No network calls, no analytics, no ads in v1.
- Free on-device ML only: Google ML Kit Text Recognition (Latin script).
- Before using any package, **check its current API on pub.dev** — don't guess method signatures. Use latest stable compatible versions.
- Run `flutter analyze` with zero warnings at the end of each phase. Commit after each phase.

## 3. Tech stack

| Concern | Choice |
|---|---|
| State | `flutter_riverpod` (with code-gen optional; keep it simple) |
| Routing | `go_router` (with shell route for bottom nav) |
| Local DB | `drift` + SQLite **FTS5** for full-text search |
| Gallery access | `photo_manager` (permissions, albums, thumbnails, system delete dialog) |
| OCR | `google_mlkit_text_recognition` |
| Prefs | `shared_preferences` (onboarding done, settings) |
| Animation | `flutter_animate` + implicit/explicit Flutter animations |
| Fonts | `google_fonts` — **Plus Jakarta Sans** (UI) |
| Splash | `flutter_native_splash` |
| Actions | `url_launcher`, `share_plus` |
| Background (stretch) | `workmanager` |

Architecture: feature-first folders, clean separation of data / domain / UI.

```
lib/
  app/            (app.dart, router.dart, theme/)
  core/           (design tokens, widgets, utils, haptics)
  data/           (drift db, daos, repositories)
  services/       (gallery_service, ocr_service, scan_service)
  domain/         (classifier/, entity_extractor/, cleanup_rules/)
  features/
    splash/ onboarding/ scan/ home/ search/ category/ detail/ cleanup/ settings/
```

## 4. Android setup

- Permissions in manifest: `READ_MEDIA_IMAGES` (API 33+), `READ_MEDIA_VISUAL_USER_SELECTED` (API 34+ partial access), `READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"`.
- Handle **partial access (Android 14)** gracefully: show a banner "SnapSort can only see some screenshots — Allow all" that re-opens the permission picker.
- Deletion: use `photo_manager`'s delete API, which shows the **system confirmation dialog** on Android 11+ (MediaStore delete request). Never try to bypass it. After confirmation, remove rows from the DB.
- Add ML Kit model dependency so the text model is bundled (works offline on first launch).

## 5. Data model (drift)

**screenshots**
- `assetId` (PK, String), `filePath`, `fileName`, `createdAt`, `width`, `height`, `sizeBytes`
- `ocrText` (String, nullable), `category` (enum as text), `sourceApp` (nullable)
- `isFavorite` (bool), `textHash` (for duplicates), `processedAt` (nullable — null = not yet scanned)

**entities**
- `id`, `assetId` (FK), `type` (url | phone | email | otp | amount | date | address | tracking), `value`, `displayValue`

**screenshots_fts** — FTS5 virtual table over `ocrText` + `fileName`, kept in sync with triggers.

Search must be instant (<50ms) on 5,000 rows, support prefix matching, and return highlighted snippets.

## 6. Scan pipeline (most important — make it robust)

1. **Find screenshots**: using `photo_manager`, pick albums whose name contains "Screenshot" (case-insensitive) or whose path contains `Screenshots`; also include any image whose file name starts with `Screenshot`. De-duplicate by asset id.
2. **Diff**: insert new assets into DB with `processedAt = null`; remove rows whose assets no longer exist.
3. **Process queue**: take unprocessed rows newest-first in **batches of 8**. For each: get file → run ML Kit OCR → run extractor + classifier → write results in one transaction.
4. **Progress**: expose a `Stream<ScanProgress>` (processed, total, current category counts) that the UI listens to.
5. **Performance**: never block the UI thread; yield between batches; downscale nothing for OCR but use small cached thumbnails (`thumbnailDataWithSize(300x300)`) for grids.
6. **Resumable**: if the app is killed mid-scan, the next launch continues from where it stopped (because `processedAt` is null).
7. **Incremental**: on app resume and on pull-to-refresh, run steps 1–3 for new screenshots only.
8. **Stretch**: `workmanager` periodic task (15 min) for background scanning.

## 7. Classification & extraction (pure Dart, unit tested)

Put this in `domain/` with **no Flutter imports**, so it's fully unit-testable. Write tests with realistic sample OCR strings for every category.

### Source app from file name
Many devices name files like `Screenshot_20261008-145012_WhatsApp.jpg`. Parse the trailing app segment into `sourceApp` (WhatsApp, Chrome, Instagram, Gmail, YouTube, etc.). Use it as a strong signal (e.g. WhatsApp → Chats unless a stronger rule matches).

### Categories (evaluate in this priority order; first match wins)

| Category | Signals (case-insensitive) |
|---|---|
| 🔐 **OTP** | 4–8 digit code near words: OTP, code, verification, one-time, PIN |
| 🧾 **Receipts** | currency (Rs, PKR, $, €, £, ₹, AED, SAR) + amount AND any of: paid, transaction, TID, transfer, successful, receipt, invoice, total |
| 📦 **Orders** | order, tracking, shipped, delivered, out for delivery, courier, order # |
| ⚠️ **Errors** | error, exception, failed, crash, stack trace, null, 404/500 |
| 🔗 **Links** | URL present and text is short / URL-dominant |
| 💬 **Chats** | sourceApp is a messenger, or multiple timestamps like `10:42 pm` on separate lines |
| 📝 **Notes & Info** | long text (> 40 words) not matching above |
| 🖼️ **Images & Memes** | very little text (< 5 words) |
| 📁 **Others** | fallback |

### Entity extraction
Regex-based extractors for: URLs, phone numbers (international + Pakistani `03xx-xxxxxxx` formats), emails, OTP codes, currency amounts, dates, tracking-number-like tokens. Store each in `entities`.

### Duplicates
`textHash` = hash of normalized OCR text (lowercased, whitespace collapsed). Same hash + same dimensions = duplicate group. Skip hashing when text < 5 words.

## 8. Features & screens

### 8.1 Splash
- Native splash (`flutter_native_splash`) with the background color + app mark, so there's no white flash.
- Then a Flutter splash: logo mark scales from 0.8 → 1.0 with a soft glow and the wordmark fades/slides in. **Total under 1.2s** — no fake waiting.
- Route: onboarding not done → Onboarding; permission missing → Permission screen; else → Home.

### 8.2 Onboarding (3 pages + permission + first scan)
Illustrations are **built in code** (CustomPainter / stacked animated widgets) — no external image assets needed.
1. **"Find anything"** — floating screenshot cards; a search bar types "wifi password" and one card lights up.
2. **"Act in one tap"** — a card with a link/phone; action chips pop in with spring animation.
3. **"Clean up, privately"** — cards dissolve into particles, a storage meter fills up "2.3 GB freed"; small lock badge "Never leaves your phone".
- Swipe + button; morphing pill page indicator; Skip in the top-right; haptic tick on page change.
4. **Permission screen** — clear privacy copy, one primary button; handles denied / permanently denied (open settings) / partial access.
5. **First scan screen** — large animated progress ring with counter ("Sorting 412 of 1,240"), category chips appearing and counting up live, subtle shimmer. On finish: celebration moment ("1,240 screenshots sorted ✨") + confetti-like particles, then auto-navigate to Home.

### 8.3 App shell & bottom nav
- **Floating pill bottom nav**, rounded 28, frosted blur (`BackdropFilter`), 4 tabs: **Home, Search, Clean, Settings**.
- Animated active indicator that slides between tabs; active icon fills + label appears; haptic selection click.
- The nav hides on scroll down and shows on scroll up.
- Each tab keeps its own state (StatefulShellRoute).

### 8.4 Home (dashboard)
- Header: "Good afternoon" + small subtitle "1,240 screenshots · 3.4 GB".
- **Search pill** (tap → Hero transition into Search tab with keyboard focused).
- **Storage card**: total size, a segmented bar by category, and "1.1 GB can be cleaned → Review" CTA.
- **Category grid** (2 columns): each tile has its own accent color, icon, count, and a stacked mini-preview of 3 thumbnails. Press = scale 0.97 + haptic.
- **Recent** horizontal strip of latest screenshots.
- Pull to refresh → incremental scan with a slim progress indicator.
- If a scan is running in the background, show a compact live progress banner.

### 8.5 Search
- Instant search-as-you-type (debounce 150ms) on FTS.
- Results: thumbnail + highlighted text snippet + category chip + date.
- Filter chips row: categories, source apps, date (Today / This week / This month / Older).
- Empty state with suggestions ("Try: OTP, receipt, wifi, address").
- Recent searches saved locally.

### 8.6 Category screen
- Masonry-ish or uniform 3-column grid with smooth thumbnails (fade-in, cached).
- Sort: newest / oldest / largest.
- **Multi-select** with long press: select all, share, delete (system dialog), favorite.
- For **Receipts**: show a summary header with the total amount detected this month (by currency).

### 8.7 Screenshot detail
- Full-screen image with `InteractiveViewer` (pinch zoom), Hero from the grid, swipe down to dismiss, swipe left/right for neighbors.
- Bottom sheet (draggable) with:
  - **Action chips** from entities: Open link, Call, WhatsApp (`https://wa.me/<number>`), Copy OTP, Open in Maps, Email, Copy amount.
  - Extracted text (selectable) + "Copy all".
  - Metadata: date, source app, size, category (tap to change category manually — save the override).
  - Share, Favorite, Delete.

### 8.8 Clean (cleanup)
- Hero card: "You can free **1.1 GB**" with an animated counter.
- Suggestion groups (each a card with count, size and preview stack, tap to review):
  - **Old OTPs** (older than 24h)
  - **Duplicates** (keep newest, select the rest)
  - **Delivered orders** older than 30 days
  - **Large screenshots** (top by size)
  - **Older than 6 months**
- Review screen: pre-selected grid, user can unselect, then "Delete 54 · 312 MB". After system confirmation → success animation showing MB freed + haptic.

### 8.9 Settings
- Theme: System / Light / Dark.
- Re-scan all screenshots (with confirm).
- Manage folders: show detected screenshot albums, toggles to include/exclude.
- Privacy section: "Everything is processed on your device. Nothing is uploaded." 
- About, version, rate app (Play Store link), open-source licenses.

## 9. Design system (make it feel premium)

**Theme**: dark-first (also ship a polished light theme).

Dark tokens:
- Background `#0B0B10`, surface `#15151C`, elevated surface `#1D1D26`, border `rgba(255,255,255,0.06)`
- Text primary `#F4F4F6`, secondary `#9A9AA8`, tertiary `#5E5E6B`
- Brand gradient: `#7C5CFF → #4FC3F7` (used sparingly: logo, primary button, progress ring)

Category accents (soft, muted, not neon): OTP violet, Receipts green, Orders amber, Errors coral, Links blue, Chats teal, Notes slate, Images pink, Others gray. Use each at 12–16% opacity for tile backgrounds with the full color for icons.

Rules:
- 8pt spacing grid; screen padding 20; radii 12 / 20 / 28.
- Typography: Plus Jakarta Sans; display 32/700, title 20/600, body 15/400, caption 12/500; slight negative letter-spacing on large text.
- Icons: rounded Material Symbols, consistent weight.
- Motion: 200–350ms, `Curves.easeOutCubic` for enter, spring for presses; stagger list/grid items (30ms per item, first load only).
- Haptics: selection click for tabs/chips, light impact for presses, medium for delete success.
- Loading: shimmer skeletons, never bare spinners in content areas.
- Every list/grid has a designed **empty state** and an **error state**.
- Edge-to-edge with transparent status/navigation bars.
- Respect system text scale and "remove animations" accessibility setting.
- Min touch target 48dp; contrast AA.

## 10. Performance bar

- Grids: `GridView.builder`, fixed-size cached thumbnails, `const` widgets, `RepaintBoundary` around heavy items.
- No synchronous file I/O or DB work in `build`.
- Scan must keep the UI at 60fps — test with 1,000+ screenshots.
- Cold start to first frame of Home < 1.5s on a mid-range device (after onboarding).

## 11. Build plan — follow in order, commit after each phase

**Phase 0 — Setup (15 min)**: create project, packages, manifest permissions, theme tokens, fonts, router skeleton, native splash.

**Phase 1 — Core engine (45 min)**: drift DB + FTS5, gallery service, OCR service, classifier + extractor in `domain/` with unit tests, scan service with progress stream. Verify with a debug screen that scanning real screenshots fills the DB correctly.

**Phase 2 — Shell & flows (35 min)**: splash, onboarding (3 pages), permission screen, first-scan screen, floating bottom nav shell.

**Phase 3 — Features (45 min)**: Home dashboard, Search, Category grid with multi-select, Detail with action chips, Cleanup with review + delete, Settings.

**Phase 4 — Polish (20 min)**: animations, haptics, empty/error states, light theme check, `flutter analyze` clean, test on a real device, fix jank.

If time runs short, **cut in this order**: workmanager background scan → folder include/exclude → receipts monthly total → swipe between screenshots in detail. Never cut: scan pipeline, search, action chips, cleanup, splash/onboarding/nav polish.

## 12. Definition of done

- [ ] Fresh install → splash → onboarding → permission → live first scan → Home, with no glitches.
- [ ] Screenshots correctly sorted into categories; classifier unit tests pass.
- [ ] Search finds a screenshot by a word inside it, instantly, with highlighted snippets.
- [ ] Detail action chips work: open URL, call, WhatsApp, copy OTP, maps.
- [ ] Cleanup suggestions appear; delete goes through the system dialog and shows MB freed.
- [ ] New screenshots appear after resume / pull-to-refresh.
- [ ] Partial-access and denied-permission states are handled.
- [ ] Dark and light themes both look polished; no overflow on small screens.
- [ ] `flutter analyze` clean; release APK builds (`flutter build apk --release`).

## 13. Out of scope (v1)

iOS, cloud sync/backup, accounts, ads, in-app purchases, non-Latin OCR, AI/LLM APIs.

---

**Start by briefly confirming the plan and the package list (with current versions from pub.dev), then implement Phase 0 immediately. Work through the phases without waiting for approval unless something is blocked. At the end, give me a short summary of what's done, what was cut, and how to test.**
