import '../../../daily_horoscope/domain/entities/daily_horoscope.dart';
import '../entities/chat_message.dart';

abstract class HoroscopeChatRepository {
  Future<ChatMessage> sendMessage({
    required String question,
    required DailyHoroscope horoscope,
    required String locale,
  });
}
