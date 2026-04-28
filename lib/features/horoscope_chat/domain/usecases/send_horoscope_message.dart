import '../../../../core/usecase/usecase.dart';
import '../../../daily_horoscope/domain/entities/daily_horoscope.dart';
import '../entities/chat_message.dart';
import '../repositories/horoscope_chat_repository.dart';

class SendHoroscopeMessage
    implements UseCase<Future<ChatMessage>, SendHoroscopeMessageParams> {
  SendHoroscopeMessage(this._repository);

  final HoroscopeChatRepository _repository;

  @override
  Future<ChatMessage> call(SendHoroscopeMessageParams params) {
    return _repository.sendMessage(
      question: params.question,
      horoscope: params.horoscope,
      locale: params.locale,
      chatHistory: params.chatHistory,
    );
  }
}

class SendHoroscopeMessageParams {
  const SendHoroscopeMessageParams({
    required this.question,
    required this.horoscope,
    required this.locale,
    this.chatHistory = const <Map<String, String>>[],
  });

  final String question;
  final DailyHoroscope horoscope;
  final String locale;
  final List<Map<String, String>> chatHistory;
}
