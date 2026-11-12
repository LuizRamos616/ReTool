import '../../domain/entities/user.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import '../../domain/services/senha_temporaria.dart';
import 'acessos_comum.dart';

class ContaAuthCriada {
  final String uid;
  final Future<void> Function() desfazer;
  final Future<void> Function() finalizar;

  const ContaAuthCriada({
    required this.uid,
    required this.desfazer,
    required this.finalizar,
  });
}

typedef CriarContaAuth = Future<ContaAuthCriada> Function(String email, String senha);

class DadosNovaConta {
  final UserProfile? admin;
  final String nome;
  final String email;
  final String perfil;

  const DadosNovaConta({
    required this.admin,
    required this.nome,
    required this.email,
    required this.perfil,
  });
}

class ContaCriada {
  final UserProfile perfil;
  final String senhaTemporaria;

  const ContaCriada({required this.perfil, required this.senhaTemporaria});
}

class CriarContaAdministrativaUseCase {
  final IUsersRepository usersRepo;
  final IAuditLogRepository auditRepo;
  final CriarContaAuth criarContaAuth;
  final String Function() gerarSenha;

  CriarContaAdministrativaUseCase(
    this.usersRepo,
    this.auditRepo,
    this.criarContaAuth, {
    String Function()? gerarSenha,
  }) : gerarSenha = gerarSenha ?? (() => gerarSenhaTemporaria());

  Future<ContaCriada> execute(DadosNovaConta dados) async {
    if (!isAdministrador(dados.admin)) {
      if (dados.admin != null) {
        final autor = autorAuditoria(dados.admin!);
        await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
          usuarioUid: autor.usuarioUid,
          usuarioNome: autor.usuarioNome,
          usuarioEmail: autor.usuarioEmail,
          usuarioPerfil: autor.usuarioPerfil,
          acao: AuditLogAcoes.criacaoUsuario,
          categoria: AuditLogCategorias.usuarios,
          resultado: 'negado',
          acaoDescricao: 'Tentativa de criar conta sem permissão',
          tipoEntidade: 'usuario',
          entidadeId: 'nova-conta',
        ));
      }
      throw ErroPermissao();
    }

    final nomeLimpo = limparTexto(dados.nome, 120);
    final emailNormalizado = dados.email.trim().toLowerCase();
    if (nomeLimpo.isEmpty) throw ErroValidacao('Informe o nome completo do colaborador.');
    if (!emailValido(emailNormalizado)) throw ErroValidacao('Informe um e-mail válido.');
    if (!isPerfilAtribuivel(dados.perfil)) throw ErroValidacao('Selecione um cargo válido.');

    final senhaTemporaria = gerarSenha();
    ContaAuthCriada conta;
    try {
      conta = await criarContaAuth(emailNormalizado, senhaTemporaria);
    } catch (e) {
      final autor = autorAuditoria(dados.admin!);
      await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
        usuarioUid: autor.usuarioUid,
        usuarioNome: autor.usuarioNome,
        usuarioEmail: autor.usuarioEmail,
        usuarioPerfil: autor.usuarioPerfil,
        acao: AuditLogAcoes.criacaoUsuario,
        categoria: AuditLogCategorias.usuarios,
        resultado: 'falha',
        acaoDescricao: 'Falha ao criar a conta de $nomeLimpo',
        tipoEntidade: 'usuario',
        entidadeId: emailNormalizado,
        entidadeNome: nomeLimpo,
        conteudo: {'email': emailNormalizado, 'perfil': dados.perfil, 'erro': e.toString()},
      ));
      rethrow;
    }

    final agora = DateTime.now().toIso8601String();
    final novoPerfil = UserProfile(
      uid: conta.uid,
      email: emailNormalizado,
      nome: nomeLimpo,
      perfil: dados.perfil,
      ativo: true,
      statusAprovacao: 'aprovado',
      trocaSenhaObrigatoria: true,
      criadoEm: agora,
      criadoPorUid: dados.admin!.uid,
    );

    try {
      await usersRepo.setProfile(novoPerfil);
    } catch (e) {
      await conta.desfazer().catchError((_) {});
      final autor = autorAuditoria(dados.admin!);
      await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
        usuarioUid: autor.usuarioUid,
        usuarioNome: autor.usuarioNome,
        usuarioEmail: autor.usuarioEmail,
        usuarioPerfil: autor.usuarioPerfil,
        acao: AuditLogAcoes.criacaoUsuario,
        categoria: AuditLogCategorias.usuarios,
        resultado: 'falha',
        acaoDescricao: 'Falha ao gravar perfil no banco de dados',
        tipoEntidade: 'usuario',
        entidadeId: conta.uid,
        entidadeNome: nomeLimpo,
        conteudo: {'email': emailNormalizado, 'erro': e.toString()},
      ));
      rethrow;
    } finally {
      await conta.finalizar().catchError((_) {});
    }

    final autor = autorAuditoria(dados.admin!);
    await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
      usuarioUid: autor.usuarioUid,
      usuarioNome: autor.usuarioNome,
      usuarioEmail: autor.usuarioEmail,
      usuarioPerfil: autor.usuarioPerfil,
      acao: AuditLogAcoes.criacaoUsuario,
      categoria: AuditLogCategorias.usuarios,
      acaoDescricao: 'Criou conta para $nomeLimpo com o cargo ${rolesConfig[dados.perfil]!.titulo}',
      tipoEntidade: 'usuario',
      entidadeId: conta.uid,
      entidadeNome: nomeLimpo,
      conteudo: {
        'email': emailNormalizado,
        'perfil': dados.perfil,
        'trocaSenhaObrigatoria': true,
      },
    ));

    return ContaCriada(perfil: novoPerfil, senhaTemporaria: senhaTemporaria);
  }
}

