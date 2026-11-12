import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum TipoAlerta { info, warning, error, success }

class Alerta extends StatelessWidget {
  final String mensagem;
  final TipoAlerta tipo;
  final VoidCallback? onFechar;

  const Alerta({
    super.key,
    required this.mensagem,
    this.tipo = TipoAlerta.info,
    this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    IconData icon;

    switch (tipo) {
      case TipoAlerta.warning:
        bg = AppColors.boxYellowBg;
        border = AppColors.warning.withOpacity(0.4);
        text = AppColors.boxYellowText;
        icon = Icons.warning_amber_rounded;
        break;
      case TipoAlerta.error:
        bg = AppColors.red03.withOpacity(0.4);
        border = AppColors.danger.withOpacity(0.4);
        text = AppColors.danger;
        icon = Icons.error_outline_rounded;
        break;
      case TipoAlerta.success:
        bg = const Color(0xFFDCFCE7);
        border = AppColors.success00.withOpacity(0.4);
        text = AppColors.success00;
        icon = Icons.check_circle_outline_rounded;
        break;
      case TipoAlerta.info:
      default:
        bg = AppColors.boxTealBg;
        border = AppColors.border;
        text = AppColors.textDark;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: text),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(fontSize: 13, color: text, fontWeight: FontWeight.w500),
            ),
          ),
          if (onFechar != null)
            IconButton(
              icon: Icon(Icons.close, size: 16, color: text),
              onPressed: onFechar,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

