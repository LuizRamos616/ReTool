import '../../domain/entities/dispositivo.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/familia.dart';
import '../../domain/entities/produto.dart';
import '../../domain/repositories/i_dispositivos_repository.dart';

class ImportarLoteUseCase {
  final IDispositivosRepository dispositivosRepository;

  ImportarLoteUseCase(this.dispositivosRepository);

  Future<ResultadoImportacaoLote> execute(
    List<Dispositivo> novosDispositivos,
    List<String> newCategoriasNomes,
    List<String> newFamiliasNomes,
    List<String> newProdutosNomes,
    List<Categoria> categoriasExistentes,
    List<Familia> familiasExistentes,
    List<Produto> produtosExistentes, [
    OpcoesImportacaoLote? opcoes,
  ]) {
    return dispositivosRepository.importarLote(
      novosDispositivos,
      newCategoriasNomes,
      newFamiliasNomes,
      newProdutosNomes,
      categoriasExistentes,
      familiasExistentes,
      produtosExistentes,
      opcoes,
    );
  }
}

