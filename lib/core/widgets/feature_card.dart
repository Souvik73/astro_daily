import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.usageLabel,
    required this.onTap,
    this.isLocked = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String usageLabel;
  final VoidCallback onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color accent = isLocked ? AppTheme.coral : AppTheme.teal;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(title, style: textTheme.titleMedium),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            usageLabel,
                            style: textTheme.labelMedium?.copyWith(
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Text(
                          isLocked ? 'Upgrade or unlock' : 'Open module',
                          style: textTheme.bodySmall?.copyWith(
                            color: isLocked ? AppTheme.coral : AppTheme.berry,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isLocked
                              ? Icons.lock_outline_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                          color: isLocked ? AppTheme.coral : AppTheme.ink,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
