# Liityntäpysäköinti – Flutter port

1:1 Flutter port of the Expo React Native app in `../app`. Helps Finnish commuters find park-and-ride (P+R) facilities with Digitransit routing and Fintraffic real-time parking utilization.

## Setup

```bash
cd flutter
flutter pub get
```

### Required API keys

1. **Digitransit API key** — pass at build/run time:
   ```
   flutter run --dart-define=DIGITRANSIT_API_KEY=<your-key>
   ```

2. **Google Maps API key** — add to the native projects:
   - Android: `android/app/src/main/AndroidManifest.xml`
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY"
                android:value="YOUR_API_KEY"/>
     ```
   - iOS: `ios/Runner/AppDelegate.swift`
     ```swift
     GMSServices.provideAPIKey("YOUR_API_KEY")
     ```

### Location permissions

- iOS `Info.plist`:
  ```
  NSLocationWhenInUseUsageDescription = Sijaintia käytetään reitin suunnitteluun ja navigointiin.
  ```
- Android `AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  <uses-permission android:name="android.permission.INTERNET"/>
  ```

### Generate the native scaffold

Flutter's native project files (`android/`, `ios/`) are not checked in. Run:

```bash
flutter create --org com.liityntapysakointi --project-name liityntapysakointi .
```

from this directory to generate them on first setup, then apply the API key + permission edits above.

## Structure

```
flutter/
├── pubspec.yaml
├── lib/
│   ├── main.dart                       # App entry + routes
│   ├── theme.dart                      # Design tokens (mirrors src/lib/theme.ts)
│   ├── models/route.dart               # Route / Facility / favourites models
│   ├── services/
│   │   ├── digitransit.dart            # Digitransit + Fintraffic API clients
│   │   └── navigation.dart             # Native maps deep links
│   ├── state/app_state.dart            # ChangeNotifier (mirrors zustand store)
│   ├── widgets/
│   │   ├── main_tabs.dart              # KARTTA / SUOSIKIT / ASETUKSET tab bar
│   │   ├── autocomplete_input.dart     # Debounced geocoding input
│   │   └── route_card.dart             # Glanceable route card
│   └── screens/
│       ├── map_screen.dart             # Map + search + results sheet
│       ├── favourites_screen.dart      # Commute pairs + parking spots
│       ├── settings_screen.dart        # Walking speed + availability toggle
│       └── route_detail_screen.dart    # Leg-by-leg + contextual CTA
```

## Parity notes vs. the RN app

- **State**: `AppState` (ChangeNotifier + Provider) replaces zustand — same fields/actions.
- **API**: direct ports of `searchRoutes`, `autocomplete`, `geocode`, `fetchParkAndRideFacilities`, including polyline decoding, detour ranking, metro bonus, walk-speed modulation.
- **Maps**: uses `google_maps_flutter`. P+R markers use `BitmapDescriptor.defaultMarkerWithHue` mapped to availability color — visually simpler than the custom pin/label widgets in RN (Flutter requires baking a bitmap to reproduce those exactly).
- **Bottom sheet**: `DraggableScrollableSheet` replaces the hand-rolled reanimated pan gesture. Snap points are equivalent (collapsed/expanded).
- **Navigation CTA**: `navigateTo` / `navigateTransit` / `getNavigationState` ported 1:1.
- **Persistence**: none yet, matching the RN app (MMKV is installed there but not wired up either).
