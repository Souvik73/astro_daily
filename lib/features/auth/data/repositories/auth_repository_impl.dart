import '../../../../core/models/subscription_models.dart';
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
  Future<void> signInWithEmail(String email) {
    return _localDataSource.signInWithEmail(email);
  }

  @override
  Future<void> signOut() {
    return _localDataSource.signOut();
  }

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) {
    return _localDataSource.updateSubscriptionTier(tier);
  }
}
