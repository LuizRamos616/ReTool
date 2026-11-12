import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/retool_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/dispositivo.dart';
import '../../domain/entities/reutilizacao.dart';
import '../widgets/feedback/skeleton.dart';
import '../widgets/feedback/empty_state.dart';

class DispositivoDetailsPage extends ConsumerStatefulWidget {
  final String id;
  const DispositivoDetailsPage({super.key, required this.id});

  @override
  ConsumerState<DispositivoDetailsPage> createState() =>
      _DispositivoDetailsPageState();
}

class _DispositivoDetailsPageState
    extends ConsumerState<DispositivoDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final rt = ref.watch(reToolProvider);
    final auth = ref.watch(authProvider);
    final disp = rt.dispositivos.where((d) => d.id == widget.id).firstOrNull;
    final nomes = rt.nomesClassificacao;

    if (disp == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Dispositivo não encontrado.',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/dispositivos'),
              child: const Text('Voltar para a lista'),
            ),
          ],
        ),
      );
    }

    final catNome = nomes.categorias[disp.categoriaId ?? ''] ?? '';
    final famNome = nomes.familias[disp.familiaId ?? ''] ?? '';
    final prodNome = nomes.produtos[disp.produtoId ?? ''] ?? '';

    // Reutilizações do dispositivo
    final reuts = rt.reutilizacoes
        .where((r) => r.dispositivoId == widget.id)
        .toList()
      ..sort((a, b) => (b.dataCriacao ?? b.data ?? '')
          .compareTo(a.dataCriacao ?? a.data ?? ''));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb + ações
          Row(
            children: [
              InkWell(
                onTap: () => context.go('/dispositivos'),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, size: 18, color: AppColors.textMuted),
                    SizedBox(width: 4),
                    Text('Dispositivos',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Spacer(),
              if (auth.canEditar)
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                ),
              const SizedBox(width: 8),
              if (auth.canSolicitar)
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.build_outlined, size: 16),
                  label: const Text('Solicitar reutilização'),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Nome principal + status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disp.nome ?? 'Sem nome',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (disp.codigo != null && disp.codigo!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Código: ${disp.codigo}',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF6b7280))),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (disp.ativo ?? true)
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (disp.ativo ?? true) ? 'Ativo' : 'Inativo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        (disp.ativo ?? true) ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Classificações em badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (catNome.isNotEmpty)
                _DetailBadge(
                    label: 'Categoria',
                    value: catNome,
                    bgColor: AppColors.boxPinkBg,
                    textColor: AppColors.boxPinkText),
              if (famNome.isNotEmpty)
                _DetailBadge(
                    label: 'Família',
                    value: famNome,
                    bgColor: AppColors.boxTealBg,
                    textColor: AppColors.boxTealText),
              if (prodNome.isNotEmpty)
                _DetailBadge(
                    label: 'Produto',
                    value: prodNome,
                    bgColor: AppColors.boxBlueBg,
                    textColor: AppColors.boxBlueText),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Info cards
          _InfoSection(children: [
            if (disp.descricao != null && disp.descricao!.isNotEmpty)
              _InfoRow(label: 'Descrição', value: disp.descricao!),
            if (disp.peso != null && disp.peso!.isNotEmpty)
              _InfoRow(label: 'Peso', value: '${disp.peso} g'),
            if (disp.processo != null && disp.processo!.isNotEmpty)
              _InfoRow(label: 'Processo industrial', value: disp.processo!),
            if (disp.dataCriacao != null)
              _InfoRow(
                  label: 'Data de criação',
                  value: disp.dataCriacao!),
            if (disp.palavrasChave != null && disp.palavrasChave!.isNotEmpty)
              _InfoRow(
                  label: 'Palavras-chave',
                  value: disp.palavrasChave!.join(', ')),
          ]),
          const SizedBox(height: AppTheme.spacingXl),

          // Imagens / Anexos
          const Text('Anexos',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: AppTheme.spacingMd),
          if (disp.anexos == null || disp.anexos!.isEmpty)
            const EmptyState(
              titulo: 'Nenhum anexo',
              descricao: 'Este dispositivo ainda não possui imagens ou documentos.',
              compacto: true,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: disp.anexos!.length,
              itemBuilder: (ctx, idx) {
                final anexo = disp.anexos![idx];
                final isImage = anexo.contentType?.startsWith('image/') ?? false;
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    color: AppColors.hover,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isImage ? Icons.image : Icons.picture_as_pdf,
                        size: 32,
                        color: isImage
                            ? AppColors.primary
                            : AppColors.boxBlueText,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          anexo.nome ?? 'Arquivo',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: AppTheme.spacingXl),

          // Histórico de reutilizações
          const Text('Histórico de Reutilizações',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: AppTheme.spacingMd),
          if (reuts.isEmpty)
            const EmptyState(
              titulo: 'Sem reutilizações',
              descricao: 'Nenhuma solicitação de reutilização para este dispositivo.',
              compacto: true,
            )
          else
            ...reuts.map((r) => _ReutCard(reutilizacao: r)),
        ],
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;

  const _DetailBadge({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.7))),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final List<Widget> children;
  const _InfoSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.isEmpty
            ? [
                const Text('Nenhum detalhe disponível.',
                    style: TextStyle(color: AppColors.textMuted))
              ]
            : children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF6b7280))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }
}

class _ReutCard extends StatelessWidget {
  final Reutilizacao reutilizacao;
  const _ReutCard({required this.reutilizacao});

  @override
  Widget build(BuildContext context) {
    final cor = corDoStatusReutilizacao(reutilizacao.status ?? '');
    final rotulo =
        rotuloCurtoStatusReutilizacao(reutilizacao.status ?? 'Em análise');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reutilizacao.descricaoAlteracao ?? 'Sem descrição',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${reutilizacao.solicitanteNome ?? 'Desconhecido'} · ${reutilizacao.dataCriacao ?? reutilizacao.data ?? ''}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6b7280)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(rotulo,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cor)),
          ),
        ],
      ),
    );
  }
}

