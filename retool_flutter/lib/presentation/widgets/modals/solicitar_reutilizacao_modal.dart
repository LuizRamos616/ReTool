import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retool_provider.dart';
import '../../../domain/entities/dispositivo.dart';
import '../../../domain/entities/reutilizacao.dart';
import '../../../core/utils/moeda.dart';
import '../../../core/theme/app_colors.dart';
import 'accessible_modal.dart';

class SolicitarReutilizacaoModal extends ConsumerStatefulWidget {
  final Dispositivo? dispositivoPreSelecionado;
  const SolicitarReutilizacaoModal({super.key, this.dispositivoPreSelecionado});

  @override
  ConsumerState<SolicitarReutilizacaoModal> createState() => _SolicitarReutilizacaoModalState();
}

class _SolicitarReutilizacaoModalState extends ConsumerState<SolicitarReutilizacaoModal> {
  late String? _dispositivoId;
  final TextEditingController _codigoPecaCtrl = TextEditingController();
  final TextEditingController _descricaoPecaCtrl = TextEditingController();
  String? _produtoId;
  final TextEditingController _pesoPecaCtrl = TextEditingController();
  final TextEditingController _hardSavingCtrl = TextEditingController();
  final TextEditingController _responsavelCtrl = TextEditingController();
  final TextEditingController _numeroOsCtrl = TextEditingController();
  final TextEditingController _descricaoAlteracaoCtrl = TextEditingController();

  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _dispositivoId = widget.dispositivoPreSelecionado?.id;
    if (widget.dispositivoPreSelecionado != null) {
      _codigoPecaCtrl.text = widget.dispositivoPreSelecionado!.codigo ?? '';
      _descricaoPecaCtrl.text = widget.dispositivoPreSelecionado!.descricao ?? '';
      _produtoId = widget.dispositivoPreSelecionado!.produtoId;
      _pesoPecaCtrl.text = widget.dispositivoPreSelecionado!.peso ?? '';
    }
    final user = ref.read(authProvider).userProfile;
    _responsavelCtrl.text = user?.nome ?? '';
  }

  @override
  void dispose() {
    _codigoPecaCtrl.dispose();
    _descricaoPecaCtrl.dispose();
    _pesoPecaCtrl.dispose();
    _hardSavingCtrl.dispose();
    _responsavelCtrl.dispose();
    _numeroOsCtrl.dispose();
    _descricaoAlteracaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _erro = null;
      _loading = true;
    });

    try {
      if (_dispositivoId == null || _dispositivoId!.isEmpty) {
        throw 'Selecione o dispositivo a ser reutilizado.';
      }
      if (_codigoPecaCtrl.text.trim().isEmpty) throw 'Informe o código da nova peça.';
      if (_descricaoPecaCtrl.text.trim().isEmpty) throw 'Informe a descrição da peça.';
      if (_responsavelCtrl.text.trim().isEmpty) throw 'Informe o responsável.';
      if (_numeroOsCtrl.text.trim().isEmpty) throw 'Informe o número da O.S.';

      final auth = ref.read(authProvider);
      // Engenharia não informa Hard Saving (sempre 0 na solicitação inicial)
      final hardSaving = auth.currentRole == 'engenharia'
          ? 0.0
          : (lerValorMonetario(_hardSavingCtrl.text) ?? 0.0);

      final peso = double.tryParse(_pesoPecaCtrl.text.replaceAll(',', '.')) ?? 0.0;

      final reutilizacao = Reutilizacao(
        id: '',
        dispositivoId: _dispositivoId!,
        data: DateTime.now().toIso8601String().substring(0, 10),
        codigoPeca: _codigoPecaCtrl.text.trim(),
        descricaoPeca: _descricaoPecaCtrl.text.trim(),
        produtoId: _produtoId ?? '',
        pesoPeca: peso,
        hardSaving: hardSaving,
        responsavel: _responsavelCtrl.text.trim(),
        numeroOs: _numeroOsCtrl.text.trim(),
        descricaoAlteracao: _descricaoAlteracaoCtrl.text.trim(),
        status: ReutilizacaoStatuses.analiseProjetista,
        solicitanteId: auth.userProfile?.uid,
        solicitanteNome: auth.userProfile?.nome,
        dataCriacao: DateTime.now().toIso8601String(),
      );

      await ref.read(reToolProvider.notifier).addReutilizacao(reutilizacao);
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
    final state = ref.watch(reToolProvider);
    final auth = ref.watch(authProvider);
    final podeInformarHardSaving = auth.currentRole != 'engenharia';

    return AccessibleModal(
      title: 'Solicitar Reutilização de Dispositivo',
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

          // Dispositivo Base
          const Text('Dispositivo base:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          if (widget.dispositivoPreSelecionado != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gray03,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${widget.dispositivoPreSelecionado!.nome ?? "Sem nome"} - ${widget.dispositivoPreSelecionado!.codigo ?? ""}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: _dispositivoId,
              hint: const Text('Selecione o dispositivo'),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: state.dispositivos.map((d) {
                return DropdownMenuItem(
                  value: d.id,
                  child: Text('${d.nome ?? "Dispositivo"} (${d.codigo ?? ""})'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _dispositivoId = v),
            ),
          const SizedBox(height: 16),

          // Nova Peça
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Código da Peça *:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(controller: _codigoPecaCtrl),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Peso da Peça (kg):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(controller: _pesoPecaCtrl, keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Descrição da Peça *:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(controller: _descricaoPecaCtrl),
          const SizedBox(height: 16),

          // Produto
          const Text('Produto da Aplicação:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _produtoId,
            hint: const Text('Selecione o produto'),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: state.produtos.map((p) {
              return DropdownMenuItem(value: p.id, child: Text(p.nome));
            }).toList(),
            onChanged: (v) => setState(() => _produtoId = v),
          ),
          const SizedBox(height: 16),

          // Responsável e O.S.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Responsável *:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(controller: _responsavelCtrl),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Número da O.S. *:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(controller: _numeroOsCtrl),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (podeInformarHardSaving) ...[
            const Text('Hard Saving Estimado (R\$):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _hardSavingCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Ex: 1.500,00'),
            ),
            const SizedBox(height: 16),
          ],

          const Text('Alterações / Adaptações necessárias:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _descricaoAlteracaoCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Descreva eventuais modificações no dispositivo...'),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _loading ? null : _enviar,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enviar solicitação'),
        ),
      ],
    );
  }
}

