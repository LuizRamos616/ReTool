import 'package:intl/intl.dart';

/// Lê um valor em reais digitado pela pessoa. Aceita o formato brasileiro
/// ("1.500,50", "1500,50", "1.500" = mil e quinhentos), o ponto decimal
/// ("1500.50") e o prefixo "R$". Vazio = 0. Devolve null se não for um
/// número válido, zero ou maior.
double? lerValorMonetario(String digitado) {
  final texto = digitado.trim().replaceFirst(RegExp(r'^R\$\s*', caseSensitive: false), '');
  if (texto.isEmpty) return 0.0;
  final comMilhar = texto.contains(',') || RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(texto);
  final normalizado = comMilhar ? texto.replaceAll('.', '').replaceAll(',', '.') : texto;
  final numero = double.tryParse(normalizado);
  if (numero != null && numero.isFinite && numero >= 0) {
    return numero;
  }
  return null;
}

String formatarMoeda(double? valor) {
  final v = valor ?? 0.0;
  final formato = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return formato.format(v);
}

