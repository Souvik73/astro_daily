import '../../../../core/error/failures.dart';
import '../../../../core/models/astro_models.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../daily_horoscope/domain/entities/daily_horoscope.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/horoscope_chat_repository.dart';
import '../datasources/horoscope_chat_data_source.dart';

class HoroscopeChatRepositoryImpl implements HoroscopeChatRepository {
  HoroscopeChatRepositoryImpl({
    required HoroscopeChatDataSource dataSource,
    required AuthRepository authRepository,
  })  : _dataSource = dataSource,
        _authRepository = authRepository;

  final HoroscopeChatDataSource _dataSource;
  final AuthRepository _authRepository;

  @override
  Future<ChatMessage> sendMessage({
    required String question,
    required DailyHoroscope horoscope,
    required String locale,
    List<Map<String, String>> chatHistory = const <Map<String, String>>[],
  }) async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    final HoroscopeResponse context = HoroscopeResponse(
      date: horoscope.date,
      zodiacSign: horoscope.zodiacSign,
      locale: horoscope.locale,
      summary: horoscope.summary,
      luckyColor: horoscope.luckyColor,
      luckyNumber: horoscope.luckyNumber,
    );

    final String answer = await _dataSource.askQuestion(
      question: question,
      horoscope: context,
      locale: locale,
      chatHistory: chatHistory,
    );

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: answer,
      author: ChatAuthor.assistant,
      timestamp: DateTime.now(),
    );
  }
}
