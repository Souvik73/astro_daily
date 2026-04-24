import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/contracts.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../daily_horoscope/domain/entities/daily_horoscope.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_horoscope_message.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum HoroscopeChatStatus { initial, ready, sending, failure }

final class HoroscopeChatState extends Equatable {
  const HoroscopeChatState({
    required this.status,
    this.horoscope,
    this.locale = 'en',
    this.messages = const <ChatMessage>[],
    this.questionsRemaining = 0,
    this.access = FeatureAccess.open,
    this.errorMessage,
  });

  const HoroscopeChatState.initial()
      : this(status: HoroscopeChatStatus.initial);

  final HoroscopeChatStatus status;
  final DailyHoroscope? horoscope;
  final String locale;
  final List<ChatMessage> messages;

  /// Remaining questions for the current quota period. -1 means unlimited.
  final int questionsRemaining;

  /// Latest access decision — drives UI for quota-exceeded states.
  final FeatureAccess access;
  final String? errorMessage;

  HoroscopeChatState copyWith({
    HoroscopeChatStatus? status,
    DailyHoroscope? horoscope,
    String? locale,
    List<ChatMessage>? messages,
    int? questionsRemaining,
    FeatureAccess? access,
    String? errorMessage,
  }) {
    return HoroscopeChatState(
      status: status ?? this.status,
      horoscope: horoscope ?? this.horoscope,
      locale: locale ?? this.locale,
      messages: messages ?? this.messages,
      questionsRemaining: questionsRemaining ?? this.questionsRemaining,
      access: access ?? this.access,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        horoscope,
        locale,
        messages,
        questionsRemaining,
        access,
        errorMessage,
      ];
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class HoroscopeChatEvent extends Equatable {
  const HoroscopeChatEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class HoroscopeChatOpened extends HoroscopeChatEvent {
  const HoroscopeChatOpened({
    required this.horoscope,
    required this.locale,
  });

  final DailyHoroscope horoscope;
  final String locale;

  @override
  List<Object?> get props => <Object?>[horoscope, locale];
}

final class HoroscopeChatMessageSent extends HoroscopeChatEvent {
  const HoroscopeChatMessageSent({required this.question});

  final String question;

  @override
  List<Object?> get props => <Object?>[question];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class HoroscopeChatBloc
    extends Bloc<HoroscopeChatEvent, HoroscopeChatState> {
  HoroscopeChatBloc({
    required SendHoroscopeMessage sendHoroscopeMessage,
    required UsagePolicy usagePolicy,
    required AuthRepository authRepository,
  })  : _sendHoroscopeMessage = sendHoroscopeMessage,
        _usagePolicy = usagePolicy,
        _authRepository = authRepository,
        super(const HoroscopeChatState.initial()) {
    on<HoroscopeChatOpened>(_onChatOpened);
    on<HoroscopeChatMessageSent>(_onMessageSent);
  }

  final SendHoroscopeMessage _sendHoroscopeMessage;
  final UsagePolicy _usagePolicy;
  final AuthRepository _authRepository;

  void _onChatOpened(
    HoroscopeChatOpened event,
    Emitter<HoroscopeChatState> emit,
  ) {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      emit(
        state.copyWith(
          status: HoroscopeChatStatus.failure,
          errorMessage: 'Session expired. Please sign in again.',
        ),
      );
      return;
    }

    final FeatureQuotaStatus quota =
        _usagePolicy.statusFor(user.id, AppFeature.horoscopeChat);

    final int remaining = quota.quota < 0
        ? -1
        : (quota.quota - quota.used).clamp(0, quota.quota);

    emit(
      state.copyWith(
        status: HoroscopeChatStatus.ready,
        horoscope: event.horoscope,
        locale: event.locale,
        questionsRemaining: remaining,
        access: quota.access,
      ),
    );
  }

  Future<void> _onMessageSent(
    HoroscopeChatMessageSent event,
    Emitter<HoroscopeChatState> emit,
  ) async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      emit(
        state.copyWith(
          status: HoroscopeChatStatus.failure,
          errorMessage: 'Session expired. Please sign in again.',
        ),
      );
      return;
    }

    final FeatureAccess access =
        _usagePolicy.resolveAccess(user.id, AppFeature.horoscopeChat);

    if (access != FeatureAccess.open) {
      emit(
        state.copyWith(
          access: access,
          errorMessage: access == FeatureAccess.rewardUnlockAvailable
              ? 'Daily limit reached. Watch an ad to unlock 3 more questions.'
              : 'Upgrade to Premium for up to 30 questions per day.',
        ),
      );
      return;
    }

    // Append the user message immediately so the UI feels responsive.
    final ChatMessage userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: event.question,
      author: ChatAuthor.user,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        status: HoroscopeChatStatus.sending,
        messages: <ChatMessage>[...state.messages, userMessage],
        errorMessage: null,
      ),
    );

    try {
      final ChatMessage reply = await _sendHoroscopeMessage(
        SendHoroscopeMessageParams(
          question: event.question,
          horoscope: state.horoscope!,
          locale: state.locale,
        ),
      );

      _usagePolicy.recordUsage(user.id, AppFeature.horoscopeChat);

      final FeatureQuotaStatus updatedQuota =
          _usagePolicy.statusFor(user.id, AppFeature.horoscopeChat);
      final int remaining = updatedQuota.quota < 0
          ? -1
          : (updatedQuota.quota - updatedQuota.used).clamp(0, updatedQuota.quota);

      emit(
        state.copyWith(
          status: HoroscopeChatStatus.ready,
          messages: <ChatMessage>[...state.messages, reply],
          questionsRemaining: remaining,
          access: updatedQuota.access,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: HoroscopeChatStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HoroscopeChatStatus.failure,
          errorMessage: 'Could not get a response. Please try again.',
        ),
      );
    }
  }
}
