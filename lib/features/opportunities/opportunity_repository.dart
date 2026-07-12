import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'opportunity.dart';

abstract interface class OpportunityRepository {
  Stream<List<Opportunity>> watchActive();
  Future<void> create(Opportunity opportunity);
  Future<void> update(Opportunity opportunity);
  Future<void> close(String id);
  Future<void> delete(String id);
}

class FirestoreOpportunityRepository implements OpportunityRepository {
  FirestoreOpportunityRepository(this.firestore, this.auth);

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CollectionReference<Map<String, dynamic>> get collection =>
      firestore.collection('opportunities');

  @override
  Stream<List<Opportunity>> watchActive() {
    return collection
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> create(Opportunity opportunity) async {
    final ownerId = auth.currentUser?.uid;
    if (ownerId == null) {
      throw StateError('Sign in before publishing an opportunity.');
    }
    await collection.doc(opportunity.id).set({
      ...opportunity.toMap(),
      'ownerId': ownerId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> update(Opportunity opportunity) {
    return collection.doc(opportunity.id).update({
      ...opportunity.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> close(String id) => collection.doc(id).update({
    'status': 'closed',
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> delete(String id) => collection.doc(id).delete();
}
