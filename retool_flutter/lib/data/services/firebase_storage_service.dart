import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/file_attachment.dart';
import '../../domain/repositories/i_storage_service.dart';
import '../../core/utils/file_validators.dart';
import '../datasources/firebase_datasource.dart';

class FirebaseStorageService implements IStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService([FirebaseStorage? storage])
      : _storage = storage ?? FirebaseDataSource.storage;

  @override
  Future<FileAttachment> uploadFile({
    required String dispositivoId,
    required String categoria,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final validation = validateFileProperties(
      size: bytes.length,
      contentType: contentType,
      categoria: categoria,
    );
    if (!validation.valid) {
      throw ArgumentError(validation.error ?? 'Arquivo inválido');
    }

    final sanitized = sanitizeFileName(fileName);
    final fileId = const Uuid().v4();
    final storagePath = 'retool/dispositivos/$dispositivoId/$categoria/${fileId}_$sanitized';

    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {'originalName': fileName},
    );

    final uploadTask = await ref.putData(bytes, metadata);
    final downloadURL = await uploadTask.ref.getDownloadURL();

    return FileAttachment(
      id: fileId,
      originalName: fileName,
      fileName: '${fileId}_$sanitized',
      contentType: contentType,
      size: bytes.length,
      storagePath: storagePath,
      downloadURL: downloadURL,
      uploadedAt: DateTime.now().toIso8601String(),
      categoria: categoria,
    );
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    await ref.delete();
  }
}

