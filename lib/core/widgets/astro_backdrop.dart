import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AstroBackdrop extends StatelessWidget {
  const AstroBackdrop({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppTheme.warmGradient,
            ),
          ),
        ),
        Positioned(
          top: -60,
          left: -60,
          child: _GlowOrb(
            size: 220,
            color: AppTheme.gold.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          top: 56,
          right: -36,
          child: _GlowOrb(
            size: 200,
            color: AppTheme.teal.withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          bottom: -80,
          left: 28,
          child: _GlowOrb(
            size: 180,
            color: AppTheme.coral.withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          top: 74,
          left: 30,
          child: _star(Icons.auto_awesome, AppTheme.gold, 18),
        ),
        Positioned(
          top: 130,
          right: 48,
          child: _star(Icons.auto_awesome, AppTheme.berry, 14),
        ),
        Positioned(
          top: 240,
          right: 110,
          child: _star(Icons.star_rounded, Colors.white, 10),
        ),
        child,
      ],
    );
  }

  Widget _star(IconData icon, Color color, double size) {
    return Icon(icon, color: color.withValues(alpha: 0.8), size: size);
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color,
            blurRadius: size * 0.32,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
