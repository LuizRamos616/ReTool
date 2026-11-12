import '../entities/reutilizacao.dart';

abstract class IReutilizacoesRepository {
  Future<String> add(Reutilizacao reutilizacao);
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<Reutilizacao?> getById(String id);
  Future<List<Reutilizacao>> listarPorDispositivo(String dispositivoId);
  Future<List<Reutilizacao>> listarTodas();
  Stream<List<Reutilizacao>> watchReutilizacoes();
}

