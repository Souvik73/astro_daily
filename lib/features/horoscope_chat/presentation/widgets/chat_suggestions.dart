import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class ChatSuggestionRow extends StatelessWidget {
  const ChatSuggestionRow({required this.onTap, super.key});

  final void Function(String question) onTap;

  static const List<(String label, String question)> _suggestions =
      <(String, String)>[
    ('Ask about work', 'What does today look like for work?'),
    ('Ask about love', 'What does today look like for love?'),
    ('Lucky signs', 'Tell me about my lucky color and number today.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions
            .map(
              ((String, String) s) => ActionChip(
                label: Text(s.$1),
                onPressed: () => onTap(s.$2),
                side: const BorderSide(color: AppTheme.border),
                backgroundColor: Colors.white,
                labelStyle:
                    Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.ink,
                        ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ChatFollowUpRow extends StatelessWidget {
  const ChatFollowUpRow({
    required this.suggestions,
    required this.onTap,
    super.key,
  });

  final List<String> suggestions;
  final void Function(String question) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map(
              (String q) => ActionChip(
                label: Text(q),
                onPressed: () => onTap(q),
                side: const BorderSide(color: AppTheme.border),
                backgroundColor: Colors.white,
                labelStyle:
                    Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.ink,
                        ),
              ),
            )
            .toList(),
      ),
    );
  }
}
