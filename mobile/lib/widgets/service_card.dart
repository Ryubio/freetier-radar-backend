/// Polished service card widget for the explore feed.
///
/// Displays service name, category badge, free tier limits in code style,
/// status indicators, bookmark toggle, and a direct-link button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';
import '../providers/services_provider.dart';
import 'service_detail_modal.dart';

class ServiceCard extends ConsumerWidget {
  final ServiceItem service;

  const ServiceCard({super.key, required this.service});

  void _openServiceDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceDetailModal(service: service),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarkedIds.contains(service.id);

    return Card(
      child: InkWell(
        onTap: () => _openServiceDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category badge + Bookmark
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryBadge(),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                          ? AppTheme.primaryBlue
                          : AppTheme.subtextColor,
                    ),
                    onPressed: () {
                      ref
                          .read(bookmarksProvider.notifier)
                          .toggleBookmark(service.id);
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Service name
              Text(
                service.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 4),

              // Short description (2 lines max)
              Text(
                service.shortDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.subtextColor,
                ),
              ),
              const SizedBox(height: 12),

              // Free tier limits in code-style box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.mantleColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF45475A)),
                ),
                child: Text(
                  service.freeTierLimits,
                  style: AppTheme.codeStyle,
                ),
              ),
              const SizedBox(height: 12),

              // Indicator chips + Open button
              Row(
                children: [
                  if (!service.requiresCreditCard)
                    _buildIndicatorChip('No CC', AppTheme.secondaryGreen),
                  if (service.hasHardCap)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildIndicatorChip(
                          'Hard Cap', AppTheme.primaryBlue),
                    ),
                  if (service.status == ServiceStatus.CHANGED_RECENTLY)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildIndicatorChip(
                          'Updated', AppTheme.warningPeach),
                    ),
                  if (service.status == ServiceStatus.DEPRECATED)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildIndicatorChip(
                          'Deprecated', AppTheme.errorRed),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(service.officialUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(service.category.icon, size: 14, color: AppTheme.primaryBlue),
          const SizedBox(width: 4),
          Text(
            service.category.displayName,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
