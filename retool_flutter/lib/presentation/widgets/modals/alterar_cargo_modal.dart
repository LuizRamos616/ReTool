import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retool_provider.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/solicitacao_cargo.dart';
import '../../../core/theme/app_colors.dart';
import 'accessible_modal.dart';

class AlterarCargoModal extends ConsumerStatefulWidget {
  const AlterarCargoModal({super.key});

  @override
  ConsumerState<AlterarCargoModal> createState() => _AlterarCargoModalState();
}

class _AlterarCargoModalState extends ConsumerState<AlterarCargoModal> {
  String? _perfilSelecionado;
  final TextEditingController _justificativaCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _justificativaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    setState(() {
      _erro = null;
      _loading = true;
    });

    try {
      if (_perfilSelecionado == null) {
        throw 'Selecione o cargo desejado.';
      }
      await ref.read(authProvider.notifier).solicitarAlteracaoCargo(
            _perfilSelecionado!,
            _justificativaCtrl.text.trim(),
          );
      ref.read(reToolProvider.notifier).showToast('Solicitação de alteração de cargo enviada!');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('ErroValidacao: ', '').replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.userProfile;
    final cargosDisponiveis = UserRoles.operacionais.where((r) => r != user?.perfil).toList();

    return AccessibleModal(
      title: 'Solicitar Alteração de Cargo',
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
          const Text('Cargo atual:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            auth.roleConfig.titulo,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          const Text('Novo cargo pretendido:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _perfilSelecionado,
            hint: const Text('Selecione um cargo'),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: cargosDisponiveis.map((c) {
              final conf = rolesConfig[c]!;
              return DropdownMenuItem(value: c, child: Text(conf.titulo));
            }).toList(),
            onChanged: (v) => setState(() => _perfilSelecionado = v),
          ),
          const SizedBox(height: 16),
          const Text('Justificativa:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _justificativaCtrl,
            maxLines: 4,
            maxLength: justificativaMax,
            decoration: const InputDecoration(
              hintText: 'Explique o motivo da alteração de cargo...',
            ),
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
          onPressed: _loading ? null : _submeter,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enviar solicitação'),
        ),
      ],
    );
  }
}

