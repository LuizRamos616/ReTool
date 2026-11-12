class Produto {
  final String id;
  final String nome;
  final bool? ativo;

  const Produto({
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

  factory Produto.fromMap(Map<String, dynamic> map, [String? id]) {
    return Produto(
      id: id ?? (map['id'] as String? ?? ''),
      nome: map['nome'] as String? ?? '',
      ativo: map['ativo'] as bool?,
    );
  }
}

