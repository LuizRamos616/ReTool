import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retool_provider.dart';
import '../../../domain/entities/reutilizacao.dart';
import '../../../core/utils/moeda.dart';
import '../../../core/theme/app_colors.dart';
import 'accessible_modal.dart';

class TransicionarReutilizacaoModal extends ConsumerStatefulWidget {
  final Reutilizacao reutilizacao;
  const TransicionarReutilizacaoModal({super.key, required this.reutilizacao});

  @override
  ConsumerState<TransicionarReutilizacaoModal> createState() => _TransicionarReutilizacaoModalState();
}

class _TransicionarReutilizacaoModalState extends ConsumerState<TransicionarReutilizacaoModal> {
  String? _novoStatus;
  final TextEditingController _motivoCtrl = TextEditingController();
  final TextEditingController _numeroOsCtrl = TextEditingController();
  final TextEditingController _hardSavingCtrl = TextEditingController();

  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _numeroOsCtrl.text = widget.reutilizacao.numeroOs;
    _hardSavingCtrl.text = widget.reutilizacao.hardSaving > 0
        ? formatarMoeda(widget.reutilizacao.hardSaving).replaceAll('R\$', '').trim()
        : '';
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _numeroOsCtrl.dispose();
    _hardSavingCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() {
      _erro = null;
      _loading = true;
    });

    try {
      if (_novoStatus == null) throw 'Selecione a nova etapa.';
      if (_novoStatus == ReutilizacaoStatuses.reutilizacaoNaoAprovada && _motivoCtrl.text.trim().isEmpty) {
        throw 'Informe o motivo da não aprovação.';
      }

      final auth = ref.read(authProvider);
      final hs = lerValorMonetario(_hardSavingCtrl.text);
      if (hs != null && hs > 0) {
        await ref.read(reToolProvider.notifier).definirHardSaving(widget.reutilizacao.id, hs);
      }

      await ref.read(reToolProvider.notifier).transicionarReutilizacao(
            widget.reutilizacao.id,
            _novoStatus!,
            motivo: _motivoCtrl.text.trim().isNotEmpty ? _motivoCtrl.text.trim() : null,
            numeroOs: _numeroOsCtrl.text.trim().isNotEmpty ? _numeroOsCtrl.text.trim() : null,
            aprovadorId: auth.userProfile?.uid,
            aprovadorNome: auth.userProfile?.nome,
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final statusAtual = normalizarStatusReutilizacao(widget.reutilizacao.status);
    final transicoes = transicoesReutilizacao[auth.currentRole]?[statusAtual] ?? [];

    return AccessibleModal(
      title: 'Atualizar Etapa do Fluxo',
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

          const Text('Status atual:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gray03,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusAtual,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Selecione a próxima etapa:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          if (transicoes.isEmpty)
            const Text(
              'Nenhuma transição permitida para seu cargo no status atual.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            )
          else
            DropdownButtonFormField<String>(
              value: _novoStatus,
              hint: const Text('Selecione a nova etapa'),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: transicoes.map((s) {
                return DropdownMenuItem(value: s, child: Text(rotuloCurtoStatusReutilizacao(s)));
              }).toList(),
              onChanged: (v) => setState(() => _novoStatus = v),
            ),
          const SizedBox(height: 16),

          if (_novoStatus == ReutilizacaoStatuses.reutilizacaoAprovada && auth.currentRole != 'engenharia') ...[
            const Text('Hard Saving (R\$):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(controller: _hardSavingCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
          ],

          if (_novoStatus == ReutilizacaoStatuses.reutilizacaoNaoAprovada) ...[
            const Text('Motivo da Não Aprovação *:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _motivoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Explique o motivo técnico...'),
            ),
            const SizedBox(height: 16),
          ],

          const Text('Número da O.S.:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(controller: _numeroOsCtrl),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: (_loading || transicoes.isEmpty) ? null : _confirmar,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar transição'),
        ),
      ],
    );
  }
}

