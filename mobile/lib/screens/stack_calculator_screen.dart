/// Indie Stack Calculator screen.
///
/// Users pick a Frontend Host, Database, and Auth Provider to build
/// a fully-free tech stack. Displays combined warnings, export as
/// markdown, and bookmark functionality.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/services_provider.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';

class StackCalculatorScreen extends ConsumerWidget {
  const StackCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stack = ref.watch(stackBuilderProvider);
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indie Stack Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Clear Stack',
            onPressed: () =>
                ref.read(stackBuilderProvider.notifier).clearStack(),
          ),
        ],
      ),
      body: servicesAsync.when(
        data: (data) {
          final hostingServices = data.items
              .where((s) => s.category == ServiceCategory.HOSTING_PAAS)
              .toList();
          final dbServices = data.items
              .where((s) => s.category == ServiceCategory.DATABASES)
              .toList();
          final authServices = data.items
              .where((s) => s.category == ServiceCategory.AUTH_SECURITY)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header
              const Text(
                'Build your fully free tech stack',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick one service per layer, and we\'ll flag any caveats.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.subtextColor,
                ),
              ),
              const SizedBox(height: 24),

              // Frontend Host
              _buildSection(
                title: '☁️ Frontend Host',
                icon: Icons.cloud,
                items: hostingServices,
                selectedItem: stack.frontend,
                onChanged: (val) => val != null
                    ? ref
                        .read(stackBuilderProvider.notifier)
                        .setFrontend(val)
                    : null,
              ),
              const SizedBox(height: 20),

              // Database
              _buildSection(
                title: '🗄️ Database',
                icon: Icons.storage,
                items: dbServices,
                selectedItem: stack.database,
                onChanged: (val) => val != null
                    ? ref
                        .read(stackBuilderProvider.notifier)
                        .setDatabase(val)
                    : null,
              ),
              const SizedBox(height: 20),

              // Auth Provider
              _buildSection(
                title: '🔐 Auth Provider',
                icon: Icons.lock,
                items: authServices,
                selectedItem: stack.auth,
                onChanged: (val) => val != null
                    ? ref.read(stackBuilderProvider.notifier).setAuth(val)
                    : null,
              ),
              const SizedBox(height: 32),

              // Summary card (shows only when at least one service selected)
              if (stack.frontend != null ||
                  stack.database != null ||
                  stack.auth != null)
                _buildSummaryCard(context, ref, stack),

              const SizedBox(height: 32),
            ],
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
              Text('Error loading services: $e',
                  style: const TextStyle(color: AppTheme.errorRed)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(servicesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<ServiceItem> items,
    required ServiceItem? selectedItem,
    required ValueChanged<ServiceItem?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ServiceItem>(
          value: selectedItem,
          decoration: const InputDecoration(hintText: 'Select a service'),
          isExpanded: true,
          dropdownColor: AppTheme.surface0Color,
          items: items.map((service) {
            return DropdownMenuItem(
              value: service,
              child: Row(
                children: [
                  Expanded(child: Text(service.name)),
                  if (!service.requiresCreditCard)
                    const Icon(Icons.credit_card_off,
                        size: 14, color: AppTheme.secondaryGreen),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        // Mini summary for selected service
        if (selectedItem != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.mantleColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF45475A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedItem.freeTierLimits,
                  style: AppTheme.codeStyle,
                ),
                if (selectedItem.requiresCreditCard)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      '⚠️ Requires credit card',
                      style: TextStyle(
                          color: AppTheme.warningPeach, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, WidgetRef ref, StackSelection stack) {
    final selectedServices = [stack.frontend, stack.database, stack.auth]
        .where((s) => s != null)
        .cast<ServiceItem>()
        .toList();

    final needsCreditCard =
        selectedServices.any((s) => s.requiresCreditCard);
    final hasChangedRecently =
        selectedServices.any((s) => s.status == ServiceStatus.CHANGED_RECENTLY);
    final hasDeprecated =
        selectedServices.any((s) => s.status == ServiceStatus.DEPRECATED);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stack Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const Divider(color: Color(0xFF45475A), height: 24),

            // Combined limits
            ...selectedServices.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s.name}: ',
                          style: const TextStyle(
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Expanded(
                        child: Text(s.freeTierLimits,
                            style: AppTheme.codeStyle),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 12),

            // Verdict
            if (needsCreditCard)
              const _VerdictRow(
                icon: Icons.credit_card,
                color: AppTheme.warningPeach,
                text: '⚠️ Requires Credit Card',
              )
            else
              const _VerdictRow(
                icon: Icons.check_circle,
                color: AppTheme.secondaryGreen,
                text: '✅ Fully Free Stack — no credit card needed!',
              ),

            if (hasChangedRecently)
              const _VerdictRow(
                icon: Icons.update,
                color: AppTheme.warningPeach,
                text: '⚠️ Some services updated recently — review terms',
              ),

            if (hasDeprecated)
              const _VerdictRow(
                icon: Icons.cancel,
                color: AppTheme.errorRed,
                text: '🚨 Includes deprecated services — find alternatives',
              ),

            const SizedBox(height: 20),

            // Export as Markdown
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportMarkdown(stack),
                icon: const Icon(Icons.description),
                label: const Text('Export as Markdown'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.mantleColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Save Stack
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _saveStack(ref, stack, context),
                icon: const Icon(Icons.bookmark),
                label: const Text('Save Stack to Bookmarks'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportMarkdown(StackSelection stack) {
    final buffer = StringBuffer();
    buffer.writeln('# 🚀 My Free Tier Tech Stack\n');
    buffer.writeln('*Generated by FreeTier Radar*\n');

    if (stack.frontend != null) {
      buffer.writeln('## ☁️ Frontend: ${stack.frontend!.name}');
      buffer.writeln('- **URL**: ${stack.frontend!.officialUrl}');
      buffer.writeln('- **Free Tier**: `${stack.frontend!.freeTierLimits}`');
      buffer.writeln(
          '- **Credit Card**: ${stack.frontend!.requiresCreditCard ? "Required" : "Not required"}\n');
    }
    if (stack.database != null) {
      buffer.writeln('## 🗄️ Database: ${stack.database!.name}');
      buffer.writeln('- **URL**: ${stack.database!.officialUrl}');
      buffer.writeln('- **Free Tier**: `${stack.database!.freeTierLimits}`');
      buffer.writeln(
          '- **Credit Card**: ${stack.database!.requiresCreditCard ? "Required" : "Not required"}\n');
    }
    if (stack.auth != null) {
      buffer.writeln('## 🔐 Auth: ${stack.auth!.name}');
      buffer.writeln('- **URL**: ${stack.auth!.officialUrl}');
      buffer.writeln('- **Free Tier**: `${stack.auth!.freeTierLimits}`');
      buffer.writeln(
          '- **Credit Card**: ${stack.auth!.requiresCreditCard ? "Required" : "Not required"}\n');
    }

    Share.share(buffer.toString());
  }

  void _saveStack(
      WidgetRef ref, StackSelection stack, BuildContext context) {
    final notifier = ref.read(bookmarksProvider.notifier);
    final ids = <String>[];
    if (stack.frontend != null) ids.add(stack.frontend!.id);
    if (stack.database != null) ids.add(stack.database!.id);
    if (stack.auth != null) ids.add(stack.auth!.id);

    for (final id in ids) {
      notifier.toggleBookmark(id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ids.length} services saved to bookmarks!'),
        backgroundColor: AppTheme.secondaryGreen,
      ),
    );
  }
}

/// Small helper widget for verdict rows in the summary card.
class _VerdictRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _VerdictRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
