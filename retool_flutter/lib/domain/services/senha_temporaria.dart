import 'dart:math';

const String _maiusculas = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const String _minusculas = 'abcdefghijkmnpqrstuvwxyz';
const String _digitos = '23456789';
const String _simbolos = '!@#\$%*-_+?';
const String _todos = '$_maiusculas$_minusculas$_digitos$_simbolos';

const int tamanhoSenhaTemporaria = 14;
const int tamanhoMinimoSenha = 8;

typedef FonteAleatoria = int Function(int max);

int _fontePadrao(int max) {
  final rng = Random.secure();
  return rng.nextInt(max);
}

String _escolher(String alfabeto, FonteAleatoria fonte) {
  return alfabeto[fonte(alfabeto.length)];
}

String gerarSenhaTemporaria([
  int tamanho = tamanhoSenhaTemporaria,
  FonteAleatoria? fonte,
]) {
  if (tamanho < tamanhoMinimoSenha) {
    throw ArgumentError('A senha temporária deve ter ao menos $tamanhoMinimoSenha caracteres.');
  }
  final f = fonte ?? _fontePadrao;

  final chars = <String>[
    _escolher(_maiusculas, f),
    _escolher(_minusculas, f),
    _escolher(_digitos, f),
    _escolher(_simbolos, f),
  ];

  while (chars.length < tamanho) {
    chars.add(_escolher(_todos, f));
  }

  // Fisher-Yates shuffle
  for (var i = chars.length - 1; i > 0; i--) {
    final j = f(i + 1);
    final temp = chars[i];
    chars[i] = chars[j];
    chars[j] = temp;
  }

  return chars.join();
}

String? validarNovaSenha(String novaSenha, String confirmacao, [String? senhaAtual]) {
  if (novaSenha.isEmpty || novaSenha.length < tamanhoMinimoSenha) {
    return 'A nova senha deve ter no mínimo $tamanhoMinimoSenha caracteres.';
  }
  if (!RegExp(r'[A-Za-z]').hasMatch(novaSenha) || !RegExp(r'\d').hasMatch(novaSenha)) {
    return 'A nova senha deve conter letras e números.';
  }
  if (novaSenha != confirmacao) {
    return 'A confirmação não coincide com a nova senha.';
  }
  if (senhaAtual != null && novaSenha == senhaAtual) {
    return 'A nova senha deve ser diferente da senha temporária.';
  }
  return null;
}

