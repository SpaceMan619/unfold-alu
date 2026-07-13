enum AccountRole { student, founder }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final AccountRole role;
}
