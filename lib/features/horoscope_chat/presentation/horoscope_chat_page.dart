import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/contracts.dart';
import '../../../core/widgets/astro_page_components.dart';
import '../../daily_horoscope/presentation/bloc/daily_horoscope_bloc.dart';
import '../bloc/horoscope_chat_bloc.dart';
import '../domain/entities/chat_message.dart';
import 'widgets/chat_empty_prompt.dart';
import 'widgets/chat_input_row.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_quota_banner.dart';
import 'widgets/chat_suggestions.dart';

class HoroscopeChatPage extends StatefulWidget {
  const HoroscopeChatPage({super.key});

  @override
  State<HoroscopeChatPage> createState() => _HoroscopeChatPageState();
}

class _HoroscopeChatPageState extends State<HoroscopeChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
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
    return Scaffold(
      backgroundColor: AppTheme.canvasSoft,
      body: SafeArea(
        // Fire HoroscopeChatOpened exactly once — when the horoscope transitions
        // from a non-success state to success. This seeds the chat bloc with the
        // loaded DailyHoroscope so it can build personalised responses.
        child: BlocListener<DailyHoroscopeBloc, DailyHoroscopeState>(
          listenWhen: (DailyHoroscopeState prev, DailyHoroscopeState curr) =>
              prev.status != DailyHoroscopeStatus.success &&
              curr.status == DailyHoroscopeStatus.success &&
              curr.horoscope != null,
          listener: (BuildContext context, DailyHoroscopeState state) {
            final String locale =
                Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
            context.read<HoroscopeChatBloc>().add(
              HoroscopeChatOpened(
                horoscope: state.horoscope!,
                locale: locale,
              ),
            );
          },
          child: BlocBuilder<DailyHoroscopeBloc, DailyHoroscopeState>(
            builder: (BuildContext context, DailyHoroscopeState horoscopeState) {
              // --- Loading ---
              if (horoscopeState.status == DailyHoroscopeStatus.initial ||
                  horoscopeState.status == DailyHoroscopeStatus.loading) {
                return Column(
                  children: <Widget>[
                    const _PageHeader(quotaBadge: ''),
                    const Divider(height: 1),
                    const Expanded(child: AstroLoadingView()),
                  ],
                );
              }

              // --- Error ---
              if (horoscopeState.status == DailyHoroscopeStatus.failure ||
                  horoscopeState.horoscope == null) {
                return Column(
                  children: <Widget>[
                    const _PageHeader(quotaBadge: ''),
                    const Divider(height: 1),
                    Expanded(
                      child: AstroErrorView(
                        message: horoscopeState.errorMessage ??
                            'Unable to load horoscope.',
                        onRetry: () => context.read<DailyHoroscopeBloc>().add(
                          DailyHoroscopeRequested(
                            locale: Localizations.maybeLocaleOf(context)
                                    ?.languageCode ??
                                'en',
                            date: DateTime.now(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // --- Chat ready ---
              return Column(
                children: <Widget>[
                  // Header re-builds only when the quota count changes.
                  BlocBuilder<HoroscopeChatBloc, HoroscopeChatState>(
                    buildWhen: (HoroscopeChatState p, HoroscopeChatState c) =>
                        p.questionsRemaining != c.questionsRemaining,
                    builder: (BuildContext _, HoroscopeChatState chatState) {
                      final String badge =
                          chatState.questionsRemaining < 0
                              ? 'Unlimited'
                              : '${chatState.questionsRemaining} left today';
                      return _PageHeader(quotaBadge: badge);
                    },
                  ),
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
                                      controller: _scrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 8),
                                      itemCount: state.messages.length +
                                          (state.status ==
                                                  HoroscopeChatStatus.sending
                                              ? 1
                                              : 0),
                                      itemBuilder: (
                                        BuildContext _,
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
                                onTap: (String q) => _send(q),
                              ),
                            if (state.messages.isNotEmpty &&
                                state.messages.last.author ==
                                    ChatAuthor.assistant &&
                                state.messages.last.suggestions.isNotEmpty &&
                                state.status != HoroscopeChatStatus.sending)
                              ChatFollowUpRow(
                                suggestions: state.messages.last.suggestions,
                                onTap: (String q) => _send(q),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  ChatInputRow(
                    controller: _inputController,
                    onSend: () => _send(_inputController.text),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page-specific header (back button instead of close button)
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.quotaBadge});

  final String quotaBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: <Widget>[
          AstroTopIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Horoscope Companion',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (quotaBadge.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    quotaBadge,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.berry,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
