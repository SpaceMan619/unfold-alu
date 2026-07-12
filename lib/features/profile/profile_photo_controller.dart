import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../auth/session_controller.dart';

final profilePhotoBytesProvider = StreamProvider<Uint8List?>((ref) {
  final uid = ref.watch(sessionProvider.select((session) => session.uid));
  if (uid.isEmpty) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
        final encoded = snapshot.data()?['profilePhotoBase64'] as String?;
        return encoded == null ? null : base64Decode(encoded);
      });
});

class PublicProfile {
  const PublicProfile({
    this.skills = const [],
    this.interests = const [],
    this.bio = '',
    this.location = 'Kigali, Rwanda',
    this.classYear = 2027,
    this.website = '',
  });

  final List<String> skills;
  final List<String> interests;
  final String bio;
  final String location;
  final int classYear;
  final String website;
}

final publicProfileProvider = StreamProvider<PublicProfile>((ref) {
  final uid = ref.watch(sessionProvider.select((session) => session.uid));
  if (uid.isEmpty) return Stream.value(const PublicProfile());
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data() ?? const <String, dynamic>{};
        return PublicProfile(
          skills: List<String>.from(data['skills'] as List? ?? const []),
          interests: List<String>.from(data['interests'] as List? ?? const []),
          bio: data['bio'] as String? ?? '',
          location: data['location'] as String? ?? 'Kigali, Rwanda',
          classYear: (data['classYear'] as num?)?.toInt() ?? 2027,
          website: data['website'] as String? ?? '',
        );
      });
});

final publicProfileEditorProvider = Provider(PublicProfileEditor.new);

class PublicProfileEditor {
  PublicProfileEditor(this.ref);
  final Ref ref;

  Future<void> save({
    required List<String> skills,
    required List<String> interests,
    required String bio,
    required String location,
    required int classYear,
    required String website,
  }) async {
    final uid = ref.read(sessionProvider).uid;
    if (uid.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'skills': skills,
      'interests': interests,
      'bio': bio.trim(),
      'location': location.trim(),
      'classYear': classYear,
      'website': website.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final profilePhotoUploaderProvider = Provider(ProfilePhotoUploader.new);

class ProfilePhotoUploader {
  ProfilePhotoUploader(this.ref);
  final Ref ref;

  Future<bool> chooseAndUpload() async {
    final uid = ref.read(sessionProvider).uid;
    if (uid.isEmpty) return false;
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return false;
    if (file.size > 8 * 1024 * 1024) {
      throw const FormatException('Choose an image smaller than 8 MB.');
    }
    final source = file.bytes;
    if (source == null) {
      throw const FormatException('Could not read that image.');
    }
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      throw const FormatException('Use a JPG, PNG, or WebP image.');
    }

    final square = img.copyResizeCropSquare(decoded, size: 384);
    final bytes = Uint8List.fromList(img.encodeJpg(square, quality: 74));
    if (bytes.length > 500 * 1024) {
      throw const FormatException('The processed image is still too large.');
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'profilePhotoBase64': base64Encode(bytes),
      'photoUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }
}
