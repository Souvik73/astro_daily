import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class ChatEmptyPrompt extends StatelessWidget {
  const ChatEmptyPrompt({required this.zodiacSign, super.key});

  final String zodiacSign;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ask your $zodiacSign companion',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "Ask anything about today's reading — work, love, lucky signs, and more.",
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
