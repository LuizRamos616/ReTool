class Categoria {
  final String id;
  final String? nome;
  final bool? ativo;

  const Categoria({
    required this.id,
    this.nome,
    this.ativo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (nome != null) 'nome': nome,
      if (ativo != null) 'ativo': ativo,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map, [String? id]) {
    return Categoria(
      id: id ?? (map['id'] as String? ?? ''),
      nome: map['nome'] as String?,
      ativo: map['ativo'] as bool?,
    );
  }
}

class Tipo {
  final String id;
  final String nome;
  final bool? ativo;

  const Tipo({
    required this.id,
    required this.nome,
    this.ativo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      if (ativo != null) 'ativo': ativo,
    };
  }

  factory Tipo.fromMap(Map<String, dynamic> map, [String? id]) {
    return Tipo(
      id: id ?? (map['id'] as String? ?? ''),
      nome: map['nome'] as String? ?? '',
      ativo: map['ativo'] as bool?,
    );
  }
}

