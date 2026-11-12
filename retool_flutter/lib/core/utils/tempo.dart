import 'dart:async';

/// Erro lançado por [comTimeout] quando o prazo se esgota (code = 'timeout').
class ErroTimeout implements Exception {
  final String code = 'timeout';
  final String message;
  ErroTimeout([this.message = 'A operação demorou mais que o esperado.']);

  @override
  String toString() => 'ErroTimeout: $message';
}

/// Prazo para gravações feitas por um clique (salvar, enviar, aprovar).
const int prazoGravacaoMs = 15000;

/// Mensagem para quando a gravação não teve resposta no prazo.
const String mensagemGravacaoSemResposta =
    'Sem resposta do servidor. Verifique a conexão: a gravação pode ser concluída quando ela voltar. Confira antes de tentar de novo.';

/// Rejeita com [ErroTimeout] se o Future não concluir no tempo limite [ms].
/// Se ela ainda concluir depois do prazo, [aoConcluirDepois] é chamado.
Future<T> comTimeout<T>(
  Future<T> future,
  int ms, {
  String? mensagem,
  void Function(T valor)? aoConcluirDepois,
}) {
  if (ms <= 0) return future;
  final completer = Completer<T>();
  bool esgotou = false;

  final timer = Timer(Duration(milliseconds: ms), () {
    esgotou = true;
    if (!completer.isCompleted) {
      completer.completeError(ErroTimeout(mensagem ?? 'A operação demorou mais que o esperado.'));
    }
  });

  future.then(
    (v) {
      timer.cancel();
      if (esgotou) {
        aoConcluirDepois?.call(v);
      } else if (!completer.isCompleted) {
        completer.complete(v);
      }
    },
    onError: (e, st) {
      timer.cancel();
      if (!esgotou && !completer.isCompleted) {
        completer.completeError(e, st);
      }
    },
  );

  return completer.future;
}

Future<T> gravarComPrazo<T>(Future<T> future, {void Function(T)? aoConcluirDepois}) {
  return comTimeout(
    future,
    prazoGravacaoMs,
    mensagem: mensagemGravacaoSemResposta,
    aoConcluirDepois: aoConcluirDepois,
  );
}

