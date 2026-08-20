import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/contracts.dart';
import '../bloc/horoscope_chat_bloc.dart';

class ChatInputRow extends StatelessWidget {
  const ChatInputRow({
    required this.controller,
    required this.onSend,
    super.key,
  });

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
