/// Draggable bottom sheet modal showing full service details.
///
/// Displays complete free tier information, change log, action buttons
/// (visit site, copy link, bookmark, share).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';
import '../providers/services_provider.dart';

class ServiceDetailModal extends ConsumerWidget {
  final ServiceItem service;

  const ServiceDetailModal({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarkedIds.contains(service.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.subtextColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    // Category badge + Verified date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(service.category.icon,
                                  size: 14, color: AppTheme.primaryBlue),
                              const SizedBox(width: 4),
                              Text(
                                service.category.displayName,
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Verified: ${service.lastVerifiedAt.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                            color: AppTheme.subtextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Service name
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full description
                    Text(
                      service.shortDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.subtextColor,
                        height: 1.5,
                      ),
                    ),

                    // Status badge
                    if (service.status != ServiceStatus.ACTIVE)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (service.status == ServiceStatus.DEPRECATED
                                  ? AppTheme.errorRed
                                  : AppTheme.warningPeach)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (service.status == ServiceStatus.DEPRECATED
                                    ? AppTheme.errorRed
                                    : AppTheme.warningPeach)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              service.status == ServiceStatus.DEPRECATED
                                  ? Icons.cancel_outlined
                                  : Icons.info_outline,
                              color: service.status == ServiceStatus.DEPRECATED
                                  ? AppTheme.errorRed
                                  : AppTheme.warningPeach,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Status: ${service.status.displayName}',
                                style: TextStyle(
                                  color:
                                      service.status == ServiceStatus.DEPRECATED
                                          ? AppTheme.errorRed
                                          : AppTheme.warningPeach,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Credit card warning
                    if (service.requiresCreditCard)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.errorRed.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.credit_card,
                                color: AppTheme.errorRed),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Requires a credit card to activate the free tier.',
                                style: TextStyle(color: AppTheme.errorRed),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Change log
                    if (service.changeLogSummary != null &&
                        service.changeLogSummary!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningPeach.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.warningPeach.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.history,
                                    color: AppTheme.warningPeach, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Recent Change',
                                  style: TextStyle(
                                    color: AppTheme.warningPeach,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              service.changeLogSummary!,
                              style: TextStyle(
                                color:
                                    AppTheme.warningPeach.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Free Tier Limits section
                    const Text(
                      'Free Tier Limits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.mantleColor,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFF45475A)),
                      ),
                      child: Text(
                        service.freeTierLimits,
                        style: AppTheme.codeStyle.copyWith(fontSize: 14),
                      ),
                    ),

                    // Hard cap indicator
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            service.hasHardCap
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            size: 16,
                            color: service.hasHardCap
                                ? AppTheme.secondaryGreen
                                : AppTheme.warningPeach,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            service.hasHardCap
                                ? 'Hard cap — stops at limit (no surprise bills)'
                                : 'Soft cap — may incur overage charges',
                            style: TextStyle(
                              fontSize: 12,
                              color: service.hasHardCap
                                  ? AppTheme.secondaryGreen
                                  : AppTheme.warningPeach,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(service.officialUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.public),
                          label: const Text('Visit Site'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: AppTheme.mantleColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: service.officialUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Link copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Link'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            ref
                                .read(bookmarksProvider.notifier)
                                .toggleBookmark(service.id);
                          },
                          icon: Icon(isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border),
                          label: Text(
                              isBookmarked ? 'Saved' : 'Bookmark'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Share.share(
                              'Check out the free tier for ${service.name}: '
                              '${service.officialUrl}',
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
