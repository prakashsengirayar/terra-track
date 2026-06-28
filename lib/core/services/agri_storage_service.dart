// lib/core/services/agri_storage_service.dart
//
// Firebase Storage helper for the agricultural Land/Worker/Work-Entry/
// Expense/Harvest module.
//
// DEVIATION FROM THE ORIGINAL SPEC, FLAGGED EXPLICITLY:
// The original request asked for `uploadPhoto(File file, String path)`.
// This codebase targets Flutter Web in addition to Android/iOS, and
// `dart:io File` / `FileImage` / `Reference.putFile()` do not compile on
// Web — this exact constraint is already documented in this repo's
// SETUP_NOTES.md and is why the existing data source
// (lib/data/datasources/remote/firestore_datasource.dart -> uploadFile)
// uses `Uint8List` + `Reference.putData()` instead of `File`/`putFile()`.
// To keep the agri module Web-compatible and consistent with the rest of
// the app, `uploadPhoto` below takes `Uint8List bytes` (e.g. from
// `XFile.readAsBytes()` via image_picker) rather than a `dart:io File`.

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class AgriStorageService {
  final FirebaseStorage _storage;

  AgriStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads [bytes] to Firebase Storage at [path] and returns the public
  /// download URL. [path] should be a full storage path, e.g.
  /// 'agri/worker_photos/<uuid>.jpg' (see AgriConstants for base paths).
  Future<String> uploadPhoto(Uint8List bytes, String path) async {
    final ref = _storage.ref(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  /// Deletes the file at [path]. Safe to call even if the file does not
  /// exist — Storage's "object not found" error is swallowed so callers
  /// (e.g. "replace photo" flows) don't need to special-case it.
  Future<void> deletePhoto(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
