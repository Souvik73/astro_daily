import '../../../../core/error/failures.dart';
import '../../../../core/mappers/birth_details_mapper.dart';
import '../../../../core/models/astro_models.dart';
import '../entities/user.dart';

class UserBirthDetailsMapper {
  const UserBirthDetailsMapper({
    BirthDetailsMapper birthDetailsMapper = const BirthDetailsMapper(),
  }) : _birthDetailsMapper = birthDetailsMapper;

  final BirthDetailsMapper _birthDetailsMapper;

  BirthDetails map(User user) {
    final birthProfile = user.birthProfile;
    if (birthProfile == null) {
      throw const AuthFailure('Complete your profile to continue.');
    }
    return _birthDetailsMapper.map(birthProfile);
  }
}
