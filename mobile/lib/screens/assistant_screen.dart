import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/services_provider.dart';
import '../services/assistant_engine.dart';
import '../theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locale = ref.read(settingsProvider).locale;
      setState(() {
        _messages.add(ChatMessage(AppStrings.get('assistant_greeting', locale), false));
      });
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    _controller.clear();
    final locale = ref.read(settingsProvider).locale;

    setState(() {
      _messages.add(ChatMessage(text, true));
      _isTyping = true;
    });

    // Simulate thinking delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final response = AssistantEngine.analyzeAndRecommend(text, locale);

    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(response, false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsProvider).locale;

    return Scaffold(
      backgroundColor: AppTheme.colors.mantle,
      appBar: AppBar(
        title: Text(AppStrings.get('assistant', locale), style: TextStyle(color: AppTheme.colors.text)),
        backgroundColor: AppTheme.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.colors.text),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length && _isTyping) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(AppStrings.get('assistant_typing', locale), style: TextStyle(color: AppTheme.colors.subtext, fontStyle: FontStyle.italic)),
                    ),
                  );
                }

                final msg = _messages[i];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppTheme.colors.primary : AppTheme.colors.surface0,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                        bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? AppTheme.colors.surface : AppTheme.colors.text,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.colors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: AppTheme.colors.text),
                    decoration: InputDecoration(
                      hintText: AppStrings.get('assistant_hint', locale),
                      hintStyle: TextStyle(color: AppTheme.colors.subtext),
                      filled: true,
                      fillColor: AppTheme.colors.surface0,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: AppTheme.colors.primary,
                  child: IconButton(
                    icon: Icon(Icons.send, color: AppTheme.colors.surface),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
