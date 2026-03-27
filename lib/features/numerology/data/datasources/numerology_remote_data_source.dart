import '../../../../core/models/astro_models.dart';
import '../../../../core/services/contracts.dart';

abstract class NumerologyRemoteDataSource {
  Future<NumerologyResult> getNumerology(BirthDetails birthDetails);
}

class NumerologyRemoteDataSourceImpl implements NumerologyRemoteDataSource {
  NumerologyRemoteDataSourceImpl({required AstroProvider astroProvider})
    : _astroProvider = astroProvider;

  final AstroProvider _astroProvider;

  @override
  Future<NumerologyResult> getNumerology(BirthDetails birthDetails) {
    return _astroProvider.getNumerology(birthDetails);
  }
}
