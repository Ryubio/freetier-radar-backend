import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Note: assuming share_plus is available, if not, you may need to add it to pubspec.yaml
import 'package:share_plus/share_plus.dart';
import '../providers/services_provider.dart';
import '../models/service_model.dart';
import '../widgets/service_card.dart';
import '../theme/app_theme.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarksProvider);
    final servicesAsyncValue = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: () async {
          ref.invalidate(servicesProvider);
        },
        child: servicesAsyncValue.when(
          data: (data) {
            final bookmarkedServices = data.items
                .where((service) => bookmarkedIds.contains(service.id))
                .toList();

            if (bookmarkedServices.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border,
                              size: 64, color: AppTheme.subtextColor),
                          SizedBox(height: 16),
                          Text(
                            'No bookmarks yet',
                            style: TextStyle(
                                color: AppTheme.textColor, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Explore services and tap the bookmark icon to save them here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppTheme.subtextColor, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '${bookmarkedServices.length} saved service${bookmarkedServices.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.subtextColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final service = bookmarkedServices[index];
                      return Dismissible(
                        key: Key(service.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          color: AppTheme.errorRed,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          ref
                              .read(bookmarksProvider.notifier)
                              .toggleBookmark(service.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${service.name} removed'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  ref
                                      .read(bookmarksProvider.notifier)
                                      .toggleBookmark(service.id);
                                },
                              ),
                            ),
                          );
                        },
                        child: ServiceCard(service: service),
                      );
                    },
                    childCount: bookmarkedServices.length,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Error loading bookmarks',
              style: const TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          servicesAsyncValue.whenData((data) {
            final bookmarkedServices = data.items
                .where((service) => bookmarkedIds.contains(service.id))
                .toList();
            if (bookmarkedServices.isNotEmpty) {
              _exportAsMarkdown(context, bookmarkedServices);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No bookmarks to export')),
              );
            }
          });
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.download, color: AppTheme.mantleColor),
        label: const Text(
          'Export All as Markdown',
          style: TextStyle(color: AppTheme.mantleColor),
        ),
      ),
    );
  }

  void _exportAsMarkdown(BuildContext context, List<ServiceItem> services) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('# My Bookmarked Services\n');
    
    for (final service in services) {
      buffer.writeln('## ${service.name}');
      buffer.writeln('**Category:** ${service.category.displayName} | **Status:** ${service.status.displayName}');
      buffer.writeln('\n${service.shortDescription}\n');
      buffer.writeln('- **Free Tier Limits:** ${service.freeTierLimits}');
      buffer.writeln('- **Requires Credit Card:** ${service.requiresCreditCard ? "Yes" : "No"}');
      buffer.writeln('- **Hard Cap:** ${service.hasHardCap ? "Yes" : "No"}');
      buffer.writeln('- **Official URL:** ${service.officialUrl}');
      buffer.writeln('\n---\n');
    }

    Share.share(buffer.toString(), subject: 'My Bookmarked Free Tier Services');
  }
}
