import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/contracts.dart';
import '../../daily_horoscope/domain/entities/daily_horoscope.dart';
import '../bloc/horoscope_chat_bloc.dart';
import '../domain/entities/chat_message.dart';
import 'widgets/chat_empty_prompt.dart';
import 'widgets/chat_input_row.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_quota_banner.dart';
import 'widgets/chat_suggestions.dart';

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
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  /// Captured from the DraggableScrollableSheet builder each frame.
  /// Using the sheet-provided controller (not an independent one) lets the
  /// sheet intercept drag gestures from the list — pulling up through the list
  /// expands the sheet; pulling down at the list top collapses it.
  ScrollController? _listScrollController;

  @override
  void dispose() {
    _inputController.dispose();
    _sheetController.dispose();
    // _listScrollController is owned by DraggableScrollableSheet — do not dispose.
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
      final ScrollController? sc = _listScrollController;
      if (sc != null && sc.hasClients) {
        sc.animateTo(
          sc.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet must be the ROOT widget so showModalBottomSheet
    // passes it the full-screen height as its constraint. If it were nested
    // inside a Container or any other unconstrained widget, it could never
    // measure how much space is available and would refuse to expand beyond
    // its initial size.
    return DraggableScrollableSheet(
      controller: _sheetController,
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const <double>[0.72, 1.0],
      builder: (BuildContext ctx, ScrollController sheetScroll) {
        // Capture the sheet-provided controller so _scrollToBottom can drive it.
        _listScrollController = sheetScroll;

        // ListenableBuilder sits INSIDE the sheet's builder so it can read
        // the live sheet size from the controller without constraining it.
        return ListenableBuilder(
          listenable: _sheetController,
          builder: (BuildContext context, Widget? _) {
            // Animate the top corner radius from 28 → 0 as the sheet travels
            // from 90 % to 100 % of the viewport — seamless full-screen look.
            final double size =
                _sheetController.isAttached ? _sheetController.size : 0.72;
            final double t = ((size - 0.90) / 0.10).clamp(0.0, 1.0);
            final double radius = 28.0 * (1.0 - t);

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.canvasSoft,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(radius)),
              ),
              child: Column(
                children: <Widget>[
                  const _SheetHandle(),
                  const _ChatHeader(),
                  const Divider(height: 1),
                  Expanded(
                    child: BlocConsumer<HoroscopeChatBloc, HoroscopeChatState>(
                      listenWhen: (
                        HoroscopeChatState prev,
                        HoroscopeChatState curr,
                      ) =>
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
                              ChatQuotaBanner(access: state.access),
                            Expanded(
                              child: state.messages.isEmpty
                                  ? ChatEmptyPrompt(
                                      zodiacSign:
                                          state.horoscope?.zodiacSign ?? '',
                                    )
                                  : ListView.builder(
                                      controller: sheetScroll,
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 8),
                                      itemCount: state.messages.length +
                                          (state.status ==
                                                  HoroscopeChatStatus.sending
                                              ? 1
                                              : 0),
                                      itemBuilder: (
                                        BuildContext ctx,
                                        int index,
                                      ) {
                                        if (index == state.messages.length) {
                                          return const ChatTypingIndicator();
                                        }
                                        return ChatMessageBubble(
                                          message: state.messages[index],
                                        );
                                      },
                                    ),
                            ),
                            if (state.messages.isEmpty)
                              ChatSuggestionRow(
                                onTap: (String q) => _send(ctx, q),
                              ),
                            if (state.messages.isNotEmpty &&
                                state.messages.last.author ==
                                    ChatAuthor.assistant &&
                                state.messages.last.suggestions.isNotEmpty &&
                                state.status != HoroscopeChatStatus.sending)
                              ChatFollowUpRow(
                                suggestions: state.messages.last.suggestions,
                                onTap: (String q) => _send(ctx, q),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  ChatInputRow(
                    controller: _inputController,
                    onSend: () => _send(context, _inputController.text),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet-specific sub-widgets (not shared with the full page)
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
