class Familia {
  final String id;
  final String nome;
  final bool? ativo;

  const Familia({
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

  factory Familia.fromMap(Map<String, dynamic> map, [String? id]) {
    return Familia(
      id: id ?? (map['id'] as String? ?? ''),
      nome: map['nome'] as String? ?? '',
      ativo: map['ativo'] as bool?,
    );
  }
}

