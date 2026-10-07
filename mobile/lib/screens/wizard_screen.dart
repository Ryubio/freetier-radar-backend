import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';
import '../providers/services_provider.dart';
import '../theme/app_theme.dart';
import 'stack_calculator_screen.dart';

class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String? _projectType;
  String? _dbType;
  String? _hostingType;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _buildStack();
    }
  }

  void _buildStack() {
    // Basic AI Heuristic
    List<String> targetServices = [];
    
    if (_projectType == 'Mobile App') {
      targetServices.add('Firebase'); // usually good for mobile
    } else if (_projectType == 'AI App') {
      targetServices.add('Hugging Face');
      targetServices.add('OpenAI');
    }

    if (_dbType == 'Relational SQL') {
      targetServices.add('Supabase');
      targetServices.add('Neon');
    } else if (_dbType == 'NoSQL Document') {
      targetServices.add('MongoDB Atlas');
    } else if (_dbType == 'Key-Value') {
      targetServices.add('Upstash');
    }

    if (_hostingType == 'Static Frontend') {
      targetServices.add('Vercel');
      targetServices.add('Netlify');
    } else if (_hostingType == 'Docker Container') {
      targetServices.add('Render');
      targetServices.add('Fly.io');
    }

    // Attempt to find these in the cached services
    final allServices = ref.read(servicesProvider).value?.items ?? [];
    final selectedServices = allServices.where((s) => targetServices.any((ts) => s.name.toLowerCase().contains(ts.toLowerCase()))).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.colors.surface,
        title: Text('Your Perfect Stack', style: TextStyle(color: AppTheme.colors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Based on your needs, we found these free-tier gems:', style: TextStyle(color: AppTheme.colors.subtext)),
            const SizedBox(height: 16),
            ...selectedServices.map((s) => ListTile(
              leading: Icon(Icons.check_circle, color: AppTheme.colors.secondary),
              title: Text(s.name, style: TextStyle(color: AppTheme.colors.text)),
              subtitle: Text(s.category.name, style: TextStyle(color: AppTheme.colors.subtext, fontSize: 12)),
            ))
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppTheme.colors.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Awesome', style: TextStyle(color: AppTheme.colors.surface)),
          )
        ],
      )
    );
  }

  Widget _buildOption(String text, String? groupValue, ValueChanged<String?> onChanged) {
    bool isSelected = groupValue == text;
    return InkWell(
      onTap: () => onChanged(text),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.colors.primary.withOpacity(0.1) : AppTheme.colors.surface0,
          border: Border.all(
            color: isSelected ? AppTheme.colors.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? AppTheme.colors.primary : AppTheme.colors.subtext),
            const SizedBox(width: 12),
            Text(text, style: TextStyle(color: isSelected ? AppTheme.colors.primary : AppTheme.colors.text, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.surface,
      appBar: AppBar(
        title: Text('Find My Stack', style: TextStyle(color: AppTheme.colors.text)),
        backgroundColor: AppTheme.colors.mantle,
        iconTheme: IconThemeData(color: AppTheme.colors.text),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: AppTheme.colors.surface0,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colors.primary),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  // Page 1
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What are you building?', style: TextStyle(color: AppTheme.colors.text, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('We will recommend the best free-tier tools for your use case.', style: TextStyle(color: AppTheme.colors.subtext)),
                        const SizedBox(height: 32),
                        _buildOption('Web App (SaaS, Blog)', _projectType, (v) => setState(() => _projectType = v)),
                        _buildOption('Mobile App', _projectType, (v) => setState(() => _projectType = v)),
                        _buildOption('AI / Machine Learning', _projectType, (v) => setState(() => _projectType = v)),
                        _buildOption('API / Microservice', _projectType, (v) => setState(() => _projectType = v)),
                      ],
                    ),
                  ),
                  // Page 2
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What kind of database do you need?', style: TextStyle(color: AppTheme.colors.text, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        _buildOption('Relational SQL (Postgres, MySQL)', _dbType, (v) => setState(() => _dbType = v)),
                        _buildOption('NoSQL Document (Mongo, Firebase)', _dbType, (v) => setState(() => _dbType = v)),
                        _buildOption('Key-Value (Redis)', _dbType, (v) => setState(() => _dbType = v)),
                        _buildOption('No Database Needed', _dbType, (v) => setState(() => _dbType = v)),
                      ],
                    ),
                  ),
                  // Page 3
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How do you plan to host it?', style: TextStyle(color: AppTheme.colors.text, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        _buildOption('Static Frontend (React, Vue, Flutter)', _hostingType, (v) => setState(() => _hostingType = v)),
                        _buildOption('Serverless Functions', _hostingType, (v) => setState(() => _hostingType = v)),
                        _buildOption('Docker Container', _hostingType, (v) => setState(() => _hostingType = v)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_currentPage == 0 && _projectType == null) return;
                    if (_currentPage == 1 && _dbType == null) return;
                    if (_currentPage == 2 && _hostingType == null) return;
                    _nextPage();
                  },
                  child: Text(
                    _currentPage == 2 ? 'Generate Stack' : 'Next',
                    style: TextStyle(color: AppTheme.colors.surface, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
