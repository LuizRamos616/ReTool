import 'dart:typed_data';
import '../entities/file_attachment.dart';

abstract class IStorageService {
  Future<FileAttachment> uploadFile({
    required String dispositivoId,
    required String categoria, // imagem_peca | imagem_dispositivo | documento_pdf
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  });

  Future<void> deleteFile(String storagePath);
}

