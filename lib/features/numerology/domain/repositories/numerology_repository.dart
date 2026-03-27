import '../entities/numerology_insight.dart';

abstract class NumerologyRepository {
  Future<NumerologyInsight> getNumerologyInsight();
}
