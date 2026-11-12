import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isRegistering = false;
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final TextEditingController _nomeCtrl = TextEditingController();

  bool _loading = false;
  String? _erro;
  String? _sucesso;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    setState(() {
      _erro = null;
      _sucesso = null;
      _loading = true;
    });

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      if (_isRegistering) {
        if (_nomeCtrl.text.trim().isEmpty) throw 'Informe seu nome completo.';
        if (password.length < 6) throw 'A senha deve conter no mínimo 6 caracteres.';
        if (password != _confirmPasswordCtrl.text) throw 'As senhas não coincidem.';

        await ref.read(authProvider.notifier).register(email, password, _nomeCtrl.text.trim());
      } else {
        await ref.read(authProvider.notifier).login(email, password);
      }
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
    final isWide = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 960),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: isWide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildBannerInstitucional()),
                        Expanded(child: _buildFormulario()),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _buildBannerInstitucional(compacto: true),
                      _buildFormulario(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerInstitucional({bool compacto = false}) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.all(compacto ? 24 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                  children: [
                    TextSpan(text: 'Re', style: TextStyle(color: Colors.white70)),
                    TextSpan(text: 'Tool', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gestão de Dispositivos e Reutilização Industrial',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Parceria entre Fatec Matão e Baldan. Centralize informações, rastreie reutilizações e mantenha o chão de fábrica integrado.',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
              ),
            ],
          ),
          if (!compacto) ...[
            const SizedBox(height: 32),
            Column(
              children: const [
                _RoleItem(cargo: 'Administração', desc: 'Controle total, aprovações e auditoria.'),
                SizedBox(height: 12),
                _RoleItem(cargo: 'Projetista', desc: 'Análise técnica, aprovação e hard saving.'),
                SizedBox(height: 12),
                _RoleItem(cargo: 'Engenharia', desc: 'Consulta e solicitações de reutilização.'),
                SizedBox(height: 12),
                _RoleItem(cargo: 'Gerência', desc: 'Visualização de relatórios e indicadores.'),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Fatec Matão "Luiz Marchesan"',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TabButton(
                titulo: 'Entrar',
                selecionado: !_isRegistering,
                onTap: () => setState(() {
                  _isRegistering = false;
                  _erro = null;
                }),
              ),
              const SizedBox(width: 12),
              _TabButton(
                titulo: 'Criar conta',
                selecionado: _isRegistering,
                onTap: () => setState(() {
                  _isRegistering = true;
                  _erro = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_erro != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red03.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.danger.withOpacity(0.4)),
              ),
              child: Text(_erro!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),

          if (_isRegistering) ...[
            const Text('Nome completo:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(controller: _nomeCtrl, decoration: const InputDecoration(hintText: 'Ex: Carlos Silva')),
            const SizedBox(height: 16),
          ],

          const Text('E-mail institucional:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'seu.email@empresa.com'),
          ),
          const SizedBox(height: 16),

          const Text('Senha:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(hintText: '••••••••'),
          ),
          const SizedBox(height: 16),

          if (_isRegistering) ...[
            const Text('Confirme a senha:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: '••••••••'),
            ),
            const SizedBox(height: 8),
            const Text(
              'O autocadastro nasce como Convidado e aguarda aprovação da Administração.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _loading ? null : _submeter,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isRegistering ? 'Cadastrar e aguardar aprovação' : 'Acessar o ReTool'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String titulo;
  final bool selecionado;
  final VoidCallback onTap;

  const _TabButton({required this.titulo, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.gray03 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          titulo,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
            color: selecionado ? AppColors.primary : AppColors.gray01,
          ),
        ),
      ),
    );
  }
}

class _RoleItem extends StatelessWidget {
  final String cargo;
  final String desc;
  const _RoleItem({required this.cargo, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cargo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ],
    );
  }
}

