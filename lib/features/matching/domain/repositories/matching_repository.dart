import '../entities/matching_result.dart';

abstract class MatchingRepository {
  Future<MatchingResult> getMatchingResult();
}
