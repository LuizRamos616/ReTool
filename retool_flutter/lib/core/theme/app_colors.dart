import 'package:flutter/material.dart';

/// Paleta oficial do ReTool (extraída de retool/src/index.css)
class AppColors {
  AppColors._();

  // Cores Base
  static const Color red00 = Color(0xFFE40D2C);
  static const Color red01 = Color(0xFF8C1A17);
  static const Color red02 = Color(0xFFFF798D);
  static const Color red03 = Color(0xFFFCC4CC);

  static const Color gray00 = Color(0xFF4A4A4A);
  static const Color gray01 = Color(0xFF6B7280);
  static const Color gray02 = Color(0xFFD6D6D6);
  static const Color gray03 = Color(0xFFE8E7E7);
  static const Color gray04 = Color(0xFFF1F5F9);
  static const Color gray05 = Color(0xFFF8FAFC);

  static const Color black00 = Color(0xFF000000);
  static const Color black01 = Color(0xFF2F2F2F);
  static const Color white00 = Color(0xFFFFFFFE);

  static const Color success00 = Color(0xFF00762E);
  static const Color success01 = Color(0xFF018D37);

  static const Color various00 = Color(0xFF9E3D45);
  static const Color various01 = Color(0xFFEB593B);
  static const Color various02 = Color(0xFF785994);
  static const Color various03 = Color(0xFF334F5C);
  static const Color various04 = Color(0xFFF5A32B);
  static const Color various05 = Color(0xFF00762E);

  // Mapeamento Semântico de UI
  static const Color primary = red00;
  static const Color textTitle = red00;
  static const Color textBody = gray00;
  static const Color textDark = black01;
  static const Color textMuted = gray01;

  static const Color graySteel = gray00;
  static const Color surfaceBg = Color(0xFFF8FAFC);
  static const Color surface = white00;
  static const Color border = gray02;
  static const Color hover = gray03;

  // Badges & Status
  static const Color danger = red00;
  static const Color dangerHover = red01;
  static const Color success = success00;
  static const Color warning = various04;

  static const Color boxPinkBg = red03;
  static const Color boxPinkText = red01;

  static const Color boxTealBg = gray03;
  static const Color boxTealText = various03;

  static const Color boxYellowBg = Color(0x26F5A32B); // rgba(245, 163, 43, 0.15)
  static const Color boxYellowText = Color(0xFF7A4A00);

  static const Color boxBlueBg = Color(0x26785994); // rgba(120, 89, 148, 0.15)
  static const Color boxBlueText = various02;
}

