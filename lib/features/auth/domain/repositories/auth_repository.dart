import '../../../../core/models/subscription_models.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Stream<User?> observeAuthState();
  User? getCurrentUser();
  User? getUserById(String userId);
  Future<void> signInWithEmail(String email);
  Future<void> signOut();
  Future<void> updateSubscriptionTier(SubscriptionTier tier);
}
