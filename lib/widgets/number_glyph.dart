import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 数之岛通用商品/贝币视觉。
///
/// 使用位图资源时提供 [assetPath]；未提供时退回到 [label] 圆形色块兜底。
/// [dim] = true 时压暗与半透明，用于"已被拿走"的货架槽或占位。
class NumberGlyph extends StatelessWidget {
  const NumberGlyph({
    super.key,
    this.assetPath,
    required this.label,
    required this.colorKey,
    this.size = 56,
    this.dim = false,
  }) : assert(assetPath != null || label != '');

  final String? assetPath;
  final String label;
  final String colorKey;
  final double size;
  final bool dim;

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
    if (assetPath != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Opacity(
          opacity: dim ? 0.28 : 1,
          child: Image.asset(
            assetPath!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    }
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
          color: dim
              ? InkPalette.ink.withValues(alpha: 0.18)
              : InkPalette.ink.withValues(alpha: 0.35),
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

/// 贝币视觉：绕 assets/numbers/coins/<face>.png，按面值取图。
class CoinGlyph extends StatelessWidget {
  const CoinGlyph({
    super.key,
    required this.face,
    this.size = 64,
    this.glow = false,
    this.dim = false,
  });

  final int face;
  final double size;
  final bool glow;
  final bool dim;

  String get assetPath => 'assets/numbers/coins/$face.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glow && !dim
            ? <BoxShadow>[
                BoxShadow(
                  color: InkPalette.glow.withValues(alpha: 0.55),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Opacity(
        opacity: dim ? 0.35 : 1,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}