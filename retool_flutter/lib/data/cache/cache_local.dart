class CacheLocal {
  static final Map<String, _ItemCache> _memoria = {};

  static void set(String chave, dynamic valor, [Duration? ttl]) {
    _memoria[chave] = _ItemCache(
      valor: valor,
      expiraEm: ttl != null ? DateTime.now().add(ttl) : null,
    );
  }

  static T? get<T>(String chave) {
    final item = _memoria[chave];
    if (item == null) return null;
    if (item.expirado) {
      _memoria.remove(chave);
      return null;
    }
    return item.valor as T?;
  }

  static void remove(String chave) {
    _memoria.remove(chave);
  }

  static void clear() {
    _memoria.clear();
  }
}

class _ItemCache {
  final dynamic valor;
  final DateTime? expiraEm;

  _ItemCache({required this.valor, this.expiraEm});

  bool get expirado => expiraEm != null && DateTime.now().isAfter(expiraEm!);
}

