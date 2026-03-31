import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AstroPageHeader extends StatelessWidget {
  const AstroPageHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (onBack != null) ...<Widget>[
          AstroTopIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: onBack == null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                title,
                textAlign: onBack == null ? TextAlign.start : TextAlign.center,
                style: textTheme.titleLarge,
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: onBack == null
                      ? TextAlign.start
                      : TextAlign.center,
                  style: textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 12),
          trailing!,
        ] else if (onBack != null) ...<Widget>[
          const SizedBox(width: 54),
        ],
      ],
    );
  }
}

class AstroTopIconButton extends StatelessWidget {
  const AstroTopIconButton({
    required this.icon,
    this.onTap,
    this.foregroundColor,
    this.backgroundColor,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: foregroundColor ?? AppTheme.ink,
        ),
      ),
    );
  }
}

class AstroHeroSurface extends StatelessWidget {
  const AstroHeroSurface({
    required this.child,
    this.gradient = AppTheme.heroGradient,
    this.padding = const EdgeInsets.all(22),
    super.key,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AstroSectionHeader extends StatelessWidget {
  const AstroSectionHeader({
    required this.title,
    this.action,
    super.key,
  });

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: textTheme.titleLarge)),
        if (action != null) ...<Widget>[
          const SizedBox(width: 8),
          Text(
            action!,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.berry),
          ),
        ],
      ],
    );
  }
}

class AstroInfoTile extends StatelessWidget {
  const AstroInfoTile({
    required this.icon,
    required this.title,
    required this.body,
    this.accent = AppTheme.teal,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class AstroMetricCard extends StatelessWidget {
  const AstroMetricCard({
    required this.label,
    required this.value,
    this.accent = AppTheme.gold,
    super.key,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.inkSoft),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class AstroLoadingView extends StatelessWidget {
  const AstroLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class AstroErrorView extends StatelessWidget {
  const AstroErrorView({
    required this.message,
    required this.onRetry,
    this.ctaLabel = 'Retry',
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton(onPressed: onRetry, child: Text(ctaLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
