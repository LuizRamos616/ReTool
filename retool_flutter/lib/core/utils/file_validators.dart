import 'dart:math';

const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
const int maxDocumentSizeBytes = 25 * 1024 * 1024; // 25MB

const List<String> allowedImageTypes = ['image/jpeg', 'image/png', 'image/webp'];
const List<String> allowedDocumentTypes = ['application/pdf'];

class ValidationResult {
  final bool valid;
  final String? error;

  const ValidationResult({required this.valid, this.error});
}

ValidationResult validateFileProperties({
  required int size,
  required String contentType,
  required String categoria,
}) {
  final isImageCategory = categoria == 'imagem_peca' || categoria == 'imagem_dispositivo';

  if (isImageCategory) {
    if (!allowedImageTypes.contains(contentType)) {
      return ValidationResult(
        valid: false,
        error: 'Formato de imagem inválido ($contentType). Formatos suportados: JPG, PNG e WEBP.',
      );
    }
    if (size > maxImageSizeBytes) {
      return ValidationResult(
        valid: false,
        error:
            'O tamanho da imagem (${formatFileSize(size)}) excede o limite máximo permitido de ${formatFileSize(maxImageSizeBytes)}.',
      );
    }
  } else if (categoria == 'documento_pdf') {
    if (!allowedDocumentTypes.contains(contentType)) {
      return const ValidationResult(
        valid: false,
        error: 'Formato de documento inválido. Apenas documentos no formato PDF são aceitos.',
      );
    }
    if (size > maxDocumentSizeBytes) {
      return ValidationResult(
        valid: false,
        error:
            'O tamanho do documento (${formatFileSize(size)}) excede o limite máximo de ${formatFileSize(maxDocumentSizeBytes)}.',
      );
    }
  }

  return const ValidationResult(valid: true);
}

String sanitizeFileName(String originalName) {
  // Remove acentos e caracteres especiais, mantendo apenas letras, dígitos, ., _ e -
  var cleanName = originalName
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');

  return cleanName.isEmpty ? 'arquivo' : cleanName;
}

String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  final i = (log(bytes) / log(k)).floor();
  final valor = (bytes / pow(k, i)).toStringAsFixed(1);
  return '$valor ${sizes[i]}';
}

