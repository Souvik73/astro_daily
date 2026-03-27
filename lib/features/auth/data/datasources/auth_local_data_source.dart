import 'dart:async';

import '../../../../core/models/subscription_models.dart';
import '../../domain/entities/user.dart';

abstract class AuthLocalDataSource {
  Stream<User?> observeAuthState();
  User? getCurrentUser();
  User? getUserById(String userId);
  Future<void> signInWithEmail(String email);
  Future<void> signOut();
  Future<void> updateSubscriptionTier(SubscriptionTier tier);
  void dispose();
}

class InMemoryAuthLocalDataSource implements AuthLocalDataSource {
  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();
  final Map<String, User> _usersById = <String, User>{};

  User? _currentUser;
  int _idCounter = 1;

  @override
  Stream<User?> observeAuthState() => _controller.stream;

  @override
  User? getCurrentUser() => _currentUser;

  @override
  User? getUserById(String userId) => _usersById[userId];

  @override
  Future<void> signInWithEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final DateTime now = DateTime.now();
    final String userId = 'user_${_idCounter++}';
    final User user = User(
      id: userId,
      email: email,
      displayName: email.split('@').first,
      zodiacSign: 'Aries',
      dateOfBirth: DateTime(now.year - 25, now.month, now.day),
      timeOfBirth: '06:30',
      placeOfBirth: 'Kolkata, India',
      tier: SubscriptionTier.free,
    );
    _usersById[userId] = user;
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) async {
    final User? user = _currentUser;
    if (user == null) {
      return;
    }
    final User updated = user.copyWith(tier: tier);
    _usersById[updated.id] = updated;
    _currentUser = updated;
    _controller.add(updated);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
