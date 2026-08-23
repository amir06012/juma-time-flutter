import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_controller.dart';
import 'mosque_list_screen.dart';
import 'qibla_screen.dart';
import 'admin_login_screen.dart';
import 'settings_screen.dart';
import 'silent_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  final LocaleController localeController;

  const HomeScreen({super.key, required this.localeController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Built in build() (not as a static const list) so its Settings tab
    // picks up the LocaleController passed down from main.dart.
    final screens = [
      const MosqueListScreen(),
      const QiblaScreen(),
      const SilentModeScreen(),
      SettingsScreen(localeController: widget.localeController),
    ];

    return Scaffold(
      // IndexedStack (not `screens[_index]`) keeps all tabs mounted at once
      // and just hides the inactive ones, instead of disposing and
      // rebuilding whichever isn't selected. Switching tabs used to tear
      // down MosqueListScreen's State entirely, so coming back to it re-ran
      // initState() and refetched mosques/prayer times from scratch every
      // time - this keeps that fetched state alive across tab switches.
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.mosque), label: l10n.navMosques),
          BottomNavigationBarItem(icon: const Icon(Icons.explore), label: l10n.navQibla),
          BottomNavigationBarItem(icon: const Icon(Icons.volume_off), label: l10n.navSilentMode),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: l10n.navSettings),
        ],
      ),
      // Discreet way to reach the admin approval screen - not meant for
      // regular users to notice. Move/hide this however you prefer once
      // you have a real admin workflow in place.
      floatingActionButton: IconButton(
        icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        ),
      ),
    );
  }
}
