import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/features/daily_horoscope/domain/entities/daily_horoscope.dart';
import 'package:astro_daily/features/horoscope_chat/domain/entities/chat_message.dart';
import 'package:astro_daily/features/horoscope_chat/domain/repositories/horoscope_chat_repository.dart';
import 'package:astro_daily/features/horoscope_chat/domain/usecases/send_horoscope_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeHoroscopeChatRepository repository;

  setUp(() {
    repository = _FakeHoroscopeChatRepository();
  });

  test('passes question, horoscope, locale, and history through', () async {
    repository.reply = ChatMessage(
      id: 'm_1',
      content: 'Focus on execution today.',
      author: ChatAuthor.assistant,
      timestamp: DateTime(2026, 3, 19),
      questionsRemaining: 2,
    );
    final useCase = SendHoroscopeMessage(repository);

    final result = await useCase(
      SendHoroscopeMessageParams(
        question: 'What about work today?',
        horoscope: _horoscope(),
        locale: 'en',
        chatHistory: const <Map<String, String>>[
          <String, String>{'role': 'user', 'content': 'Hi'},
        ],
      ),
    );

    expect(repository.lastQuestion, 'What about work today?');
    expect(repository.lastLocale, 'en');
    expect(repository.lastHistory?.single['content'], 'Hi');
    expect(result.content, 'Focus on execution today.');
    expect(result.questionsRemaining, 2);
  });

  test('propagates quota-exceeded failures', () async {
    repository.error = const AiQuotaExceededFailure();
    final useCase = SendHoroscopeMessage(repository);

    expect(
      () => useCase(
        SendHoroscopeMessageParams(
          question: 'Another question',
          horoscope: _horoscope(),
          locale: 'en',
        ),
      ),
      throwsA(isA<AiQuotaExceededFailure>()),
    );
  });
}

DailyHoroscope _horoscope() {
  return DailyHoroscope(
    date: DateTime(2026, 3, 19),
    zodiacSign: 'Aries',
    locale: 'en',
    summary: 'Steady progress wins today.',
    luckyColor: 'Green',
    luckyNumber: 5,
    dosDonts: const <String>['Do: Focus', "Don't: Rush"],
    personalizedFocus: 'pilot, steady progress wins today.',
  );
}

class _FakeHoroscopeChatRepository implements HoroscopeChatRepository {
  ChatMessage? reply;
  Failure? error;

  String? lastQuestion;
  String? lastLocale;
  List<Map<String, String>>? lastHistory;

  @override
  Future<ChatMessage> sendMessage({
    required String question,
    required DailyHoroscope horoscope,
    required String locale,
    List<Map<String, String>> chatHistory = const <Map<String, String>>[],
  }) async {
    lastQuestion = question;
    lastLocale = locale;
    lastHistory = chatHistory;
    final Failure? failure = error;
    if (failure != null) throw failure;
    return reply!;
  }
}
