import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus { pending, verified, rejected }

class StartupProfile {
  const StartupProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.summary,
    required this.verificationStatus,
  });

  final String id;
  final String ownerId;
  final String name;
  final String summary;
  final VerificationStatus verificationStatus;

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  factory StartupProfile.fromMap(String id, Map<String, dynamic> map) {
    return StartupProfile(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      verificationStatus: VerificationStatus.values.firstWhere(
        (value) => value.name == map['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
    );
  }
}

abstract interface class StartupRepository {
  Stream<StartupProfile?> watchForOwner(String ownerId);
  Future<void> submit({
    required String ownerId,
    required String name,
    required String summary,
  });
}

class FirestoreStartupRepository implements StartupRepository {
  FirestoreStartupRepository(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Stream<StartupProfile?> watchForOwner(String ownerId) {
    return firestore
        .collection('startups')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isEmpty
              ? null
              : StartupProfile.fromMap(
                  snapshot.docs.first.id,
                  snapshot.docs.first.data(),
                ),
        );
  }

  @override
  Future<void> submit({
    required String ownerId,
    required String name,
    required String summary,
  }) {
    return firestore.collection('startups').doc(ownerId).set({
      'ownerId': ownerId,
      'name': name.trim(),
      'summary': summary.trim(),
      'verificationStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
