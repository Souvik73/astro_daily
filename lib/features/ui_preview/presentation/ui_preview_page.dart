import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UiPreviewPage extends StatelessWidget {
  const UiPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PreviewPalette.canvas,
      body: Stack(
        children: <Widget>[
          const _AtmosphereLayer(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Astro Daily UI Direction',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 52,
                          height: 0.98,
                          fontWeight: FontWeight.w700,
                          color: _PreviewPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mystic vibrant, hero-led, and significantly calmer than the current card-heavy app. This preview shows the first four redesigned surfaces before the full rollout.',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          height: 1.55,
                          color: _PreviewPalette.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _StyleStrip(),
                      const SizedBox(height: 30),
                      LayoutBuilder(
                        builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                        ) {
                          final double width = constraints.maxWidth;
                          final double frameWidth = width >= 1400
                              ? 330
                              : width >= 1100
                              ? 300
                              : width >= 720
                              ? 320
                              : math.min(width, 360);

                          return Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: <Widget>[
                              _PreviewPhoneFrame(
                                width: frameWidth,
                                label: 'Login',
                                child: const _LoginPreview(),
                              ),
                              _PreviewPhoneFrame(
                                width: frameWidth,
                                label: 'Home',
                                child: const _HomePreview(),
                              ),
                              _PreviewPhoneFrame(
                                width: frameWidth,
                                label: 'Daily Horoscope',
                                child: const _DailyPreview(),
                              ),
                              _PreviewPhoneFrame(
                                width: frameWidth,
                                label: 'Subscription',
                                child: const _SubscriptionPreview(),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPalette {
  static const Color canvas = Color(0xFFF7EFE3);
  static const Color ink = Color(0xFF1D1B2A);
  static const Color inkSoft = Color(0xFF5F5C70);
  static const Color border = Color(0xFFE0D3C1);
  static const Color teal = Color(0xFF0C6E6A);
  static const Color gold = Color(0xFFE7A43B);
  static const Color coral = Color(0xFFC86A5C);
  static const Color berry = Color(0xFF9F4A66);
  static const Color cream = Color(0xFFFFFBF5);
  static const Color midnight = Color(0xFF20233D);
  static const Color premium = Color(0xFF3A3048);
}

class _AtmosphereLayer extends StatelessWidget {
  const _AtmosphereLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -100,
            left: -60,
            child: _blurOrb(
              size: 280,
              color: _PreviewPalette.gold.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 80,
            right: -40,
            child: _blurOrb(
              size: 260,
              color: _PreviewPalette.teal.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: -90,
            left: 120,
            child: _blurOrb(
              size: 340,
              color: _PreviewPalette.coral.withValues(alpha: 0.18),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _StarfieldPainter()),
          ),
        ],
      ),
    );
  }

  Widget _blurOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: <BoxShadow>[
          BoxShadow(color: color, blurRadius: size * 0.35, spreadRadius: 20),
        ],
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.46);
    const List<Offset> seeds = <Offset>[
      Offset(0.08, 0.12),
      Offset(0.19, 0.28),
      Offset(0.32, 0.08),
      Offset(0.44, 0.18),
      Offset(0.61, 0.12),
      Offset(0.72, 0.24),
      Offset(0.87, 0.1),
      Offset(0.12, 0.62),
      Offset(0.28, 0.78),
      Offset(0.51, 0.68),
      Offset(0.64, 0.84),
      Offset(0.82, 0.72),
      Offset(0.92, 0.58),
    ];

    for (int i = 0; i < seeds.length; i++) {
      final Offset seed = seeds[i];
      canvas.drawCircle(
        Offset(seed.dx * size.width, seed.dy * size.height),
        i.isEven ? 1.6 : 1.1,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StyleStrip extends StatelessWidget {
  const _StyleStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _PreviewPalette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _PreviewPalette.midnight.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const _StyleBadge(
            icon: Icons.auto_awesome_rounded,
            label: 'Mystic Vibrant',
          ),
          const _StyleBadge(
            icon: Icons.wb_sunny_outlined,
            label: 'Hero-Led Calm',
          ),
          const _StyleBadge(
            icon: Icons.workspace_premium_outlined,
            label: 'Ad-Supported Freemium',
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              _Swatch(_PreviewPalette.midnight),
              _Swatch(_PreviewPalette.teal),
              _Swatch(_PreviewPalette.gold),
              _Swatch(_PreviewPalette.coral),
              _Swatch(_PreviewPalette.berry),
              _Swatch(_PreviewPalette.cream),
            ],
          ),
        ],
      ),
    );
  }
}

class _StyleBadge extends StatelessWidget {
  const _StyleBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _PreviewPalette.cream,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _PreviewPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: _PreviewPalette.berry),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _PreviewPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white),
      ),
    );
  }
}

class _PreviewPhoneFrame extends StatelessWidget {
  const _PreviewPhoneFrame({
    required this.width,
    required this.label,
    required this.child,
  });

  final double width;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 14, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
              color: _PreviewPalette.inkSoft,
            ),
          ),
        ),
        Container(
          width: width,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10131C),
            borderRadius: BorderRadius.circular(34),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _PreviewPalette.midnight.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              height: width * 2.08,
              color: _PreviewPalette.cream,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginPreview extends StatelessWidget {
  const _LoginPreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFF1F2A49),
                Color(0xFF7D5066),
                Color(0xFFF3BB75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          left: -40,
          top: 50,
          child: _planet(170, const Color(0x33FFFFFF)),
        ),
        Positioned(
          right: 18,
          top: 86,
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white.withValues(alpha: 0.9),
            size: 22,
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Astro Daily',
                style: GoogleFonts.manrope(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Align with today’s\ncosmic rhythm',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 42,
                  height: 0.92,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'A more premium, atmospheric login with social-first entry and softer trust cues.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _MiniChip('Daily guidance'),
                  _MiniChip('Ad-light free tier'),
                  _MiniChip('Personalized profile'),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: const BoxDecoration(
              color: _PreviewPalette.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const <Widget>[
                _Handle(),
                SizedBox(height: 18),
                _SocialButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Continue with Google',
                  fill: Colors.white,
                  foreground: _PreviewPalette.ink,
                ),
                SizedBox(height: 10),
                _SocialButton(
                  icon: Icons.apple,
                  label: 'Continue with Apple',
                  fill: Color(0xFF201E27),
                  foreground: Colors.white,
                ),
                SizedBox(height: 18),
                _DividerLabel('or use email'),
                SizedBox(height: 16),
                _InputMock(label: 'Email'),
                SizedBox(height: 10),
                _InputMock(label: 'Password'),
                SizedBox(height: 16),
                _ActionButton(
                  label: 'Sign in',
                  fill: LinearGradient(
                    colors: <Color>[
                      _PreviewPalette.coral,
                      _PreviewPalette.gold,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _planet(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _HomePreview extends StatelessWidget {
  const _HomePreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFF1E2440),
                Color(0xFF815368),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const Spacer(),
                  const _HeaderIcon(Icons.search_rounded),
                  const SizedBox(width: 10),
                  const _HeaderIcon(Icons.person_outline_rounded),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Good morning,\nSouvik',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 38,
                  height: 0.95,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Scorpio energy is best used on one confident move, not five scattered ones.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.84),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _Eyebrow('TODAY FOR SCORPIO'),
                          SizedBox(height: 6),
                          _HeroCopy('Strong intuition,\nsteady momentum'),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Open',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                _SectionHeading(
                  title: 'Your cosmic tools',
                  action: 'See all',
                ),
                SizedBox(height: 14),
                _ModuleCard(
                  title: 'Horoscope Companion',
                  subtitle: '3 free questions left today',
                  accent: _PreviewPalette.teal,
                  icon: Icons.chat_bubble_outline_rounded,
                  badge: 'Reward +3',
                ),
                SizedBox(height: 12),
                _ModuleCard(
                  title: 'Kundli',
                  subtitle: 'Your chart is ready to reopen anytime',
                  accent: _PreviewPalette.coral,
                  icon: Icons.auto_graph_rounded,
                  badge: '1 refresh/week',
                ),
                SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _SmallModuleCard(
                        title: 'Matching',
                        badge: '1 free',
                        accent: _PreviewPalette.berry,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SmallModuleCard(
                        title: 'Numerology',
                        badge: 'Reward +1',
                        accent: _PreviewPalette.gold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                _SectionHeading(
                  title: 'Free plan, softened',
                  action: 'Upgrade',
                ),
                SizedBox(height: 12),
                _InlinePremiumCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyPreview extends StatelessWidget {
  const _DailyPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color(0xFFFFFBF6),
            Color(0xFFF8EEE3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const _HeaderIcon(Icons.arrow_back_ios_new_rounded, dark: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daily Horoscope',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _PreviewPalette.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const _HeaderIcon(Icons.favorite_border_rounded, dark: true),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF252C4A),
                    Color(0xFF96536A),
                    Color(0xFFEBB158),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _Eyebrow('31 MARCH • SCORPIO'),
                  const SizedBox(height: 8),
                  Text(
                    'Wear confidence,\nnot noise',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 34,
                      height: 0.94,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your best energy today comes from decisiveness. Red accents help visibility, but balance them with restraint.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      height: 1.48,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: _StatChip(
                          label: 'Lucky Color',
                          value: 'Rust Red',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StatChip(
                          label: 'Lucky Number',
                          value: '8',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _SectionHeading(title: 'Companion chat', action: '3 free left'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _PreviewPalette.border),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _PreviewPalette.midnight.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _chatBubble(
                        'Should I wear a red shirt today?',
                        fill: const Color(0xFFF2E8DD),
                        textColor: _PreviewPalette.ink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _chatBubble(
                      'Yes, but keep the rest of the outfit neutral. It matches today’s visibility theme without becoming too loud.',
                      fill: const Color(0xFF2F3659),
                      textColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const <Widget>[
                      _MiniChip('Ask about work'),
                      _MiniChip('Ask about love'),
                      _MiniChip('Reward +3 questions'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _SectionHeading(title: 'Do / Don’t', action: 'Grounded tips'),
            const SizedBox(height: 10),
            const _InsightRow(
              icon: Icons.check_circle_outline_rounded,
              title: 'Do',
              body: 'Keep one visible choice bold and intentional.',
              accent: _PreviewPalette.teal,
            ),
            const SizedBox(height: 10),
            const _InsightRow(
              icon: Icons.remove_circle_outline_rounded,
              title: 'Don’t',
              body: 'Overcrowd the day with low-value commitments.',
              accent: _PreviewPalette.coral,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(
    String text, {
    required Color fill,
    required Color textColor,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 215),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 12.5,
            height: 1.48,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPreview extends StatelessWidget {
  const _SubscriptionPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color(0xFFF8F0E6),
            Color(0xFFFFFCF7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Premium, softened',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      height: 0.95,
                      fontWeight: FontWeight.w700,
                      color: _PreviewPalette.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _PreviewPalette.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Ad-free',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _PreviewPalette.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The paywall no longer blocks the app harshly. It sells calm, convenience, and richer access.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.5,
                color: _PreviewPalette.inkSoft,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: const <Widget>[
                Expanded(
                  child: _PlanBadge(
                    title: 'Free',
                    subtitle: 'Ads + generous limits',
                    accent: _PreviewPalette.teal,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _PlanBadge(
                    title: 'Premium',
                    subtitle: 'Ad-free + more depth',
                    accent: _PreviewPalette.berry,
                    highlighted: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _BenefitTile(
              icon: Icons.block_rounded,
              title: 'Remove ads',
              body: 'No banners, no reward prompts, no interruptions.',
            ),
            const SizedBox(height: 10),
            const _BenefitTile(
              icon: Icons.bolt_rounded,
              title: 'Higher limits',
              body: '30 horoscope chat questions/day and broader reading access.',
            ),
            const SizedBox(height: 10),
            const _BenefitTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Priority insights',
              body: 'Premium surfaces feel faster and more complete.',
            ),
            const SizedBox(height: 18),
            const _PlanCard(
              title: 'Premium Monthly',
              price: '₹199',
              note: 'For users who want an ad-free daily ritual.',
              accent: _PreviewPalette.coral,
            ),
            const SizedBox(height: 12),
            const _PlanCard(
              title: 'Premium Yearly',
              price: '₹1,299',
              note: 'Best value. Includes full ritual access across the year.',
              accent: _PreviewPalette.teal,
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon(this.icon, {this.dark = false});

  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 18,
        color: dark ? _PreviewPalette.ink : Colors.white,
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 52,
        height: 4,
        decoration: BoxDecoration(
          color: _PreviewPalette.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.fill,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color fill;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: fill == Colors.white
              ? _PreviewPalette.border
              : fill.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: _PreviewPalette.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _PreviewPalette.inkSoft,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _PreviewPalette.border)),
      ],
    );
  }
}

class _InputMock extends StatelessWidget {
  const _InputMock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PreviewPalette.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: _PreviewPalette.inkSoft,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.fill});

  final String label;
  final Gradient fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: fill,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _PreviewPalette.coral.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w800,
        color: Colors.white.withValues(alpha: 0.82),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 30,
        height: 0.94,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _PreviewPalette.ink,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            action,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _PreviewPalette.berry,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _PreviewPalette.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
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
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _PreviewPalette.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    height: 1.45,
                    color: _PreviewPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallModuleCard extends StatelessWidget {
  const _SmallModuleCard({
    required this.title,
    required this.badge,
    required this.accent,
  });

  final String title;
  final String badge;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _PreviewPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _PreviewPalette.ink,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              badge,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlinePremiumCard extends StatelessWidget {
  const _InlinePremiumCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            _PreviewPalette.premium,
            Color(0xFF6B4D63),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Premium feels lighter now',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No ads, higher daily limits, smoother companion chat, and richer guidance without making free users feel shut out.',
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _PreviewPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _PreviewPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    height: 1.45,
                    color: _PreviewPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? accent.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? accent : _PreviewPalette.border,
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _PreviewPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 12,
              height: 1.4,
              color: _PreviewPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _PreviewPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _PreviewPalette.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _PreviewPalette.premium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _PreviewPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    height: 1.48,
                    color: _PreviewPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.note,
    required this.accent,
    this.emphasized = false,
  });

  final String title;
  final String price;
  final String note;
  final Color accent;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emphasized ? accent.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: emphasized ? accent : _PreviewPalette.border,
          width: emphasized ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _PreviewPalette.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    height: 1.45,
                    color: _PreviewPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            price,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 34,
              height: 0.94,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
