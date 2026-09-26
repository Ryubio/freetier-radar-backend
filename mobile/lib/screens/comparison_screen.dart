import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/services_provider.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';

class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  ServiceCategory _selectedCategory = ServiceCategory.DATABASES;
  final List<ServiceItem> _selectedServices = [];

  void _toggleServiceSelection(ServiceItem service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else if (_selectedServices.length < 3) {
        _selectedServices.add(service);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only compare up to 3 services at once')),
        );
      }
    });
  }

  void _shareComparison() {
    if (_selectedServices.length < 2) return;

    final buffer = StringBuffer();
    buffer.writeln('# Free Tier Comparison: ${_selectedCategory.displayName}\n');

    for (final service in _selectedServices) {
      buffer.writeln('## ${service.name}');
      buffer.writeln('- **Limits:** ${service.freeTierLimits}');
      buffer.writeln('- **Credit Card Required:** ${service.requiresCreditCard ? "Yes" : "No"}');
      buffer.writeln('- **Hard Cap:** ${service.hasHardCap ? "Yes" : "No"}');
      buffer.writeln('- **Status:** ${service.status.displayName}');
      buffer.writeln('- **Link:** ${service.officialUrl}\n');
    }

    Share.share(buffer.toString(), subject: 'Free Tier Services Comparison');
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsyncValue = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Services'),
        actions: [
          if (_selectedServices.length >= 2)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareComparison,
              tooltip: 'Share Comparison',
            )
        ],
      ),
      body: servicesAsyncValue.when(
        data: (data) {
          // Filter out ALL category since comparison makes sense within the same type
          final validCategories = ServiceCategory.values
              .where((c) => c != ServiceCategory.ALL)
              .toList();

          final categoryServices = data.items
              .where((s) => s.category == _selectedCategory)
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<ServiceCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Select Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: validCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                        _selectedServices.clear();
                      });
                    }
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select 2-3 services to compare:',
                    style: TextStyle(
                      color: AppTheme.subtextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categoryServices.length,
                  itemBuilder: (context, index) {
                    final service = categoryServices[index];
                    final isSelected = _selectedServices.contains(service);
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                        label: Text(service.name),
                        selected: isSelected,
                        onSelected: (_) => _toggleServiceSelection(service),
                        backgroundColor: AppTheme.surface0Color,
                        selectedColor: AppTheme.primaryBlue.withOpacity(0.3),
                        checkmarkColor: AppTheme.primaryBlue,
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: AppTheme.surface0Color),
              Expanded(
                child: _selectedServices.length < 2
                    ? const Center(
                        child: Text(
                          'Select at least 2 services to view comparison',
                          style: TextStyle(color: AppTheme.subtextColor),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingTextStyle: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                            columns: [
                              const DataColumn(label: Text('Feature')),
                              ..._selectedServices.map(
                                (s) => DataColumn(label: Text(s.name)),
                              ),
                            ],
                            rows: [
                              DataRow(cells: [
                                const DataCell(Text('Free Tier Limits', style: TextStyle(fontWeight: FontWeight.bold))),
                                ..._selectedServices.map((s) => DataCell(Text(s.freeTierLimits))),
                              ]),
                              DataRow(cells: [
                                const DataCell(Text('Requires CC', style: TextStyle(fontWeight: FontWeight.bold))),
                                ..._selectedServices.map((s) => DataCell(
                                      Text(
                                        s.requiresCreditCard ? 'Yes' : 'No',
                                        style: TextStyle(
                                          color: s.requiresCreditCard ? AppTheme.errorRed : AppTheme.secondaryGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )),
                              ]),
                              DataRow(cells: [
                                const DataCell(Text('Hard Cap', style: TextStyle(fontWeight: FontWeight.bold))),
                                ..._selectedServices.map((s) => DataCell(
                                      Text(
                                        s.hasHardCap ? 'Yes' : 'No',
                                        style: TextStyle(
                                          color: s.hasHardCap ? AppTheme.secondaryGreen : AppTheme.warningPeach,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )),
                              ]),
                              DataRow(cells: [
                                const DataCell(Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                ..._selectedServices.map((s) => DataCell(Text(s.status.displayName))),
                              ]),
                              DataRow(cells: [
                                const DataCell(Text('Last Verified', style: TextStyle(fontWeight: FontWeight.bold))),
                                ..._selectedServices.map((s) => DataCell(
                                      Text('${s.lastVerifiedAt.year}-${s.lastVerifiedAt.month.toString().padLeft(2, '0')}-${s.lastVerifiedAt.day.toString().padLeft(2, '0')}'),
                                    )),
                              ]),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppTheme.errorRed)),
        ),
      ),
    );
  }
}
