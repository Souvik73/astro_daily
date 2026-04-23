import '../../../../core/models/subscription_models.dart';
import '../entities/auth_profile.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Stream<User?> observeAuthState();
  User? getCurrentUser();
  User? getUserById(String userId);
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required AuthProfile profile,
  });
  Future<void> signInWithGoogle({AuthProfile? profile});
  Future<void> signInWithApple({AuthProfile? profile});
  Future<void> signOut();
  Future<void> completeProfile(AuthProfile profile);
  Future<void> updateSubscriptionTier(SubscriptionTier tier);
}
