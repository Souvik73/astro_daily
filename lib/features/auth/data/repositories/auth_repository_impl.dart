import '../../../../core/models/subscription_models.dart';
import '../../domain/entities/auth_profile.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final AuthLocalDataSource _localDataSource;

  @override
  User? getCurrentUser() {
    return _localDataSource.getCurrentUser();
  }

  @override
  User? getUserById(String userId) {
    return _localDataSource.getUserById(userId);
  }

  @override
  Stream<User?> observeAuthState() {
    return _localDataSource.observeAuthState();
  }

  @override
  Future<void> signInWithEmail(String email, String password) {
    return _localDataSource.signInWithEmail(email, password);
  }

  @override
  Future<void> signInWithGoogle({AuthProfile? profile}) {
    return _localDataSource.signInWithGoogle(profile: profile);
  }

  @override
  Future<void> signInWithApple({AuthProfile? profile}) {
    return _localDataSource.signInWithApple(profile: profile);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required AuthProfile profile,
  }) {
    return _localDataSource.signUpWithEmail(
      email: email,
      password: password,
      profile: profile,
    );
  }

  @override
  Future<void> signOut() {
    return _localDataSource.signOut();
  }

  @override
  Future<void> completeProfile(AuthProfile profile) {
    return _localDataSource.completeProfile(profile);
  }

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) {
    return _localDataSource.updateSubscriptionTier(tier);
  }
}
