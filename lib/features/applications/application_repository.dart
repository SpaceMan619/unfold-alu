import 'package:cloud_firestore/cloud_firestore.dart';

import 'application.dart';

abstract interface class ApplicationRepository {
  Stream<List<OpportunityApplication>> watchForStudent(String studentId);
  Stream<List<OpportunityApplication>> watchForFounder(String founderId);
  Future<void> submit(OpportunityApplication application);
  Future<void> seedFounderDemos(List<OpportunityApplication> applications);
  Future<void> updateStatus(String id, ApplicationStatus status);
  Future<void> withdraw(String id);
}

class FirestoreApplicationRepository implements ApplicationRepository {
  FirestoreApplicationRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get collection =>
      firestore.collection('applications');

  @override
  Stream<List<OpportunityApplication>> watchForStudent(String studentId) {
    return collection
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OpportunityApplication.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<OpportunityApplication>> watchForFounder(String founderId) {
    return collection
        .where('founderId', isEqualTo: founderId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OpportunityApplication.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> submit(OpportunityApplication application) {
    return collection.doc(application.id).set({
      ...application.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> seedFounderDemos(
    List<OpportunityApplication> applications,
  ) async {
    await firestore.runTransaction((transaction) async {
      final records =
          <
            ({
              OpportunityApplication application,
              DocumentReference<Map<String, dynamic>> reference,
              bool exists,
            })
          >[];
      for (final application in applications) {
        final reference = collection.doc(application.id);
        final existing = await transaction.get(reference);
        records.add((
          application: application,
          reference: reference,
          exists: existing.exists,
        ));
      }
      for (final record in records) {
        if (!record.exists) {
          final application = record.application;
          transaction.set(record.reference, {
            ...application.toMap(),
            'createdAt': Timestamp.fromDate(application.createdAt),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  @override
  Future<void> updateStatus(String id, ApplicationStatus status) {
    return collection.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> withdraw(String id) => collection.doc(id).delete();
}
