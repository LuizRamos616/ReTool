import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/retool_provider.dart';
import '../../core/theme/app_colors.dart';

class TrocaSenhaObrigatoriaPage extends ConsumerStatefulWidget {
  const TrocaSenhaObrigatoriaPage({super.key});

  @override
  ConsumerState<TrocaSenhaObrigatoriaPage> createState() => _TrocaSenhaObrigatoriaPageState();
}

class _TrocaSenhaObrigatoriaPageState extends ConsumerState<TrocaSenhaObrigatoriaPage> {
  final TextEditingController _senhaAtualCtrl = TextEditingController();
  final TextEditingController _novaSenhaCtrl = TextEditingController();
  final TextEditingController _confirmacaoCtrl = TextEditingController();

  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _trocar() async {
    setState(() {
      _erro = null;
      _loading = true;
    });

    try {
      await ref.read(authProvider.notifier).concluirTrocaSenha(
            _senhaAtualCtrl.text,
            _novaSenhaCtrl.text,
            _confirmacaoCtrl.text,
          );
      ref.read(reToolProvider.notifier).showToast('Senha alterada com sucesso!');
      if (mounted) context.go('/dispositivos');
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '').replaceFirst('ErroValidacao: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0F172A),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, size: 28, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text(
                      'Troca de Senha Obrigatória',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sua conta foi criada com uma senha temporária. Para continuar, defina uma nova senha definitiva.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

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

                const Text('Senha temporária atual:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _senhaAtualCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Senha recebida'),
                ),
                const SizedBox(height: 16),

                const Text('Nova senha definitiva:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _novaSenhaCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Mínimo 8 caracteres com letras e números'),
                ),
                const SizedBox(height: 16),

                const Text('Confirme a nova senha:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Repita a nova senha'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _trocar,
                    child: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Salvar nova senha e entrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextEditingController get _confirmPasswordCtrl => _confirmacaoCtrl;
}

