# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EndMile is a Flutter web application for comparing multimodal commute options in East Yorkshire (Beverley, Hull, Brough, York, Eastrington → Wellington Place, Leeds). It loads route data from local JSON assets (no backend API), displays journey options with map visualization, and lets users compare by speed, cost, and risk.

Deployed to GitHub Pages at `/Apptest/`.

## Common Commands

All Flutter commands must be run from the `client/` directory:

```bash
cd client
flutter pub get          # Install dependencies
flutter analyze          # Run linter (flutter_lints)
flutter test             # Run all tests
flutter test test/api_service_test.dart   # Run a single test file
flutter build web        # Build for web
flutter build web --release --base-href "/Apptest/"  # Production build for GitHub Pages
flutter run -d chrome    # Run locally in Chrome
```

## Architecture

### Directory Layout (under `client/lib/`)

- **models.dart** — All data classes: `Segment`, `Leg`, `JourneyResult`, `SegmentOptions`, `DirectDrive`, `Emissions`, `InitData`. Each has `fromJson` factories.
- **services/api_service.dart** — Loads route data from `assets/routes_clean.json` and `routes_2_clean.json`. `fetchInitData()` returns all options; `searchJourneys()` filters by transport mode and sorts by tab.
- **providers/route_provider.dart** — Single `ChangeNotifierProvider` (`RouteProvider`) managing selected route for map display.
- **screens/** — `HomePage` (search form + mode filters), `SummaryPage` (results with Smart/Fastest/Cheapest tabs), `DetailPage` (map + itinerary), `DirectDrivePage`.
- **widgets/** — Reusable components (journey cards, timeline, map, leg selector modal, etc.).
- **utils/** — `app_colors.dart` (HSL color system), `emission_utils.dart` (CO2 per mode), `route_selector.dart` (diversity-first sorting), `risk_helper.dart` (per-leg risk scoring).

### Key Patterns

- **Responsive layout**: `ResponsiveLayout` widget switches at 800px breakpoint — mobile gets single view, desktop gets split-screen (400px left panel + map).
- **State flow**: Provider wraps app in `main.dart` → screens read/write via `RouteProvider` → map widget reacts to changes.
- **Smart sorting algorithm** (`route_selector.dart`): Groups journeys by anchor (destination), scores with `cost + (time * 0.3) + ((risk - minRisk) * 20.0) + emissions`, then selects diversity-first across groups before adding depth.
- **No backend/env vars**: All data comes from bundled JSON assets. No API keys or environment configuration needed.

### Design System

Defined in `client/DESIGN_SYSTEM.md`. Key values:
- Primary: `#4F46E5` (indigo), Secondary: `#0F766E` (teal)
- Font: Inter (via google_fonts), 14px base
- Border radius: 12px standard, 8px small
- Press feedback: 0.96 scale via `ScaleOnPress` widget, 100ms ease-out

## CI/CD

GitHub Actions (`.github/workflows/`):
- **ci.yml**: On push/PR to main → `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build web`
- **deploy.yml**: On push to main → builds release web with `--base-href "/Apptest/"` → deploys to GitHub Pages

## Data Pipeline

Python scripts in `client/` (`process_routes.py`, `fetch_stops.py`, `verification_script.py`) process raw route data into the clean JSON assets consumed by the app.
