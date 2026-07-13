import 'package:unfold/features/auth/session_controller.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserProfile?> signInWithGoogle({AccountRole? role}) async => null;

  @override
  Future<UserProfile> saveGoogleProfile({required AccountRole role}) async {
    return UserProfile(
      uid: 'google-user',
      name: 'Rajveer Jolly',
      email: 'rajveer@alustudent.com',
      role: role,
    );
  }

  @override
  Stream<String?> authStateChanges() => Stream.value(null);

  @override
  Future<UserProfile?> profile(String uid) async => null;

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required AccountRole role,
  }) async {
    return UserProfile(uid: 'test-user', name: name, email: email, role: role);
  }

  @override
  Future<void> signOut() async {}
}
