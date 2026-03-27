import '../entities/kundli_insight.dart';

abstract class KundliRepository {
  Future<KundliInsight> getKundliInsight();
}
