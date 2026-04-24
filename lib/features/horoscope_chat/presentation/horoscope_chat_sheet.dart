import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/contracts.dart';
import '../../daily_horoscope/domain/entities/daily_horoscope.dart';
import '../bloc/horoscope_chat_bloc.dart';
import '../domain/entities/chat_message.dart';

class HoroscopeChatSheet extends StatefulWidget {
  const HoroscopeChatSheet._();

  static Future<void> show(
    BuildContext context, {
    required DailyHoroscope horoscope,
    required String locale,
    String? initialQuestion,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<HoroscopeChatBloc>(
        create: (_) {
          final HoroscopeChatBloc bloc = sl<HoroscopeChatBloc>()
            ..add(HoroscopeChatOpened(horoscope: horoscope, locale: locale));
          if (initialQuestion != null) {
            bloc.add(HoroscopeChatMessageSent(question: initialQuestion));
          }
          return bloc;
        },
        child: const HoroscopeChatSheet._(),
      ),
    );
  }

  @override
  State<HoroscopeChatSheet> createState() => _HoroscopeChatSheetState();
}

class _HoroscopeChatSheetState extends State<HoroscopeChatSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(BuildContext context, String text) {
    final String q = text.trim();
    if (q.isEmpty) return;
    _inputController.clear();
    context
        .read<HoroscopeChatBloc>()
        .add(HoroscopeChatMessageSent(question: q));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.canvasSoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (BuildContext ctx, ScrollController sheetScroll) {
          return Column(
            children: <Widget>[
              const _SheetHandle(),
              const _ChatHeader(),
              const Divider(height: 1),
              Expanded(
                child: BlocConsumer<HoroscopeChatBloc, HoroscopeChatState>(
                  listenWhen: (HoroscopeChatState prev, HoroscopeChatState curr) =>
                      curr.messages.length != prev.messages.length ||
                      curr.status == HoroscopeChatStatus.failure,
                  listener: (BuildContext ctx, HoroscopeChatState state) {
                    _scrollToBottom();
                    if (state.status == HoroscopeChatStatus.failure &&
                        state.errorMessage != null) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(state.errorMessage!)),
                        );
                    }
                  },
                  builder: (BuildContext ctx, HoroscopeChatState state) {
                    return Column(
                      children: <Widget>[
                        if (state.access != FeatureAccess.open &&
                            state.messages.isNotEmpty)
                          _QuotaBanner(access: state.access),
                        Expanded(
                          child: state.messages.isEmpty
                              ? _EmptyPrompt(
                                  zodiacSign:
                                      state.horoscope?.zodiacSign ?? '',
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 12, 16, 8),
                                  itemCount: state.messages.length +
                                      (state.status ==
                                              HoroscopeChatStatus.sending
                                          ? 1
                                          : 0),
                                  itemBuilder:
                                      (BuildContext ctx, int index) {
                                    if (index == state.messages.length) {
                                      return const _TypingIndicator();
                                    }
                                    return _MessageBubble(
                                      message: state.messages[index],
                                    );
                                  },
                                ),
                        ),
                        if (state.messages.isEmpty)
                          _SuggestionRow(
                            onTap: (String q) => _send(ctx, q),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _InputRow(
                controller: _inputController,
                onSend: () => _send(context, _inputController.text),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.border,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HoroscopeChatBloc, HoroscopeChatState>(
      buildWhen: (HoroscopeChatState p, HoroscopeChatState c) =>
          p.questionsRemaining != c.questionsRemaining,
      builder: (BuildContext ctx, HoroscopeChatState state) {
        final String badge = state.questionsRemaining < 0
            ? 'Unlimited'
            : '${state.questionsRemaining} left today';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Horoscope Companion',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.berry,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: AppTheme.inkSoft,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.zodiacSign});

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
              'Ask anything about today\'s reading — work, love, lucky signs, and more.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.onTap});

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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFFF2E7DA)
                  : AppTheme.midnight,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
            ),
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isUser ? AppTheme.ink : Colors.white,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppTheme.midnight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: const SizedBox(
            width: 36,
            height: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _Dot(delay: Duration.zero),
                _Dot(delay: Duration(milliseconds: 160)),
                _Dot(delay: Duration(milliseconds: 320)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});

  final Duration delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Colors.white54,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuotaBanner extends StatelessWidget {
  const _QuotaBanner({required this.access});

  final FeatureAccess access;

  @override
  Widget build(BuildContext context) {
    final bool isReward = access == FeatureAccess.rewardUnlockAvailable;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isReward
          ? AppTheme.gold.withValues(alpha: 0.12)
          : AppTheme.coral.withValues(alpha: 0.10),
      child: Text(
        isReward
            ? 'Daily limit reached — watch an ad to unlock 3 more questions.'
            : 'Upgrade to Premium for up to 30 questions per day.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isReward ? AppTheme.gold : AppTheme.coral,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HoroscopeChatBloc, HoroscopeChatState>(
      buildWhen: (HoroscopeChatState p, HoroscopeChatState c) =>
          p.status != c.status || p.access != c.access,
      builder: (BuildContext ctx, HoroscopeChatState state) {
        final bool blocked = state.status == HoroscopeChatStatus.sending ||
            state.access != FeatureAccess.open;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 12,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !blocked,
                    textInputAction: TextInputAction.send,
                    onSubmitted: blocked ? null : (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: blocked && state.access != FeatureAccess.open
                          ? 'Daily limit reached'
                          : 'Ask your companion…',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _SendButton(onSend: blocked ? null : onSend),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onSend});

  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: onSend != null ? AppTheme.midnight : AppTheme.border,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: onSend,
        icon: const Icon(Icons.arrow_upward_rounded),
        color: Colors.white,
        iconSize: 20,
      ),
    );
  }
}
