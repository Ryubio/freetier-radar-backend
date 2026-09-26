/// Deprecation Alerts timeline screen.
/// Shows visual diffs for old vs new limits.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/services_provider.dart';
import '../theme/app_theme.dart';
import '../utils/extensions.dart'; // For relative time format

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deprecation Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.invalidate(alertsProvider),
            tooltip: 'Check for updates',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(alertsProvider),
        child: alertsAsync.when(
          data: (alerts) {
            if (alerts.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: AppTheme.secondaryGreen),
                          SizedBox(height: 16),
                          Text(
                            'All clear! No recent changes detected.',
                            style: TextStyle(
                                color: AppTheme.subtextColor, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'We scan for pricing changes every 12 hours.',
                            style: TextStyle(
                                color: AppTheme.subtextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final isDowngrade = alert.alertType == 'TIER_DOWNGRADE';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline dot
                      Column(
                        children: [
                          _buildAlertIcon(alert.alertType),
                          if (index < alerts.length - 1)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 2,
                              height: 100, // Fixed height for connecting line
                              color: const Color(0xFF45475A),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Alert content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  alert.serviceName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                Text(
                                  alert.detectedAt.toRelativeTime(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.subtextColor.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _alertTypeLabel(alert.alertType),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _alertColor(alert.alertType),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.summary,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textColor,
                              ),
                            ),
                            // Advanced Limit Diff Display
                            if (alert.oldLimit != null && alert.newLimit != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.mantleColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF45475A)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.remove_circle_outline, size: 16, color: AppTheme.errorRed),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            alert.oldLimit!,
                                            style: AppTheme.codeStyle.copyWith(
                                              decoration: TextDecoration.lineThrough,
                                              color: AppTheme.subtextColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                      child: Icon(Icons.arrow_downward, size: 12, color: AppTheme.subtextColor),
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.add_circle_outline, size: 16, color: isDowngrade ? AppTheme.warningPeach : AppTheme.secondaryGreen),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            alert.newLimit!,
                                            style: AppTheme.codeStyle.copyWith(
                                              color: isDowngrade ? AppTheme.warningPeach : AppTheme.secondaryGreen,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppTheme.errorRed, size: 48),
                const SizedBox(height: 16),
                const Text('Error loading alerts',
                    style: TextStyle(color: AppTheme.errorRed)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(alertsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertIcon(String type) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _alertColor(type).withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: _alertColor(type).withOpacity(0.5)),
      ),
      child: Icon(_alertIconData(type), color: _alertColor(type), size: 20),
    );
  }

  Color _alertColor(String type) {
    switch (type) {
      case 'TIER_DOWNGRADE': return AppTheme.errorRed;
      case 'TIER_UPGRADE': return AppTheme.secondaryGreen;
      case 'POLICY_CHANGE':
      default: return AppTheme.warningPeach;
    }
  }

  IconData _alertIconData(String type) {
    switch (type) {
      case 'TIER_DOWNGRADE': return Icons.trending_down;
      case 'TIER_UPGRADE': return Icons.trending_up;
      case 'POLICY_CHANGE':
      default: return Icons.sync;
    }
  }

  String _alertTypeLabel(String type) {
    switch (type) {
      case 'TIER_DOWNGRADE': return '⚠️ Tier Downgrade';
      case 'TIER_UPGRADE': return '✅ Tier Upgrade';
      case 'POLICY_CHANGE':
      default: return '🔄 Policy Change';
    }
  }
}
