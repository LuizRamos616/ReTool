/// Cargos operacionais — os únicos que a Administração pode atribuir.
typedef UserRole = String;

class UserRoles {
  static const String admin = 'admin';
  static const String projetista = 'projetista';
  static const String engenharia = 'engenharia';
  static const String gerencia = 'gerencia';
  static const String convidado = 'convidado';

  static const List<String> operacionais = [admin, projetista, engenharia, gerencia];
}

class RoleConfig {
  final String id;
  final String titulo;
  final String tituloCurto;
  final String descricao;
  final String badgeBg;
  final String badgeText;
  final String borderColor;
  final String iconColor;
  final bool canConsultar;
  final bool canCadastrar;
  final bool canEditar;
  final bool canExcluir;
  final bool canAprovar;
  final bool canSolicitar;
  final bool canGerenciarUsuarios;
  final bool canVerLogs;

  const RoleConfig({
    required this.id,
    required this.titulo,
    required this.tituloCurto,
    required this.descricao,
    required this.badgeBg,
    required this.badgeText,
    required this.borderColor,
    required this.iconColor,
    required this.canConsultar,
    required this.canCadastrar,
    required this.canEditar,
    required this.canExcluir,
    required this.canAprovar,
    required this.canSolicitar,
    required this.canGerenciarUsuarios,
    required this.canVerLogs,
  });
}

const Map<String, RoleConfig> rolesConfig = {
  'admin': RoleConfig(
    id: 'admin',
    titulo: 'Programadora / Administradora',
    tituloCurto: 'Administração',
    descricao:
        'Responsável pelo sistema: cria e bloqueia usuários, define perfis de acesso, cadastra, edita e exclui registros, aprova solicitações e administra permissões. Todas as exclusões são registradas em histórico/log.',
    badgeBg: '#f3e8ff',
    badgeText: '#6b21a8',
    borderColor: '#a855f7',
    iconColor: '#7c3aed',
    canConsultar: true,
    canCadastrar: true,
    canEditar: true,
    canExcluir: true,
    canAprovar: true,
    canSolicitar: true,
    canGerenciarUsuarios: true,
    canVerLogs: true,
  ),
  'projetista': RoleConfig(
    id: 'projetista',
    titulo: 'Projetista – Ferramentaria',
    tituloCurto: 'Projetista',
    descricao:
        'Atua na análise e aprovação das solicitações: consulta dispositivos e projetos, cadastra e edita informações, aprova solicitações de reutilização e atualiza status e andamento. Não pode excluir registros.',
    badgeBg: '#dcfce7',
    badgeText: '#15803d',
    borderColor: '#22c55e',
    iconColor: '#16a34a',
    canConsultar: true,
    canCadastrar: true,
    canEditar: true,
    canExcluir: false,
    canAprovar: true,
    canSolicitar: true,
    canGerenciarUsuarios: false,
    canVerLogs: false,
  ),
  'engenharia': RoleConfig(
    id: 'engenharia',
    titulo: 'Engenharia de Processo / Industrial',
    tituloCurto: 'Engenharia',
    descricao:
        'Faz a consulta e solicita reutilização de dispositivos: consulta dispositivos existentes, verifica possibilidade de reutilização, solicita reutilização e acompanha o status da solicitação. Não pode cadastrar, editar ou excluir registros.',
    badgeBg: '#ffedd5',
    badgeText: '#c2410c',
    borderColor: '#f97316',
    iconColor: '#ea580c',
    canConsultar: true,
    canCadastrar: false,
    canEditar: false,
    canExcluir: false,
    canAprovar: false,
    canSolicitar: true,
    canGerenciarUsuarios: false,
    canVerLogs: false,
  ),
  'gerencia': RoleConfig(
    id: 'gerencia',
    titulo: 'Gerência',
    tituloCurto: 'Gerência',
    descricao:
        'Acompanha e consulta as informações do sistema: consulta projetos, dispositivos e reutilizações, acompanha indicadores e resultados e visualiza histórico e movimentações. Não pode cadastrar, editar, excluir ou aprovar.',
    badgeBg: '#dbeafe',
    badgeText: '#1e40af',
    borderColor: '#3b82f6',
    iconColor: '#2563eb',
    canConsultar: true,
    canCadastrar: false,
    canEditar: false,
    canExcluir: false,
    canAprovar: false,
    canSolicitar: false,
    canGerenciarUsuarios: false,
    canVerLogs: false,
  ),
};

const RoleConfig convidadoConfig = RoleConfig(
  id: 'convidado',
  titulo: 'Convidado',
  tituloCurto: 'Convidado',
  descricao:
      'Cadastro realizado pelo próprio colaborador e aguardando a análise da Administração. Não consulta nem altera dados até que um cargo seja definido na aprovação.',
  badgeBg: '#f3f4f6',
  badgeText: '#4b5563',
  borderColor: '#9ca3af',
  iconColor: '#6b7280',
  canConsultar: false,
  canCadastrar: false,
  canEditar: false,
  canExcluir: false,
  canAprovar: false,
  canSolicitar: false,
  canGerenciarUsuarios: false,
  canVerLogs: false,
);

const List<String> perfisAtribuiveis = UserRoles.operacionais;

bool isPerfilAtribuivel(String? perfil) {
  return perfil != null && perfisAtribuiveis.contains(perfil);
}

RoleConfig configDoPerfil(String? perfil) {
  if (isPerfilAtribuivel(perfil)) {
    return rolesConfig[perfil]!;
  }
  return convidadoConfig;
}

class UserProfile {
  final String uid;
  final String email;
  final String nome;
  final String perfil;
  final bool ativo;
  final String? criadoEm;
  final String? atualizadoEm;
  final String? statusAprovacao;
  final bool? trocaSenhaObrigatoria;
  final String? senhaAlteradaEm;
  final String? senhaRedefinidaEm;
  final String? senhaRedefinidaPorUid;
  final String? criadoPorUid;
  final String? aprovadoPorUid;
  final String? aprovadoEm;
  final String? rejeitadoPorUid;
  final String? rejeitadoEm;
  final String? motivoRejeicao;
  final String? perfilSolicitado;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.nome,
    required this.perfil,
    required this.ativo,
    this.criadoEm,
    this.atualizadoEm,
    this.statusAprovacao,
    this.trocaSenhaObrigatoria,
    this.senhaAlteradaEm,
    this.senhaRedefinidaEm,
    this.senhaRedefinidaPorUid,
    this.criadoPorUid,
    this.aprovadoPorUid,
    this.aprovadoEm,
    this.rejeitadoPorUid,
    this.rejeitadoEm,
    this.motivoRejeicao,
    this.perfilSolicitado,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? nome,
    String? perfil,
    bool? ativo,
    String? criadoEm,
    String? atualizadoEm,
    String? statusAprovacao,
    bool? trocaSenhaObrigatoria,
    String? senhaAlteradaEm,
    String? senhaRedefinidaEm,
    String? senhaRedefinidaPorUid,
    String? criadoPorUid,
    String? aprovadoPorUid,
    String? aprovadoEm,
    String? rejeitadoPorUid,
    String? rejeitadoEm,
    String? motivoRejeicao,
    String? perfilSolicitado,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      perfil: perfil ?? this.perfil,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      statusAprovacao: statusAprovacao ?? this.statusAprovacao,
      trocaSenhaObrigatoria: trocaSenhaObrigatoria ?? this.trocaSenhaObrigatoria,
      senhaAlteradaEm: senhaAlteradaEm ?? this.senhaAlteradaEm,
      senhaRedefinidaEm: senhaRedefinidaEm ?? this.senhaRedefinidaEm,
      senhaRedefinidaPorUid: senhaRedefinidaPorUid ?? this.senhaRedefinidaPorUid,
      criadoPorUid: criadoPorUid ?? this.criadoPorUid,
      aprovadoPorUid: aprovadoPorUid ?? this.aprovadoPorUid,
      aprovadoEm: aprovadoEm ?? this.aprovadoEm,
      rejeitadoPorUid: rejeitadoPorUid ?? this.rejeitadoPorUid,
      rejeitadoEm: rejeitadoEm ?? this.rejeitadoEm,
      motivoRejeicao: motivoRejeicao ?? this.motivoRejeicao,
      perfilSolicitado: perfilSolicitado ?? this.perfilSolicitado,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nome': nome,
      'perfil': perfil,
      'ativo': ativo,
      if (criadoEm != null) 'criadoEm': criadoEm,
      if (atualizadoEm != null) 'atualizadoEm': atualizadoEm,
      if (statusAprovacao != null) 'statusAprovacao': statusAprovacao,
      if (trocaSenhaObrigatoria != null) 'trocaSenhaObrigatoria': trocaSenhaObrigatoria,
      if (senhaAlteradaEm != null) 'senhaAlteradaEm': senhaAlteradaEm,
      if (senhaRedefinidaEm != null) 'senhaRedefinidaEm': senhaRedefinidaEm,
      if (senhaRedefinidaPorUid != null) 'senhaRedefinidaPorUid': senhaRedefinidaPorUid,
      if (criadoPorUid != null) 'criadoPorUid': criadoPorUid,
      if (aprovadoPorUid != null) 'aprovadoPorUid': aprovadoPorUid,
      if (aprovadoEm != null) 'aprovadoEm': aprovadoEm,
      if (rejeitadoPorUid != null) 'rejeitadoPorUid': rejeitadoPorUid,
      if (rejeitadoEm != null) 'rejeitadoEm': rejeitadoEm,
      if (motivoRejeicao != null) 'motivoRejeicao': motivoRejeicao,
      if (perfilSolicitado != null) 'perfilSolicitado': perfilSolicitado,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserProfile(
      uid: id ?? (map['uid'] as String? ?? ''),
      email: map['email'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      perfil: map['perfil'] as String? ?? 'convidado',
      ativo: map['ativo'] as bool? ?? false,
      criadoEm: map['criadoEm'] as String?,
      atualizadoEm: map['atualizadoEm'] as String?,
      statusAprovacao: map['statusAprovacao'] as String?,
      trocaSenhaObrigatoria: map['trocaSenhaObrigatoria'] as bool?,
      senhaAlteradaEm: map['senhaAlteradaEm'] as String?,
      senhaRedefinidaEm: map['senhaRedefinidaEm'] as String?,
      senhaRedefinidaPorUid: map['senhaRedefinidaPorUid'] as String?,
      criadoPorUid: map['criadoPorUid'] as String?,
      aprovadoPorUid: map['aprovadoPorUid'] as String?,
      aprovadoEm: map['aprovadoEm'] as String?,
      rejeitadoPorUid: map['rejeitadoPorUid'] as String?,
      rejeitadoEm: map['rejeitadoEm'] as String?,
      motivoRejeicao: map['motivoRejeicao'] as String?,
      perfilSolicitado: map['perfilSolicitado'] as String?,
    );
  }
}

/// Situação de acesso derivada do perfil persistido.
enum SituacaoUsuario { pendente, ativo, bloqueado, rejeitado }

SituacaoUsuario situacaoDoUsuario(UserProfile u) {
  if (u.statusAprovacao == 'rejeitado') return SituacaoUsuario.rejeitado;
  if (u.statusAprovacao == 'pendente') return SituacaoUsuario.pendente;
  if (u.ativo) {
    return isPerfilAtribuivel(u.perfil) ? SituacaoUsuario.ativo : SituacaoUsuario.pendente;
  }
  // Legado: o autocadastro antigo gravava `perfilSolicitado` numa conta Gerência inativa.
  if (u.statusAprovacao == null && u.perfil == 'gerencia' && u.perfilSolicitado != null) {
    return SituacaoUsuario.pendente;
  }
  return SituacaoUsuario.bloqueado;
}

bool isContaOperacional(UserProfile? u) {
  if (u == null) return false;
  return situacaoDoUsuario(u) == SituacaoUsuario.ativo && u.trocaSenhaObrigatoria != true;
}

bool podeManterSessao(UserProfile? u) {
  if (u == null) return false;
  final situacao = situacaoDoUsuario(u);
  return situacao == SituacaoUsuario.ativo || situacao == SituacaoUsuario.pendente;
}

enum TelaDaSessao { login, aguardandoAprovacao, trocaSenha, sistema }

TelaDaSessao telaDaSessao(UserProfile? u) {
  if (!podeManterSessao(u)) return TelaDaSessao.login;
  if (situacaoDoUsuario(u!) == SituacaoUsuario.pendente) return TelaDaSessao.aguardandoAprovacao;
  if (u.trocaSenhaObrigatoria == true) return TelaDaSessao.trocaSenha;
  return TelaDaSessao.sistema;
}

bool isAdministrador(UserProfile? u) {
  return isContaOperacional(u) && u!.perfil == 'admin';
}

String mensagemAcessoNegado(UserProfile u) {
  if (situacaoDoUsuario(u) == SituacaoUsuario.rejeitado) {
    final motivo = u.motivoRejeicao != null && u.motivoRejeicao!.isNotEmpty ? ' Motivo: ${u.motivoRejeicao}' : '';
    return 'Sua solicitação de cadastro foi recusada pela Administração.$motivo';
  }
  return 'Este usuário foi desativado pela Administradora. Contate o suporte.';
}

