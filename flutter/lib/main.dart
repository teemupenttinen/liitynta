import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/main_tabs.dart';
import 'screens/route_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  state.load();
  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const LiityntaApp(),
    ),
  );
}

class LiityntaApp extends StatelessWidget {
  const LiityntaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liityntaparkki',
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
