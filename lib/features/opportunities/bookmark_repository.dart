import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class BookmarkRepository {
  Stream<Set<String>> watch(String userId);
  Future<void> setSaved(String userId, String opportunityId, bool saved);
}

class FirestoreBookmarkRepository implements BookmarkRepository {
  FirestoreBookmarkRepository(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> items(String userId) =>
      firestore.collection('bookmarks').doc(userId).collection('items');

  @override
  Stream<Set<String>> watch(String userId) => items(
    userId,
  ).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  @override
  Future<void> setSaved(String userId, String opportunityId, bool saved) {
    final document = items(userId).doc(opportunityId);
    return saved
        ? document.set({'savedAt': FieldValue.serverTimestamp()})
        : document.delete();
  }
}
