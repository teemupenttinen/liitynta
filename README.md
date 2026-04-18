# Liityntäparkki

A mobile app that helps Finnish commuters find park-and-ride (P+R) facilities. Search an origin and destination, browse routes ranked by travel time with real-time parking availability, and get contextual navigation handoff to native maps for the driving and transit legs.

The app is built in Flutter and uses the [Digitransit](https://digitransit.fi/) API for multimodal routing and geocoding, and the [Fintraffic Digitraffic](https://www.digitraffic.fi/) API for real-time P+R occupancy data. All UI text is in Finnish.

## Getting started

The Flutter app lives in [flutter/](flutter/). See [flutter/README.md](flutter/README.md) for setup, API keys, and run instructions.

```bash
cd flutter
flutter pub get
flutter run --dart-define=DIGITRANSIT_API_KEY=<your-key>
```
