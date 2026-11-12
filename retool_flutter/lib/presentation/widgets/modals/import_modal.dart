import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/retool_provider.dart';
import '../../../domain/repositories/i_dispositivos_repository.dart';
import '../../../application/importacao/planilha_dispositivos.dart';
import '../../../core/theme/app_colors.dart';
import 'accessible_modal.dart';

class ImportModal extends ConsumerStatefulWidget {
  const ImportModal({super.key});

  @override
  ConsumerState<ImportModal> createState() => _ImportModalState();
}

class _ImportModalState extends ConsumerState<ImportModal> {
  String? _nomeArquivo;
  List<int>? _arquivoBytes;
  ResultadoProcessamento? _previa;

  bool _processandoArquivo = false;
  bool _gravandoLote = false;
  bool _cancelado = false;
  String _etapa = '';
  int _progressoFeitos = 0;
  int _progressoTotal = 0;
  ResultadoImportacaoLote? _resultadoFinal;
  String? _erro;

  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;

    setState(() {
      _nomeArquivo = file.name;
      _arquivoBytes = file.bytes;
      _processandoArquivo = true;
      _previa = null;
      _erro = null;
      _etapa = 'Analisando planilha...';
    });

    try {
      final abas = lerPlanilhaBytes(_arquivoBytes!, file.name);
      final state = ref.read(reToolProvider);
      final previa = processarPlanilhaDispositivos(
        abas,
        ContextoProcessamento(
          categorias: state.categorias,
          familias: state.familias,
          produtos: state.produtos,
        ),
      );

      setState(() {
        _previa = previa;
        _processandoArquivo = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao processar planilha: $e';
        _processandoArquivo = false;
      });
    }
  }

  Future<void> _iniciarImportacao() async {
    if (_arquivoBytes == null || _nomeArquivo == null) return;
    setState(() {
      _gravandoLote = true;
      _cancelado = false;
      _etapa = 'Iniciando gravação...';
    });

    try {
      final res = await ref.read(reToolProvider.notifier).importarPlanilha(
            fileBytes: _arquivoBytes!,
            fileName: _nomeArquivo!,
            onProgressoGravacao: (p) {
              setState(() {
                _etapa = 'Gravando lote ${p.lote ?? 1}/${p.totalLotes ?? 1}...';
                _progressoFeitos = p.feitos;
                _progressoTotal = p.total;
              });
            },
            cancelado: () => _cancelado,
          );

      setState(() {
        _resultadoFinal = res;
        _gravandoLote = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro na gravação: $e';
        _gravandoLote = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resultadoFinal != null) {
      return AccessibleModal(
        title: 'Importação Concluída',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success01, size: 48),
            const SizedBox(height: 12),
            Text(
              '${_resultadoFinal!.sucesso} registros gravados com sucesso!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _LinhaResumo(label: 'Inseridos:', valor: '${_resultadoFinal!.inseridos ?? 0}'),
            _LinhaResumo(label: 'Atualizados:', valor: '${_resultadoFinal!.atualizados ?? 0}'),
            _LinhaResumo(label: 'Sem alteração (ignorados):', valor: '${_resultadoFinal!.ignoradosSemAlteracao ?? 0}'),
            _LinhaResumo(label: 'Imagens herdadas da linha:', valor: '${_resultadoFinal!.imagensHerdadas ?? 0}'),
            if (_resultadoFinal!.interrompido != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Aviso: Interrompido por ${_resultadoFinal!.interrompido}.',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    }

    return AccessibleModal(
      title: 'Importar Planilha de Dispositivos',
      maxWidth: 650,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_erro != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red03.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Text(_erro!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),

          if (_nomeArquivo == null)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Icon(Icons.table_view_rounded, size: 56, color: AppColors.gray01),
                  const SizedBox(height: 12),
                  const Text('Selecione uma planilha Excel (.xlsx, .xls) ou CSV'),
                  const SizedBox(height: 4),
                  const Text(
                    'Cada combinação única de Código + Dispositivo será importada.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Selecionar arquivo'),
                    onPressed: _selecionarArquivo,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray03,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_nomeArquivo!, style: const TextStyle(fontWeight: FontWeight.w600))),
                  if (!_gravandoLote)
                    TextButton(onPressed: _selecionarArquivo, child: const Text('Trocar')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_processandoArquivo)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Processando dados da planilha...'),
                    ],
                  ),
                ),
              )
            else if (_previa != null) ...[
              const Text('Resumo da Leitura:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _LinhaResumo(label: 'Linhas válidas lidas:', valor: '${_previa!.resumo.linhasLidas}'),
              _LinhaResumo(label: 'Combinações únicas (registros):', valor: '${_previa!.resumo.combinacoesUnicas}'),
              _LinhaResumo(label: 'Linhas duplicadas agrupadas:', valor: '${_previa!.resumo.duplicadasRemovidas}'),
              if (_previa!.resumo.linhasSemChave > 0)
                _LinhaResumo(label: 'Linhas sem código e dispositivo:', valor: '${_previa!.resumo.linhasSemChave}'),
              const SizedBox(height: 8),
              _LinhaResumo(label: 'Novas categorias a criar:', valor: '${_previa!.novasCategorias.length}'),
              _LinhaResumo(label: 'Novas famílias a criar:', valor: '${_previa!.novasFamilias.length}'),
              _LinhaResumo(label: 'Novos produtos a criar:', valor: '${_previa!.novosProdutos.length}'),
            ],

            if (_gravandoLote) ...[
              const SizedBox(height: 20),
              Text(_etapa, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _progressoTotal > 0 ? _progressoFeitos / _progressoTotal : null,
              ),
              const SizedBox(height: 6),
              Text('$_progressoFeitos de $_progressoTotal registros processados', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ],
      ),
      actions: [
        if (_gravandoLote)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => setState(() => _cancelado = true),
            child: const Text('Cancelar importação'),
          )
        else ...[
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          if (_previa != null) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _iniciarImportacao,
              child: const Text('Confirmar e Gravar'),
            ),
          ],
        ],
      ],
    );
  }
}

class _LinhaResumo extends StatelessWidget {
  final String label;
  final String valor;
  const _LinhaResumo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

