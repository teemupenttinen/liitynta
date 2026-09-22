# Liityntäpysäköinti

A mobile app that helps Finnish commuters find park-and-ride (P+R) facilities. Search an origin and destination, browse routes ranked by travel time with real-time parking availability, and get contextual navigation handoff to native maps for the driving and transit legs.

The app is built in Flutter. The [Digitransit](https://digitransit.fi/) API (multimodal routing + geocoding) and the [Fintraffic](https://www.digitraffic.fi/) parking API (real-time P+R occupancy) are accessed through a small Cloudflare Worker proxy in [`proxy/`](proxy/) so the Digitransit API key never ships in the app binary. All UI text is in Finnish.

## Repository layout

```
liitynta/
├── flutter/        # Flutter app
├── proxy/          # Cloudflare Worker that proxies Digitransit + Fintraffic
├── design.pen      # Pencil design file
└── images/         # Design assets
```

## Running locally

You need two terminals: one for the proxy, one for the Flutter app.

### 1. Proxy

```bash
cd proxy
npm install
```

Create `proxy/.dev.vars` (gitignored) and fill in your Digitransit key:

```
DIGITRANSIT_API_KEY=<your-digitransit-key>
APP_TOKEN=localdev
```

Get a Digitransit key at [digitransit.fi/en/developers/](https://digitransit.fi/en/developers/). `APP_TOKEN` can be any string for local dev.

Start the worker:

```bash
npx wrangler dev
```

It listens on `http://localhost:8787`.

### 2. Flutter app

```bash
cd flutter
flutter pub get
flutter run \
  --dart-define=PROXY_URL=http://localhost:8787 \
  --dart-define=APP_TOKEN=localdev
```

`PROXY_URL` must match the proxy's address; `APP_TOKEN` must match the one in `proxy/.dev.vars`. On Android emulator use `http://10.0.2.2:8787` instead of `localhost`.

## Deploying the proxy

```bash
cd proxy
wrangler secret put DIGITRANSIT_API_KEY   # paste your key
wrangler secret put APP_TOKEN             # paste a strong random value
wrangler deploy
```

Then build the app with the production proxy URL and token:

```bash
flutter run \
  --dart-define=PROXY_URL=https://liityntaparkki-proxy.<your-account>.workers.dev \
  --dart-define=APP_TOKEN=<the-same-token-as-in-the-secret>
```

## More

- [`flutter/README.md`](flutter/README.md) — Flutter-specific setup, structure, native scaffold
- [`PRODUCTION_CHECKLIST.md`](PRODUCTION_CHECKLIST.md) — outstanding work before shipping
