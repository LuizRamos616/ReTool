typedef AuditLogAcao = String;
typedef AuditLogCategoria = String;
typedef AuditLogResultado = String;
typedef AuditLogTipoEntidade = String;

class AuditLogAcoes {
  static const String criacao = 'criacao';
  static const String edicao = 'edicao';
  static const String exclusao = 'exclusao';
  static const String transicao = 'transicao';
  static const String importacao = 'importacao';
  static const String aprovacao = 'aprovacao';
  static const String rejeicao = 'rejeicao';
  static const String alteracaoPerfil = 'alteracao_perfil';
  static const String bloqueioUsuario = 'bloqueio_usuario';
  static const String desbloqueioUsuario = 'desbloqueio_usuario';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String cadastro = 'cadastro';
  static const String aprovacaoUsuario = 'aprovacao_usuario';
  static const String rejeicaoUsuario = 'rejeicao_usuario';
  static const String criacaoUsuario = 'criacao_usuario';
  static const String trocaSenha = 'troca_senha';
  static const String redefinicaoSenha = 'redefinicao_senha';
  static const String solicitacaoCargo = 'solicitacao_cargo';
  static const String aprovacaoCargo = 'aprovacao_cargo';
  static const String rejeicaoCargo = 'rejeicao_cargo';
}

class AuditLogCategorias {
  static const String autenticacao = 'autenticacao';
  static const String usuarios = 'usuarios';
  static const String dados = 'dados';
  static const String fluxo = 'fluxo';
}

const Map<String, List<String>> acoesPorCategoria = {
  AuditLogCategorias.autenticacao: [
    AuditLogAcoes.login,
    AuditLogAcoes.logout,
    AuditLogAcoes.cadastro,
    AuditLogAcoes.trocaSenha,
  ],
  AuditLogCategorias.usuarios: [
    AuditLogAcoes.aprovacaoUsuario,
    AuditLogAcoes.rejeicaoUsuario,
    AuditLogAcoes.criacaoUsuario,
    AuditLogAcoes.redefinicaoSenha,
    AuditLogAcoes.alteracaoPerfil,
    AuditLogAcoes.bloqueioUsuario,
    AuditLogAcoes.desbloqueioUsuario,
    AuditLogAcoes.solicitacaoCargo,
    AuditLogAcoes.aprovacaoCargo,
    AuditLogAcoes.rejeicaoCargo,
  ],
  AuditLogCategorias.dados: [
    AuditLogAcoes.criacao,
    AuditLogAcoes.edicao,
    AuditLogAcoes.exclusao,
    AuditLogAcoes.importacao,
  ],
  AuditLogCategorias.fluxo: [
    AuditLogAcoes.transicao,
    AuditLogAcoes.aprovacao,
    AuditLogAcoes.rejeicao,
  ],
};

const Map<String, String> rotuloCategoria = {
  AuditLogCategorias.autenticacao: 'Autenticação',
  AuditLogCategorias.usuarios: 'Usuários e cargos',
  AuditLogCategorias.dados: 'Alteração de dados',
  AuditLogCategorias.fluxo: 'Fluxo de reutilização',
};

const Map<String, String> rotuloAcao = {
  AuditLogAcoes.criacao: 'Criação',
  AuditLogAcoes.edicao: 'Edição',
  AuditLogAcoes.exclusao: 'Exclusão',
  AuditLogAcoes.transicao: 'Transição de fluxo',
  AuditLogAcoes.importacao: 'Importação',
  AuditLogAcoes.aprovacao: 'Aprovação',
  AuditLogAcoes.rejeicao: 'Rejeição',
  AuditLogAcoes.alteracaoPerfil: 'Alteração de cargo',
  AuditLogAcoes.bloqueioUsuario: 'Bloqueio de usuário',
  AuditLogAcoes.desbloqueioUsuario: 'Desbloqueio de usuário',
  AuditLogAcoes.login: 'Login',
  AuditLogAcoes.logout: 'Logout',
  AuditLogAcoes.cadastro: 'Cadastro',
  AuditLogAcoes.aprovacaoUsuario: 'Aprovação de usuário',
  AuditLogAcoes.rejeicaoUsuario: 'Rejeição de usuário',
  AuditLogAcoes.criacaoUsuario: 'Criação de usuário',
  AuditLogAcoes.trocaSenha: 'Troca de senha',
  AuditLogAcoes.redefinicaoSenha: 'Redefinição de senha',
  AuditLogAcoes.solicitacaoCargo: 'Solicitação de cargo',
  AuditLogAcoes.aprovacaoCargo: 'Aprovação de cargo',
  AuditLogAcoes.rejeicaoCargo: 'Rejeição de cargo',
};

const Map<String, String> rotuloTipoEntidade = {
  'dispositivo': 'Dispositivo',
  'categoria': 'Categoria',
  'tipo': 'Tipo',
  'familia': 'Família',
  'produto': 'Produto',
  'reutilizacao': 'Reutilização',
  'usuario': 'Usuário',
  'solicitacao_cargo': 'Solicitação de cargo',
  'sessao': 'Sessão',
};

String categoriaDaAcao(String acao) {
  for (final entry in acoesPorCategoria.entries) {
    if (entry.value.contains(acao)) {
      return entry.key;
    }
  }
  return AuditLogCategorias.dados;
}

const List<String> palavrasSensiveis = [
  'senha',
  'password',
  'passwd',
  'pwd',
  'token',
  'secret',
  'segredo',
  'hash',
  'credential',
  'credencial',
];

const List<String> termosSensiveis = [
  'password',
  'passwd',
  'apikey',
  'privatekey',
  'credential',
  'credencial',
  'segredo',
];

List<String> _palavrasDoCampo(String campo) {
  return campo
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .split(RegExp(r'[\s_\-.]+'))
      .map((p) => p.toLowerCase())
      .where((p) => p.isNotEmpty)
      .toList();
}

bool campoEhSensivel(String campo) {
  final c = campo.toLowerCase();
  for (final termo in termosSensiveis) {
    if (c.contains(termo)) return true;
  }
  final palavras = _palavrasDoCampo(campo);
  for (final p in palavras) {
    if (palavrasSensiveis.contains(p)) return true;
  }
  return false;
}

Map<String, dynamic>? sanitizarDadosAuditoria(Map<String, dynamic>? dados) {
  if (dados == null) return null;
  final out = <String, dynamic>{};
  for (final entry in dados.entries) {
    final chave = entry.key;
    final valor = entry.value;
    if (campoEhSensivel(chave)) continue;
    if (valor is Map<String, dynamic>) {
      out[chave] = sanitizarDadosAuditoria(valor);
    } else if (valor is List) {
      out[chave] = valor.map((item) {
        if (item is Map<String, dynamic>) {
          return sanitizarDadosAuditoria(item);
        }
        return item;
      }).toList();
    } else {
      out[chave] = valor;
    }
  }
  return out;
}

class AuditLog {
  final String id;
  final String dataHora;
  final String? dataHoraServidor;
  final String usuarioUid;
  final String usuarioNome;
  final String usuarioEmail;
  final String usuarioPerfil;
  final String acao;
  final String categoria;
  final String resultado;
  final String? acaoDescricao;
  final String tipoEntidade;
  final String entidadeId;
  final String? entidadeNome;
  final String? detalhes;
  final Map<String, dynamic>? conteudo;
  final Map<String, dynamic>? dadosAnteriores;

  const AuditLog({
    required this.id,
    required this.dataHora,
    this.dataHoraServidor,
    required this.usuarioUid,
    required this.usuarioNome,
    required this.usuarioEmail,
    required this.usuarioPerfil,
    required this.acao,
    required this.categoria,
    this.resultado = 'sucesso',
    this.acaoDescricao,
    required this.tipoEntidade,
    required this.entidadeId,
    this.entidadeNome,
    this.detalhes,
    this.conteudo,
    this.dadosAnteriores,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dataHora': dataHora,
      if (dataHoraServidor != null) 'dataHoraServidor': dataHoraServidor,
      'usuarioUid': usuarioUid,
      'usuarioNome': usuarioNome,
      'usuarioEmail': usuarioEmail,
      'usuarioPerfil': usuarioPerfil,
      'acao': acao,
      'categoria': categoria,
      'resultado': resultado,
      if (acaoDescricao != null) 'acaoDescricao': acaoDescricao,
      'tipoEntidade': tipoEntidade,
      'entidadeId': entidadeId,
      if (entidadeNome != null) 'entidadeNome': entidadeNome,
      if (detalhes != null) 'detalhes': detalhes,
      if (conteudo != null) 'conteudo': sanitizarDadosAuditoria(conteudo),
      if (dadosAnteriores != null) 'dadosAnteriores': sanitizarDadosAuditoria(dadosAnteriores),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map, [String? id]) {
    final acao = map['acao'] as String? ?? 'criacao';
    final categoria = map['categoria'] as String? ?? categoriaDaAcao(acao);
    return AuditLog(
      id: id ?? (map['id'] as String? ?? ''),
      dataHora: map['dataHora'] as String? ?? '',
      dataHoraServidor: map['dataHoraServidor'] as String?,
      usuarioUid: map['usuarioUid'] as String? ?? '',
      usuarioNome: map['usuarioNome'] as String? ?? '',
      usuarioEmail: map['usuarioEmail'] as String? ?? '',
      usuarioPerfil: map['usuarioPerfil'] as String? ?? 'convidado',
      acao: acao,
      categoria: categoria,
      resultado: map['resultado'] as String? ?? 'sucesso',
      acaoDescricao: map['acaoDescricao'] as String? ?? rotuloAcao[acao],
      tipoEntidade: map['tipoEntidade'] as String? ?? 'dispositivo',
      entidadeId: map['entidadeId'] as String? ?? '',
      entidadeNome: map['entidadeNome'] as String?,
      detalhes: map['detalhes'] as String?,
      conteudo: map['conteudo'] is Map ? Map<String, dynamic>.from(map['conteudo'] as Map) : null,
      dadosAnteriores:
          map['dadosAnteriores'] is Map ? Map<String, dynamic>.from(map['dadosAnteriores'] as Map) : null,
    );
  }
}

