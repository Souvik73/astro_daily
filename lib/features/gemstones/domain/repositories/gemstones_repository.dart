import '../entities/gemstone_insight.dart';

abstract class GemstonesRepository {
  Future<GemstoneInsight> getGemstoneInsight();
}
