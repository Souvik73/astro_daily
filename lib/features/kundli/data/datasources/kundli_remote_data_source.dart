import '../../../../core/models/astro_models.dart';
import '../../../../core/services/contracts.dart';

abstract class KundliRemoteDataSource {
  Future<KundliData> getKundli(BirthDetails birthDetails);
}

class KundliRemoteDataSourceImpl implements KundliRemoteDataSource {
  KundliRemoteDataSourceImpl({required AstroProvider astroProvider})
    : _astroProvider = astroProvider;

  final AstroProvider _astroProvider;

  @override
  Future<KundliData> getKundli(BirthDetails birthDetails) {
    return _astroProvider.getKundli(birthDetails);
  }
}
