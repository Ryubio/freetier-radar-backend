/// Home / Explore screen — the main feed of free-tier services.
///
/// Features:
/// - Debounced search bar
/// - "Radar of the Week" banner for recently changed/new services
/// - Category filter chips + No CC toggle
/// - Pull-to-refresh
/// - Loading shimmer, empty state, error state with retry

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers/services_provider.dart';
import '../models/service_model.dart';
import '../widgets/service_card.dart';
import '../widgets/filter_bar.dart';
import '../theme/app_theme.dart';
import 'wizard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(servicesFilterProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsyncValue = ref.watch(servicesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WizardScreen())),
        icon: Icon(Icons.auto_awesome, color: AppTheme.colors.surface),
        label: Text("Find My Stack", style: TextStyle(color: AppTheme.colors.surface, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.colors.primary,
      ),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(width: 8),
            const Text('FreeTier Radar'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(servicesFilterProvider.notifier)
                              .setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const FilterBar(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryBlue,
              onRefresh: () async {
                ref.invalidate(servicesProvider);
              },
              child: servicesAsyncValue.when(
                data: (data) {
                  if (data.items.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildServiceList(data);
                },
                loading: () => _buildLoadingState(),
                error: (err, stack) => _buildErrorState(err),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarBanner(List<ServiceItem> items) {
    // Pick the newest or most recently changed service
    final spotlight = items.firstWhere(
      (s) => s.status == ServiceStatus.CHANGED_RECENTLY,
      orElse: () => items.first,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.15),
            AppTheme.secondaryGreen.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Radar of the Week',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            spotlight.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            spotlight.shortDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spotlight.freeTierLimits,
            style: AppTheme.codeStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(PaginatedServices data) {
    return CustomScrollView(
      slivers: [
        // Radar of the Week banner
        SliverToBoxAdapter(
          child: _buildRadarBanner(data.items),
        ),
        // Service count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '${data.total} services found',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.subtextColor.withOpacity(0.6),
              ),
            ),
          ),
        ),
        // Service cards
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24, top: 4),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ServiceCard(service: data.items[index]);
              },
              childCount: data.items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.surface0Color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 200,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.surface0Color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.surface0Color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.mantleColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off,
                    size: 64, color: AppTheme.subtextColor),
                SizedBox(height: 16),
                Text(
                  'No services found matching filters',
                  style: TextStyle(
                      color: AppTheme.subtextColor, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your search or category filters',
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

  Widget _buildErrorState(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off,
              color: AppTheme.errorRed, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Could not connect to server',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$err',
            style: const TextStyle(
                color: AppTheme.subtextColor, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(servicesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.mantleColor,
            ),
          ),
        ],
      ),
    );
  }
}
