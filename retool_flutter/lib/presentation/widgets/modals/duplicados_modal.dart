import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/retool_provider.dart';
import '../../../domain/entities/dispositivo.dart';
import '../../../core/theme/app_colors.dart';
import 'accessible_modal.dart';

class DuplicadosModal extends ConsumerStatefulWidget {
  const DuplicadosModal({super.key});

  @override
  ConsumerState<DuplicadosModal> createState() => _DuplicadosModalState();
}

class _DuplicadosModalState extends ConsumerState<DuplicadosModal> {
  PlanoLimpezaDuplicados? _plano;
  bool _executando = false;
  int _removidos = 0;
  String? _sucesso;

  @override
  void initState() {
    super.initState();
    _calcularPlano();
  }

  void _calcularPlano() {
    final state = ref.read(reToolProvider);
    final idsComReutilizacao = state.reutilizacoes.map((r) => r.dispositivoId).toSet();
    final plano = planejarLimpezaDuplicados(state.dispositivos, idsComReutilizacao);
    setState(() => _plano = plano);
  }

  Future<void> _removerDuplicadosSeguros() async {
    if (_plano == null || _plano!.totalRemover == 0) return;
    setState(() => _executando = true);

    final idsParaRemover = _plano!.grupos.expand((g) => g.remover.map((d) => d.id)).toList();
    await ref.read(reToolProvider.notifier).excluirDispositivosEmLote(idsParaRemover);

    setState(() {
      _removidos = idsParaRemover.length;
      _executando = false;
      _sucesso = '$_removidos dispositivo(s) duplicado(s) removido(s) com segurança!';
    });
    _calcularPlano();
  }

  @override
  Widget build(BuildContext context) {
    if (_plano == null) {
      return const AccessibleModal(
        title: 'Verificando Duplicados',
        content: Center(child: CircularProgressIndicator()),
      );
    }

    return AccessibleModal(
      title: 'Limpeza de Dispositivos Duplicados',
      maxWidth: 680,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sucesso != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.success00.withOpacity(0.4)),
              ),
              child: Text(_sucesso!, style: const TextStyle(color: AppColors.success00, fontSize: 13, fontWeight: FontWeight.bold)),
            ),

          const Text(
            'Combinações idênticas de Código + Dispositivo geradas em importações antigas:',
            style: TextStyle(fontSize: 13, color: AppColors.textBody),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray03,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Grupos Repetidos', valor: '${_plano!.grupos.length}'),
                _Stat(label: 'Seguros p/ Remover', valor: '${_plano!.totalRemover}', cor: AppColors.primary),
                _Stat(label: 'Exigem Revisão', valor: '${_plano!.totalRevisar}', cor: AppColors.warning),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_plano!.grupos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Nenhum registro duplicado encontrado na base de dados! 🎉', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            )
          else ...[
            const Text('Exemplos de grupos duplicados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _plano!.grupos.length > 5 ? 5 : _plano!.grupos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final g = _plano!.grupos[index];
                  return ListTile(
                    dense: true,
                    title: Text('${g.nome ?? "Dispositivo"} (${g.codigo ?? "Sem código"})', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Manter: ID ${g.manter.id} | Remover: ${g.remover.length} | Revisar: ${g.revisar.length}'),
                  );
                },
              ),
            ),
          ],
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: _executando ? null : () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        if (_plano!.totalRemover > 0) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: _executando ? null : _removerDuplicadosSeguros,
            child: _executando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Remover ${_plano!.totalRemover} Duplicados'),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String valor;
  final Color? cor;
  const _Stat({required this.label, required this.valor, this.cor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor ?? AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

