import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:freetier_radar/theme/app_theme.dart';
import 'package:freetier_radar/screens/home_screen.dart';
import 'package:freetier_radar/screens/alerts_screen.dart';
import 'package:freetier_radar/screens/stack_calculator_screen.dart';
import 'package:freetier_radar/screens/bookmarks_screen.dart';
import 'package:freetier_radar/screens/settings_screen.dart';
import 'package:freetier_radar/screens/assistant_screen.dart';
import 'package:freetier_radar/l10n/app_strings.dart';
import 'package:freetier_radar/providers/services_provider.dart';
import 'package:freetier_radar/screens/onboarding_screen.dart';
import 'package:freetier_radar/screens/comparison_screen.dart';
import 'package:freetier_radar/services/local_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local caching
  await Hive.initFlutter();
  await LocalCacheService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Check if onboarding has been shown
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(ProviderScope(
    child: FreeTierRadarApp(hasSeenOnboarding: hasSeenOnboarding),
  ));
}

/// Root application widget.
class FreeTierRadarApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const FreeTierRadarApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreeTier Radar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: hasSeenOnboarding
          ? const MainNavigationScreen()
          : const OnboardingScreen(),
    );
  }
}

/// Bottom navigation host with four tabs + settings access.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AssistantScreen(),
    AlertsScreen(),
    StackCalculatorScreen(),
    BookmarksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsProvider).locale;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Compare FAB only on Explore tab
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryBlue,
              tooltip: 'Compare Services',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ComparisonScreen()),
                );
              },
              child: const Icon(Icons.compare_arrows,
                  color: AppTheme.mantleColor),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined),
            activeIcon: const Icon(Icons.explore),
            label: AppStrings.get('explore', locale),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: AppStrings.get('assistant', locale),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_outlined),
            activeIcon: const Icon(Icons.notifications),
            label: "Alerts", // We can add alerts to app_strings later
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.layers_outlined),
            activeIcon: const Icon(Icons.layers),
            label: "Stack",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_border),
            activeIcon: const Icon(Icons.bookmark),
            label: AppStrings.get('bookmarks', locale),
          ),
        ],
      ),
    );
  }
}
