import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/main_tabs.dart';
import 'screens/route_detail_screen.dart';

const _proxyUrl = String.fromEnvironment('PROXY_URL');
const _appToken = String.fromEnvironment('APP_TOKEN');

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Only report crashes from real users; debug runs would pollute the dashboard.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(kReleaseMode);

    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (_proxyUrl.isEmpty || _appToken.isEmpty) {
      runApp(const _ConfigErrorApp());
      return;
    }

    final state = AppState();
    await state.load();
    runApp(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const LiityntaparkkiApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sovelluksen asetukset puuttuvat',
                    style: AppTextStyles.subhero,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sovellus tarvitsee PROXY_URL ja APP_TOKEN -arvot käynnistyäkseen. '
                    'Käännä uudelleen lipuilla:',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFF0F0F0),
                    child: SelectableText(
                      'flutter run \\\n'
                      '  --dart-define=PROXY_URL=http://localhost:8787 \\\n'
                      '  --dart-define=APP_TOKEN=<token>',
                      style: AppTextStyles.paragraph.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiityntaparkkiApp extends StatelessWidget {
  const LiityntaparkkiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liityntäparkki',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const MainTabs(),
        '/route-detail': (_) => const RouteDetailScreen(),
      },
    );
  }
}
