typedef CategoriaAnexo = String;

class CategoriasAnexo {
  static const String imagemPeca = 'imagem_peca';
  static const String imagemDispositivo = 'imagem_dispositivo';
  static const String documentoPdf = 'documento_pdf';
}

class FileAttachment {
  final String id;
  final String originalName;
  final String fileName;
  final String contentType;
  final int size;
  final String storagePath;
  final String downloadURL;
  final String uploadedAt;
  final String categoria; // imagem_peca | imagem_dispositivo | documento_pdf

  const FileAttachment({
    required this.id,
    required this.originalName,
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.storagePath,
    required this.downloadURL,
    required this.uploadedAt,
    required this.categoria,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalName': originalName,
      'fileName': fileName,
      'contentType': contentType,
      'size': size,
      'storagePath': storagePath,
      'downloadURL': downloadURL,
      'uploadedAt': uploadedAt,
      'categoria': categoria,
    };
  }

  factory FileAttachment.fromMap(Map<String, dynamic> map) {
    return FileAttachment(
      id: map['id'] as String? ?? '',
      originalName: map['originalName'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      contentType: map['contentType'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      storagePath: map['storagePath'] as String? ?? '',
      downloadURL: map['downloadURL'] as String? ?? '',
      uploadedAt: map['uploadedAt'] as String? ?? '',
      categoria: map['categoria'] as String? ?? CategoriasAnexo.documentoPdf,
    );
  }
}

