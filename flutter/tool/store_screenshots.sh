#!/usr/bin/env bash
# Takes the App Store screenshots on the iOS Simulator.
#
# Usage:
#   APP_TOKEN=<production token> tool/store_screenshots.sh
#
# The script boots the simulator, sets a clean status bar, and runs
# integration_test/store_screenshots_test.dart. The test signals each screen
# through a file, and the script saves it with `xcrun simctl io screenshot`.
#
# The app is iPhone only, so App Store Connect needs only 6.9" iPhone
# screenshots (1320 x 2868), as PNG or JPEG without an alpha channel.
set -euo pipefail

cd "$(dirname "$0")/.."

: "${APP_TOKEN:?Set APP_TOKEN to the production app token.}"
PROXY_URL="${PROXY_URL:-https://liityntaparkki-proxy.teemupenttinen.workers.dev}"
OUT_DIR="${OUT_DIR:-../screenshots/app-store}"
BUNDLE_ID=com.liityntaparkki.liityntaparkki
# Söderkulla, the origin of the first commute in the test. The route details
# screen then shows "Aja parkkiin".
LOCATION="${LOCATION:-60.3047,25.2640}"

command -v magick >/dev/null ||
  { echo "ImageMagick is missing. Install it: brew install imagemagick" >&2; exit 1; }

# Prints the UDID of the first available simulator with one of the names.
find_udid() {
  local name udid
  for name in "$@"; do
    udid=$(xcrun simctl list devices available |
      grep -F "    $name (" | head -1 |
      grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' || true)
    if [ -n "$udid" ]; then echo "$udid"; return; fi
  done
}

# Usage: shoot <output folder> <simulator name>...
shoot() {
  local folder="$1"; shift
  local udid out signals pid req shot
  udid=$(find_udid "$@")
  if [ -z "$udid" ]; then
    echo "No simulator found with one of these names: $*" >&2
    echo "Add one in Xcode: Window > Devices and Simulators." >&2
    exit 1
  fi
  out="$OUT_DIR/$folder"
  mkdir -p "$out"
  signals=$(mktemp -d)

  echo "==> $folder on $udid"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl status_bar "$udid" override --time 9:41 \
    --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 \
    --batteryState discharging --batteryLevel 100
  xcrun simctl location "$udid" set "$LOCATION"
  # Works before the app is installed. The map then shows the location dot.
  xcrun simctl privacy "$udid" grant location "$BUNDLE_ID"

  flutter test integration_test/store_screenshots_test.dart -d "$udid" \
    --dart-define=PROXY_URL="$PROXY_URL" \
    --dart-define=APP_TOKEN="$APP_TOKEN" \
    --dart-define=SCREENSHOT_SIGNAL_DIR="$signals" &
  pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    for req in "$signals"/*.request; do
      [ -e "$req" ] || continue
      shot=$(basename "$req" .request)
      xcrun simctl io "$udid" screenshot --type=png "$out/$shot.png" >/dev/null 2>&1
      # App Store Connect rejects images with an alpha channel.
      magick "$out/$shot.png" -background white -alpha remove -alpha off "$out/$shot.png"
      rm "$req"
      touch "$signals/$shot.done"
      echo "    saved $out/$shot.png"
    done
    sleep 0.3
  done

  if ! wait "$pid"; then
    echo "The screenshot test failed on $folder. Read the output above." >&2
    exit 1
  fi
  xcrun simctl status_bar "$udid" clear
  rm -rf "$signals"
}

shoot iphone-6.9 "iPhone 17 Pro Max" "iPhone 16 Pro Max"

echo "Done. Screenshots are in $(cd "$OUT_DIR" && pwd)."
