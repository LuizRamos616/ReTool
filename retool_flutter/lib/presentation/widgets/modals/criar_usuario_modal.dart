import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retool_provider.dart';
import '../../../domain/entities/user.dart';
import '../../../core/theme/app_colors.dart';
import 'accessible_modal.dart';

class CriarUsuarioModal extends ConsumerStatefulWidget {
  const CriarUsuarioModal({super.key});

  @override
  ConsumerState<CriarUsuarioModal> createState() => _CriarUsuarioModalState();
}

class _CriarUsuarioModalState extends ConsumerState<CriarUsuarioModal> {
  final TextEditingController _nomeCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  String _perfilSelecionado = UserRoles.engenharia;

  bool _loading = false;
  String? _erro;
  String? _senhaGerada;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    setState(() {
      _erro = null;
      _loading = true;
    });

    try {
      final res = await ref.read(authProvider.notifier).criarContaComSenhaTemporaria(
            _nomeCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _perfilSelecionado,
          );
      setState(() {
        _loading = false;
        _senhaGerada = res.senhaTemporaria;
      });
      ref.read(reToolProvider.notifier).showToast('Conta criada com sucesso!');
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '').replaceFirst('ErroValidacao: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_senhaGerada != null) {
      return AccessibleModal(
        title: 'Conta Criada com Sucesso!',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A conta foi criada com senha temporária. O usuário deverá alterá-la no primeiro acesso.',
              style: TextStyle(fontSize: 13, color: AppColors.textBody),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray03,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Senha temporária gerada:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        _senhaGerada!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Copiar senha',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _senhaGerada!));
                          ref.read(reToolProvider.notifier).showToast('Senha copiada para a área de transferência!');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Atenção: esta senha só será exibida esta única vez. Repasse-a com segurança ao colaborador.',
              style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Concluir'),
          ),
        ],
      );
    }

    return AccessibleModal(
      title: 'Criar Novo Usuário',
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
          const Text('Nome completo:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(hintText: 'Ex: Maria Silva'),
          ),
          const SizedBox(height: 16),
          const Text('E-mail institucional:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'maria.silva@empresa.com'),
          ),
          const SizedBox(height: 16),
          const Text('Cargo a atribuir:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _perfilSelecionado,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: UserRoles.operacionais.map((r) {
              return DropdownMenuItem(value: r, child: Text(rolesConfig[r]!.titulo));
            }).toList(),
            onChanged: (v) => setState(() => _perfilSelecionado = v!),
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
          onPressed: _loading ? null : _criar,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Criar conta'),
        ),
      ],
    );
  }
}

