import '../../../../core/models/astro_models.dart';
import '../../../../core/services/contracts.dart';

abstract class MatchingRemoteDataSource {
  Future<CompatibilityResult> getCompatibility(CompatibilityRequest request);
}

class MatchingRemoteDataSourceImpl implements MatchingRemoteDataSource {
  MatchingRemoteDataSourceImpl({required AstroProvider astroProvider})
    : _astroProvider = astroProvider;

  final AstroProvider _astroProvider;

  @override
  Future<CompatibilityResult> getCompatibility(CompatibilityRequest request) {
    return _astroProvider.getCompatibility(request);
  }
}
