import '../../domain/entities/user.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import '../../domain/services/senha_temporaria.dart';
import 'acessos_comum.dart';

typedef AtualizarSenhaAuth = Future<void> Function(String senhaAtual, String novaSenha);

class DadosTrocaSenha {
  final UserProfile usuario;
  final String senhaAtual;
  final String novaSenha;
  final String confirmacao;

  const DadosTrocaSenha({
    required this.usuario,
    required this.senhaAtual,
    required this.novaSenha,
    required this.confirmacao,
  });
}

class ConcluirTrocaSenhaUseCase {
  final IUsersRepository usersRepo;
  final IAuditLogRepository auditRepo;
  final AtualizarSenhaAuth atualizarSenhaAuth;

  ConcluirTrocaSenhaUseCase(this.usersRepo, this.auditRepo, this.atualizarSenhaAuth);

  Future<void> execute(DadosTrocaSenha dados) async {
    if (dados.senhaAtual.isEmpty) {
      throw ErroValidacao('Informe a senha temporária recebida.');
    }
    final erro = validarNovaSenha(dados.novaSenha, dados.confirmacao, dados.senhaAtual);
    if (erro != null) throw ErroValidacao(erro);

    try {
      await atualizarSenhaAuth(dados.senhaAtual, dados.novaSenha);
    } catch (e) {
      final autor = autorAuditoria(dados.usuario);
      await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
        usuarioUid: autor.usuarioUid,
        usuarioNome: autor.usuarioNome,
        usuarioEmail: autor.usuarioEmail,
        usuarioPerfil: autor.usuarioPerfil,
        acao: AuditLogAcoes.trocaSenha,
        categoria: AuditLogCategorias.autenticacao,
        resultado: 'falha',
        acaoDescricao: 'Falha na troca obrigatória de senha (primeiro acesso)',
        tipoEntidade: 'usuario',
        entidadeId: dados.usuario.uid,
        entidadeNome: dados.usuario.nome,
        conteudo: {'erro': e.toString()},
      ));
      rethrow;
    }

    final agora = DateTime.now().toIso8601String();
    await usersRepo.updateProfile(dados.usuario.uid, {
      'trocaSenhaObrigatoria': false,
      'senhaAlteradaEm': agora,
    });

    final autor = autorAuditoria(dados.usuario);
    await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
      usuarioUid: autor.usuarioUid,
      usuarioNome: autor.usuarioNome,
      usuarioEmail: autor.usuarioEmail,
      usuarioPerfil: autor.usuarioPerfil,
      acao: AuditLogAcoes.trocaSenha,
      categoria: AuditLogCategorias.autenticacao,
      acaoDescricao: 'Substituiu a senha temporária no primeiro acesso',
      tipoEntidade: 'usuario',
      entidadeId: dados.usuario.uid,
      entidadeNome: dados.usuario.nome,
      conteudo: {'motivo': 'primeiro_acesso'},
    ));
  }
}

