import '../../../../core/models/astro_models.dart';
import '../../../../core/services/contracts.dart';

abstract class HoroscopeChatDataSource {
  Future<String> askQuestion({
    required String question,
    required HoroscopeResponse horoscope,
    required String locale,
  });
}

class HoroscopeChatDataSourceImpl implements HoroscopeChatDataSource {
  HoroscopeChatDataSourceImpl({required AiPersonalizer aiPersonalizer})
      : _aiPersonalizer = aiPersonalizer;

  final AiPersonalizer _aiPersonalizer;

  @override
  Future<String> askQuestion({
    required String question,
    required HoroscopeResponse horoscope,
    required String locale,
  }) {
    return _aiPersonalizer.answerHoroscopeQuestion(
      question,
      horoscope: horoscope,
      locale: locale,
    );
  }
}
