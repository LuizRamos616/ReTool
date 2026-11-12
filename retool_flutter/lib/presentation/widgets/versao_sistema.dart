import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class VersaoSistema extends StatelessWidget {
  const VersaoSistema({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ReTool v2.11.0',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.gray01,
            ),
          ),
        ],
      ),
    );
  }
}

