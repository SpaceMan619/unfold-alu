import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../auth/session_controller.dart';

final profilePhotoUrlProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(sessionProvider.select((session) => session.uid));
  if (uid.isEmpty) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) => snapshot.data()?['photoUrl'] as String?);
});

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

    final square = img.copyResizeCropSquare(decoded, size: 1024);
    final bytes = Uint8List.fromList(img.encodeJpg(square, quality: 82));
    if (bytes.length > 2 * 1024 * 1024) {
      throw const FormatException('The processed image is still too large.');
    }
    final object = FirebaseStorage.instance.ref(
      'users/$uid/profile/avatar.jpg',
    );
    await object.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await object.getDownloadURL();
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'photoUrl': url,
      'photoUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }
}
