import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SkeletonLinha extends StatelessWidget {
  final double largura;
  final double altura;
  final double borderRadius;

  const SkeletonLinha({
    super.key,
    required this.largura,
    required this.altura,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: AppColors.gray03,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCards extends StatelessWidget {
  final int quantidade;

  const SkeletonCards({super.key, this.quantidade = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        quantidade,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                SkeletonLinha(largura: 60, altura: 60, borderRadius: 6),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonLinha(largura: 180, altura: 14),
                      SizedBox(height: 8),
                      SkeletonLinha(largura: 120, altura: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

