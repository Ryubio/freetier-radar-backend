import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/services_provider.dart';

class SettingsState {
  final String apiBaseUrl;
  final String appTheme;

  SettingsState({
    required this.apiBaseUrl,
    required this.appTheme,
  });

  SettingsState copyWith({
    String? apiBaseUrl,
    String? appTheme,
  }) {
    return SettingsState(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      appTheme: appTheme ?? this.appTheme,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
            apiBaseUrl: 'https://api.freetier.example.com',
            appTheme: 'Catppuccin Mocha')) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('api_base_url') ?? 'https://api.freetier.example.com';
    final theme = prefs.getString('app_theme') ?? 'Catppuccin Mocha';
    state = state.copyWith(apiBaseUrl: url, appTheme: theme);
  }

  Future<void> updateApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
    state = state.copyWith(apiBaseUrl: url);
  }

  Future<void> updateAppTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme);
    state = state.copyWith(appTheme: theme);
  }

  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_base_url');
    await prefs.remove('app_theme');
    await prefs.remove('bookmarked_services');
    state = SettingsState(
        apiBaseUrl: 'https://api.freetier.example.com',
        appTheme: 'Catppuccin Mocha');
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isTestingConnection = false;
  bool? _connectionSuccess;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _urlController.text = settings.apiBaseUrl;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionSuccess = null;
    });

    // Mock testing connection delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Attempting a simple simulated check
    final success = _urlController.text.isNotEmpty && _urlController.text.startsWith('http');
    
    setState(() {
      _isTestingConnection = false;
      _connectionSuccess = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Server Configuration'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'https://...',
                    ),
                    onChanged: (val) =>
                        ref.read(settingsProvider.notifier).updateApiBaseUrl(val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isTestingConnection ? null : _testConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceColor,
                          foregroundColor: AppTheme.primaryBlue,
                        ),
                        child: _isTestingConnection
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Test Connection'),
                      ),
                      const SizedBox(width: 16),
                      if (_connectionSuccess != null)
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _connectionSuccess!
                                    ? AppTheme.secondaryGreen
                                    : AppTheme.errorRed,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _connectionSuccess! ? 'Connected' : 'Failed',
                              style: TextStyle(
                                color: _connectionSuccess!
                                    ? AppTheme.secondaryGreen
                                    : AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Appearance'),
          Card(
            child: Column(
              children: ['Catppuccin Mocha', 'Nord', 'Tokyo Night'].map((theme) {
                return RadioListTile<String>(
                  title: Text(theme),
                  value: theme,
                  groupValue: settings.appTheme,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).updateAppTheme(val);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data Management'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear All Bookmarks'),
                  onTap: () => _showClearBookmarksDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text('Clear Cache'),
                  subtitle: const Text('12.4 MB cached'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('App Version'),
                  trailing: Text('1.0.0', style: TextStyle(color: AppTheme.subtextColor)),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('View Source Code'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Report a Bug'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Danger Zone', color: AppTheme.errorRed),
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
              title: const Text('Reset All Settings', style: TextStyle(color: AppTheme.errorRed)),
              onTap: () => _showResetDialog(context),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = AppTheme.primaryBlue}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showClearBookmarksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface0Color,
        title: const Text('Clear Bookmarks?'),
        content: const Text('Are you sure you want to remove all bookmarked services? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.subtextColor)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('bookmarked_services');
              ref.invalidate(bookmarksProvider);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmarks cleared')),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface0Color,
        title: const Text('Reset Settings?'),
        content: const Text('This will reset all your preferences and clear local data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.subtextColor)),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetSettings();
              ref.invalidate(bookmarksProvider);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset')),
              );
            },
            child: const Text('Reset', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}
