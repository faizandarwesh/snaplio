# SnapLio

Your screenshots, finally useful. Search, act on and clean up, all private, all on your phone.

Android-only Flutter app. 100% on-device: ML Kit OCR (bundled Latin model), SQLite FTS5 search, no network calls, no accounts.

## Run

```sh
flutter pub get
dart run build_runner build      # drift code-gen (already committed)
flutter run                      # on an Android device with some screenshots
flutter build apk --release --split-per-abi
```

## Test

```sh
flutter test        # domain rules, FTS5 repository, small-screen widget smoke tests
flutter analyze
```

## Layout

```
lib/
  app/         app, router (go_router + StatefulShellRoute), shell (floating nav), providers, theme
  core/        design tokens, haptics, formatters, shared widgets
  data/        drift DB (+ FTS5 triggers), repository
  services/    gallery (photo_manager), OCR (ML Kit), scan pipeline
  domain/      pure Dart: extractor, classifier, source app, cleanup rules (unit tested)
  features/    splash, onboarding, scan, home, search, category, detail, cleanup, settings
tool/gen_icons.dart   regenerates the launcher icon + splash mark PNGs
```

Debug builds include **Settings → Scan diagnostics** for inspecting what the scanner wrote to the DB.
