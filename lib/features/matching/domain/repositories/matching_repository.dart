import '../../../../core/models/birth_profile.dart';
import '../entities/matching_result.dart';

abstract class MatchingRepository {
  /// The last partner profile the user entered, persisted locally.
  /// Null if the user has never entered one.
  Future<BirthProfile?> getSavedPartner();

  Future<MatchingResult> getMatchingResult(BirthProfile partner);
}
