import '../entities/dispositivo.dart';

const Set<String> camposIgnorados = {'id', 'dataCriacao', 'chaveCD'};

bool _vazio(dynamic v) {
  if (v == null) return true;
  if (v is String && v.isEmpty) return true;
  if (v is List && v.isEmpty) return true;
  return false;
}

bool _iguais(dynamic a, dynamic b) {
  if (_vazio(a) && _vazio(b)) return true;
  if (a == b) return true;
  if (a is List || b is List) {
    if (a is! List || b is! List || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_iguais(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map || b is Map) {
    if (a is! Map || b is! Map) return false;
    final chavesA = a.keys.where((k) => a[k] != null).toList();
    final chavesB = b.keys.where((k) => b[k] != null).toList();
    if (chavesA.length != chavesB.length) return false;
    for (final k in chavesA) {
      if (!_iguais(a[k], b[k])) return false;
    }
    return true;
  }
  return false;
}

Map<String, dynamic> camposAlterados(Dispositivo? original, Map<String, dynamic> editado) {
  final base = original?.toMap() ?? {};
  final resultado = <String, dynamic>{};

  for (final entry in editado.entries) {
    final campo = entry.key;
    final valor = entry.value;
    if (camposIgnorados.contains(campo) || valor == null) continue;
    if (!_iguais(base[campo], valor)) {
      resultado[campo] = valor;
    }
  }
  return resultado;
}

bool alteraImagem(Map<String, dynamic> alteracoes) {
  return camposImagemPropagados.any((c) => alteracoes.containsKey(c));
}

