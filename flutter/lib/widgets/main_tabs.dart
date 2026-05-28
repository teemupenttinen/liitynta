import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../screens/map_screen.dart';
import '../screens/favourites_screen.dart';
import '../screens/settings_screen.dart';

class MainTabs extends StatelessWidget {
  const MainTabs({super.key});

  static const _screens = <Widget>[
    MapScreen(),
    FavouritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: IndexedStack(index: state.activeTabIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: state.activeTabIndex,
        onTap: state.setActiveTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.bgWhite,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.map), label: 'KARTTA'),
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.heart), label: 'SUOSIKIT'),
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings), label: 'ASETUKSET'),
        ],
      ),
    );
  }
}
