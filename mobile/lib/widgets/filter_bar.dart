import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/services_provider.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(servicesFilterProvider);
    final filterNotifier = ref.read(servicesFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // No CC Required Toggle
          FilterChip(
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.credit_card_off, size: 16),
                SizedBox(width: 4),
                Text('No CC Required'),
              ],
            ),
            selected: filter.noCreditCard,
            onSelected: (_) => filterNotifier.toggleNoCreditCard(),
            selectedColor: AppTheme.secondaryGreen.withOpacity(0.2),
            labelStyle: TextStyle(
              color: filter.noCreditCard ? AppTheme.secondaryGreen : AppTheme.subtextColor,
            ),
          ),
          const SizedBox(width: 12),
          // Divider
          Container(
            height: 24,
            width: 1,
            color: const Color(0xFF45475A),
          ),
          const SizedBox(width: 12),
          // Categories
          ...ServiceCategory.values.map((category) {
            final isSelected = filter.category == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(category.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    filterNotifier.setCategory(category);
                  }
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
