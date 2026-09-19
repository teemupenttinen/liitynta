// Drives the app through the screens that go to the App Store.
//
// Do not run this file directly. tool/store_screenshots.sh runs it on each
// simulator and saves every screen that the test signals.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liityntaparkki/main.dart';
import 'package:liityntaparkki/models/route.dart';
import 'package:liityntaparkki/state/app_state.dart';
import 'package:liityntaparkki/widgets/autocomplete_input.dart';

// Folder where the test and the script exchange signal files. Empty when
// the test runs without the script: then it only pauses at each screen.
const _signalDir = String.fromEnvironment('SCREENSHOT_SIGNAL_DIR');

// Saved commute pairs. The test searches them in turn and shows the first
// one that finds a P+R with free spaces. The script puts the simulator
// location at the origin of the first pair.
const _commutes = [
  ('Söderkulla, Sipoo', 'Kamppi, Helsinki'),
  ('Kirkkonummi', 'Keilaniemi, Espoo'),
  ('Tuusula', 'Pasila, Helsinki'),
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Draw every frame that the app asks for, as in a normal run. The default
  // policy draws only the frames that the test pumps.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('store screenshots', (tester) async {
    // Start from empty storage, so that earlier runs leave no favourites.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Same as main(), without Firebase.
    final state = AppState();
    await state.load();
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const LiityntaparkkiApp(),
    ));

    await _waitFor(tester, () {
      if (state.facilitiesError != null) {
        fail('Parking data did not load: ${state.facilitiesError} '
            'Make sure that PROXY_URL and APP_TOKEN are correct.');
      }
      return state.facilities.isNotEmpty;
    }, 'parking data');

    // Big facilities with live counts make the fullest favourites list.
    final live = state.facilities.where((f) => (f.available ?? 0) > 0).toList()
      ..sort((a, b) => b.capacity.compareTo(a.capacity));
    for (final (i, c) in _commutes.indexed) {
      state.addCommutePair(CommutePair(
        id: 'pair-$i',
        origin: c.$1,
        destination: c.$2,
        createdAt: DateTime.now(),
      ));
    }
    for (final f in live.take(3)) {
      state.addFavouriteParkingSpot(
          FavouriteParkingSpot(id: f.id, facilityId: f.id, name: f.name));
    }

    await tester.pump(const Duration(milliseconds: 500));
    _centerPins(tester);
    await _shot(tester, '01-kartta');

    // Open the sheet of the biggest P+R that has a pin on the visible map.
    // The map builds pins only for the area on screen.
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final pin = live.map((f) => _pin(f.name)).firstWhere(
          (finder) {
            if (finder.evaluate().isEmpty) return false;
            final c = tester.getCenter(finder.first);
            // Below the search fields and above the tab bar.
            return c.dx > 40 &&
                c.dx < screen.width - 40 &&
                c.dy > 300 &&
                c.dy < screen.height - 200;
          },
          orElse: () => fail('No P+R pin on the visible map.'),
        );
    await tester.tap(pin.first, warnIfMissed: false);
    await _waitFor(tester, () => _present(find.text('Navigoi parkkiin')),
        'the parking sheet');
    await _shot(tester, '02-parkkipaikka');

    // Search the saved commutes in turn, until one finds a free P+R.
    var found = false;
    for (final c in _commutes) {
      await tester.tap(find.text('SUOSIKIT'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(c.$1));
      await _waitFor(tester, () => !state.isSearching, 'the search',
          timeout: const Duration(seconds: 90));
      await tester.pump(const Duration(seconds: 1));
      found = _present(find.text('Näytä reitti'));
      if (found) break;
      debugPrint('No route with a free P+R for ${c.$1} → ${c.$2}.');
    }
    if (!found) fail('No saved commute found a free P+R. Change _commutes.');
    await _shot(tester, '03-reitit');

    final expand = find.textContaining('muuta tulosta');
    if (_present(expand)) {
      await tester.tap(expand);
      await _shot(tester, '04-kaikki-reitit');
    }

    await tester.tap(find.text('Näytä reitti').first);
    await _waitFor(
        tester, () => _present(find.text('Reitin tiedot')), 'route details');
    await _shot(tester, '05-reitin-tiedot');

    await tester.tap(find.byIcon(LucideIcons.arrowLeft).first);
    await _waitFor(tester, () => !_present(find.text('Reitin tiedot')),
        'the map after route details');

    await tester.tap(find.text('SUOSIKIT'));
    await _shot(tester, '06-suosikit');

    await tester.tap(find.text('ASETUKSET'));
    await _shot(tester, '07-asetukset');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

/// Finds the map pin of one facility, or all pins when [facilityName] is null.
Finder _pin([String? facilityName]) => find.byWidgetPredicate((w) =>
    w is Semantics &&
    (w.properties.label ?? '').startsWith(facilityName == null
        ? 'Pysäköinti '
        : 'Pysäköinti $facilityName,'));

/// Moves the map so that the P+R pins sit in the middle of the free area
/// between the search fields and the tab bar. The default view of the app
/// puts most pins in the top half and the sea in the bottom half.
void _centerPins(WidgetTester tester) {
  final top = tester.getRect(find.byType(AutocompleteInput).last).bottom;
  final bottom = tester.getRect(find.byType(BottomNavigationBar)).top;
  final pins = _pin();
  final ys = [
    for (var i = 0; i < pins.evaluate().length; i++)
      tester.getCenter(pins.at(i)).dy,
  ].where((y) => y > 0 && y < bottom).toList();
  if (ys.isEmpty) return;
  final pinsMiddle = (ys.reduce(math.min) + ys.reduce(math.max)) / 2;
  final dy = (top + bottom) / 2 - pinsMiddle;
  final map = tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
  final camera = map.camera;
  final size = camera.nonRotatedSize;
  map.move(camera.pointToLatLng(math.Point(size.x / 2, size.y / 2 - dy)),
      camera.zoom);
}

bool _present(Finder finder) => finder.evaluate().isNotEmpty;

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() condition,
  String what, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for $what.');
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Asks tool/store_screenshots.sh to save the screen and waits until it has.
Future<void> _shot(WidgetTester tester, String name) async {
  // Time for map tiles to load and for animations to end.
  await tester.pump(const Duration(seconds: 4));
  if (_signalDir.isEmpty) return;
  File('$_signalDir/$name.request').writeAsStringSync(name);
  final done = File('$_signalDir/$name.done');
  await _waitFor(tester, done.existsSync, 'the script to save $name');
}
