import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 数之岛通用商品/贝币视觉：一个圆形色块 + 中央汉字标签。
///
/// v0 用它兜底代替真实商品/贝币图。后续在 assets/numbers/ 下补齐 png 后
/// 直接换实现即可，调用点不变。
class NumberGlyph extends StatelessWidget {
  const NumberGlyph({
    super.key,
    required this.label,
    required this.colorKey,
    this.size = 56,
    this.dim = false,
    this.borderColor,
  });

  final String label;
  final String colorKey;
  final double size;
  final bool dim;
  final Color? borderColor;

  static Color colorFor(String key) {
    switch (key) {
      case 'vermilion':
        return InkPalette.vermilion;
      case 'ochre':
        return InkPalette.ochre;
      case 'reed':
        return InkPalette.reed;
      case 'dusk':
        return InkPalette.dusk;
      case 'glow':
        return InkPalette.glow;
      default:
        return InkPalette.inkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color base = colorFor(colorKey);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dim
            ? base.withValues(alpha: 0.22)
            : base.withValues(alpha: 0.85),
        border: Border.all(
          color: borderColor ??
              (dim
                  ? InkPalette.ink.withValues(alpha: 0.18)
                  : InkPalette.ink.withValues(alpha: 0.35)),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: dim
              ? InkPalette.ink.withValues(alpha: 0.35)
              : InkPalette.paper,
          letterSpacing: 1,
        ),
      ),
    );
  }
}