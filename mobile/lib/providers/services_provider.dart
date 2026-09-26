import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

// Settings State
class AppSettings {
  final String apiBaseUrl;
  final AppThemeType themeType;
  final bool hasSeenOnboarding;

  const AppSettings({
    this.apiBaseUrl = 'https://freetier-radar-backend.onrender.com',
    this.themeType = AppThemeType.catppuccin,
    this.hasSeenOnboarding = false,
  });

  AppSettings copyWith({
    String? apiBaseUrl,
    AppThemeType? themeType,
    bool? hasSeenOnboarding,
  }) {
    return AppSettings(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      themeType: themeType ?? this.themeType,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = 'https://freetier-radar-backend.onrender.com';
    final themeStr = prefs.getString('themeType') ?? AppThemeType.catppuccin.name;
    final themeType = AppThemeType.values.firstWhere(
      (e) => e.name == themeStr,
      orElse: () => AppThemeType.catppuccin,
    );
    final onboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    state = AppSettings(
      apiBaseUrl: baseUrl,
      themeType: themeType,
      hasSeenOnboarding: onboarding,
    );
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiBaseUrl', url);
    state = state.copyWith(apiBaseUrl: url);
  }

  Future<void> setTheme(AppThemeType theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeType', theme.name);
    state = state.copyWith(themeType: theme);
  }

  Future<void> setHasSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', seen);
    state = state.copyWith(hasSeenOnboarding: seen);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

// Theme Provider Alias
final themeProvider = StateProvider<AppThemeType>((ref) {
  return ref.watch(settingsProvider).themeType;
});

// Cache Service Provider
final localCacheProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

// 1. Api Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final settings = ref.watch(settingsProvider);
  final cache = ref.watch(localCacheProvider);
  return ApiService(
    baseUrl: settings.apiBaseUrl,
    cacheService: cache,
  );
});

// 2. Services Filter State & Provider
class ServicesFilter {
  final ServiceCategory category;
  final bool noCreditCard;
  final String searchQuery;

  const ServicesFilter({
    this.category = ServiceCategory.ALL,
    this.noCreditCard = false,
    this.searchQuery = '',
  });

  ServicesFilter copyWith({
    ServiceCategory? category,
    bool? noCreditCard,
    String? searchQuery,
  }) {
    return ServicesFilter(
      category: category ?? this.category,
      noCreditCard: noCreditCard ?? this.noCreditCard,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ServicesFilterNotifier extends StateNotifier<ServicesFilter> {
  ServicesFilterNotifier() : super(const ServicesFilter());

  void setCategory(ServiceCategory category) {
    state = state.copyWith(category: category);
  }

  void toggleNoCreditCard() {
    state = state.copyWith(noCreditCard: !state.noCreditCard);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final servicesFilterProvider = StateNotifierProvider<ServicesFilterNotifier, ServicesFilter>((ref) {
  return ServicesFilterNotifier();
});

// 3. Services Fetcher Provider
final servicesProvider = FutureProvider.autoDispose<PaginatedServices>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filter = ref.watch(servicesFilterProvider);
  final isOnline = ref.watch(connectivityProvider).value ?? true;
  
  return await apiService.fetchServices(
    category: filter.category,
    noCreditCard: filter.noCreditCard,
    searchQuery: filter.searchQuery,
    isOffline: false,
  );
});

// Category Stats Provider
final categoryStatsProvider = Provider<Map<ServiceCategory, int>>((ref) {
  final servicesState = ref.watch(servicesProvider);
  
  final Map<ServiceCategory, int> stats = {
    for (var cat in ServiceCategory.values) cat: 0
  };

  servicesState.whenData((data) {
    for (var item in data.items) {
      stats[item.category] = (stats[item.category] ?? 0) + 1;
      stats[ServiceCategory.ALL] = (stats[ServiceCategory.ALL] ?? 0) + 1;
    }
  });

  return stats;
});

// 4. Alerts Fetcher Provider
final alertsProvider = FutureProvider.autoDispose<List<DeprecationAlert>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final isOnline = ref.watch(connectivityProvider).value ?? true;
  return await apiService.fetchAlerts(isOffline: false);
});

// 5. Bookmarks Provider
class BookmarksNotifier extends StateNotifier<List<String>> {
  static const _prefsKey = 'bookmarked_services';
  
  BookmarksNotifier() : super([]) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_prefsKey) ?? [];
  }

  Future<void> toggleBookmark(String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    if (state.contains(serviceId)) {
      state = state.where((id) => id != serviceId).toList();
    } else {
      state = [...state, serviceId];
    }
    await prefs.setStringList(_prefsKey, state);
  }
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, List<String>>((ref) {
  return BookmarksNotifier();
});

// 6. Stack Builder Provider
class StackSelection {
  final ServiceItem? frontend;
  final ServiceItem? database;
  final ServiceItem? auth;

  const StackSelection({
    this.frontend,
    this.database,
    this.auth,
  });

  StackSelection copyWith({
    ServiceItem? frontend,
    ServiceItem? database,
    ServiceItem? auth,
  }) {
    return StackSelection(
      frontend: frontend ?? this.frontend,
      database: database ?? this.database,
      auth: auth ?? this.auth,
    );
  }
}

class StackBuilderNotifier extends StateNotifier<StackSelection> {
  StackBuilderNotifier() : super(const StackSelection());

  void setFrontend(ServiceItem service) {
    state = state.copyWith(frontend: service);
  }

  void setDatabase(ServiceItem service) {
    state = state.copyWith(database: service);
  }

  void setAuth(ServiceItem service) {
    state = state.copyWith(auth: service);
  }
  
  void clearStack() {
    state = const StackSelection();
  }
}

final stackBuilderProvider = StateNotifierProvider<StackBuilderNotifier, StackSelection>((ref) {
  return StackBuilderNotifier();
});
