import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/retool_provider.dart';
import '../../../domain/entities/dispositivo.dart';
import '../../../domain/entities/file_attachment.dart';
import '../../../core/theme/app_colors.dart';
import 'accessible_modal.dart';

class DispositivoFormModal extends ConsumerStatefulWidget {
  final Dispositivo? dispositivoParaEditar;
  const DispositivoFormModal({super.key, this.dispositivoParaEditar});

  @override
  ConsumerState<DispositivoFormModal> createState() => _DispositivoFormModalState();
}

class _DispositivoFormModalState extends ConsumerState<DispositivoFormModal> {
  final TextEditingController _nomeCtrl = TextEditingController();
  final TextEditingController _codigoCtrl = TextEditingController();
  String? _categoriaId;
  String? _familiaId;
  String? _produtoId;
  final TextEditingController _pesoCtrl = TextEditingController();
  final TextEditingController _descricaoCtrl = TextEditingController();
  final TextEditingController _observacoesCtrl = TextEditingController();
  final TextEditingController _palavrasChaveCtrl = TextEditingController();

  String? _imagemDispositivoUrl;
  String? _imagemPecaUrl;
  List<FileAttachment> _anexos = [];

  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final d = widget.dispositivoParaEditar;
    if (d != null) {
      _nomeCtrl.text = d.nome ?? '';
      _codigoCtrl.text = d.codigo ?? '';
      _categoriaId = d.categoriaId;
      _familiaId = d.familiaId;
      _produtoId = d.produtoId;
      _pesoCtrl.text = d.peso ?? '';
      _descricaoCtrl.text = d.descricao ?? '';
      _observacoesCtrl.text = d.observacoes ?? '';
      _palavrasChaveCtrl.text = (d.palavrasChave ?? []).join(', ');
      _imagemDispositivoUrl = d.imagemDispositivo;
      _imagemPecaUrl = d.imagemPeca;
      _anexos = List.from(d.anexos ?? []);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _codigoCtrl.dispose();
    _pesoCtrl.dispose();
    _descricaoCtrl.dispose();
    _observacoesCtrl.dispose();
    _palavrasChaveCtrl.dispose();
    super.dispose();
  }

  Future<void> _fazerUpload(String categoria) async {
    final result = await FilePicker.platform.pickFiles(
      type: categoria == 'documento_pdf' ? FileType.custom : FileType.image,
      allowedExtensions: categoria == 'documento_pdf' ? ['pdf'] : ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;

    setState(() => _loading = true);
    try {
      final dispId = widget.dispositivoParaEditar?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
      String mime = 'image/jpeg';
      if (file.name.endsWith('.png')) mime = 'image/png';
      if (file.name.endsWith('.webp')) mime = 'image/webp';
      if (file.name.endsWith('.pdf')) mime = 'application/pdf';

      final anexo = await ref.read(reToolProvider.notifier).uploadAnexo(
            dispositivoId: dispId,
            categoria: categoria,
            fileName: file.name,
            bytes: file.bytes!,
            contentType: mime,
          );

      setState(() {
        if (categoria == 'imagem_dispositivo') {
          _imagemDispositivoUrl = anexo.downloadURL;
        } else if (categoria == 'imagem_peca') {
          _imagemPecaUrl = anexo.downloadURL;
        } else {
          _anexos.add(anexo);
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _salvar() async {
    setState(() {
      _erro = null;
      _loading = true;
    });

    try {
      final tags = _palavrasChaveCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final disp = Dispositivo(
        id: widget.dispositivoParaEditar?.id ?? '',
        nome: _nomeCtrl.text.trim().isNotEmpty ? _nomeCtrl.text.trim() : null,
        codigo: _codigoCtrl.text.trim().isNotEmpty ? _codigoCtrl.text.trim() : null,
        categoriaId: _categoriaId,
        familiaId: _familiaId,
        produtoId: _produtoId,
        peso: _pesoCtrl.text.trim().isNotEmpty ? _pesoCtrl.text.trim() : null,
        descricao: _descricaoCtrl.text.trim().isNotEmpty ? _descricaoCtrl.text.trim() : null,
        observacoes: _observacoesCtrl.text.trim().isNotEmpty ? _observacoesCtrl.text.trim() : null,
        palavrasChave: tags,
        imagemDispositivo: _imagemDispositivoUrl,
        imagemPeca: _imagemPecaUrl,
        anexos: _anexos,
        ativo: widget.dispositivoParaEditar?.ativo ?? true,
      );

      await ref.read(reToolProvider.notifier).saveDispositivo(disp);
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
    final isEditing = widget.dispositivoParaEditar != null;

    return AccessibleModal(
      title: isEditing ? 'Editar Dispositivo' : 'Novo Dispositivo',
      maxWidth: 700,
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

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nº Dispositivo (Nome):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(controller: _nomeCtrl, decoration: const InputDecoration(hintText: 'Ex: MAT04670')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Número da Peça (Código):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(controller: _codigoCtrl, decoration: const InputDecoration(hintText: 'Ex: 504001')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Categoria / Tipo:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _categoriaId,
                      hint: const Text('Selecione'),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: state.categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome ?? ''))).toList(),
                      onChanged: (v) => setState(() => _categoriaId = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Família:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _familiaId,
                      hint: const Text('Selecione'),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: state.familias.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nome))).toList(),
                      onChanged: (v) => setState(() => _familiaId = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Produto:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _produtoId,
                      hint: const Text('Selecione'),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: state.produtos.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nome))).toList(),
                      onChanged: (v) => setState(() => _produtoId = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Peso (kg):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(controller: _pesoCtrl, keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Descrição da Peça / Processo:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(controller: _descricaoCtrl, maxLines: 2),
          const SizedBox(height: 16),

          const Text('Palavras-chave (separadas por vírgula):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(controller: _palavrasChaveCtrl, decoration: const InputDecoration(hintText: 'Ex: dobra, solda, estampo')),
          const SizedBox(height: 16),

          const Text('Observações:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(controller: _observacoesCtrl, maxLines: 2),
          const SizedBox(height: 20),

          // Upload de Imagens
          const Text('Imagens e Documentos:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              // Imagem do Dispositivo
              Expanded(
                child: _BoxUpload(
                  titulo: 'Imagem do Dispositivo',
                  subtitulo: 'Propagada pela linha',
                  url: _imagemDispositivoUrl,
                  onUpload: () => _fazerUpload('imagem_dispositivo'),
                  onRemover: () => setState(() => _imagemDispositivoUrl = null),
                ),
              ),
              const SizedBox(width: 12),
              // Imagem da Peça
              Expanded(
                child: _BoxUpload(
                  titulo: 'Imagem da Peça',
                  subtitulo: 'Individual',
                  url: _imagemPecaUrl,
                  onUpload: () => _fazerUpload('imagem_peca'),
                  onRemover: () => setState(() => _imagemPecaUrl = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text('Anexar PDF (${_anexos.length} anexos)'),
            onPressed: () => _fazerUpload('documento_pdf'),
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
          onPressed: _loading ? null : _salvar,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEditing ? 'Salvar alterações' : 'Cadastrar dispositivo'),
        ),
      ],
    );
  }
}

class _BoxUpload extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String? url;
  final VoidCallback onUpload;
  final VoidCallback onRemover;

  const _BoxUpload({
    required this.titulo,
    required this.subtitulo,
    this.url,
    required this.onUpload,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.gray03.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(8),
      child: url != null && url!.isNotEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined)),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: onRemover,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Text(subtitulo, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cloud_upload_outlined, size: 14),
                  label: const Text('Enviar', style: TextStyle(fontSize: 11)),
                  onPressed: onUpload,
                ),
              ],
            ),
    );
  }
}

