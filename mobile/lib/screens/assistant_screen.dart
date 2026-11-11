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
      backgroundColor: AppTheme.mantleColor,
      appBar: AppBar(
        title: Text(AppStrings.get('assistant', locale), style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textColor),
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
                      child: Text(AppStrings.get('assistant_typing', locale), style: TextStyle(color: AppTheme.subtextColor, fontStyle: FontStyle.italic)),
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
                      color: msg.isUser ? AppTheme.primaryBlue : AppTheme.surface0Color,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                        bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? AppTheme.surfaceColor : AppTheme.textColor,
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
            color: AppTheme.surfaceColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: AppTheme.textColor),
                    decoration: InputDecoration(
                      hintText: AppStrings.get('assistant_hint', locale),
                      hintStyle: TextStyle(color: AppTheme.subtextColor),
                      filled: true,
                      fillColor: AppTheme.surface0Color,
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
                  backgroundColor: AppTheme.primaryBlue,
                  child: IconButton(
                    icon: Icon(Icons.send, color: AppTheme.surfaceColor),
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
