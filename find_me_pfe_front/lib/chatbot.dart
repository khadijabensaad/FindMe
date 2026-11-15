import 'package:find_me/ui/stylist/stylist_screen.dart';
import 'package:flutter/material.dart';

/// Kept for backward compatibility: every link to ChatbotPage now opens the AI Fashion Stylist.
class ChatbotPage extends StatelessWidget {
  final String? initialPrompt;
  const ChatbotPage({super.key, this.initialPrompt});

  @override
  Widget build(BuildContext context) => StylistScreen(initialPrompt: initialPrompt);
}
