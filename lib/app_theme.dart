import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 水墨 · 暖色调色板。参考 assets/scenes/palette.png 手取。
class InkPalette {
  static const Color paper = Color(0xFFF6EEDD); // 宣纸底
  static const Color paperDeep = Color(0xFFEADFC5);
  static const Color ink = Color(0xFF2B241D); // 淡墨勾边
  static const Color inkSoft = Color(0xFF6B5A46);
  static const Color vermilion = Color(0xFFC24B33); // 朱砂
  static const Color ochre = Color(0xFFC9873D); // 赭石
  static const Color reed = Color(0xFF8FA55B); // 苇绿
  static const Color dusk = Color(0xFF7A5A82); // 山影紫
  static const Color glow = Color(0xFFF2C56A); // 点亮暖光
}

ThemeData buildWonderIslesTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: InkPalette.vermilion,
    brightness: Brightness.light,
    primary: InkPalette.vermilion,
    secondary: InkPalette.ochre,
    surface: InkPalette.paper,
  );

  final TextTheme text = ThemeData.light().textTheme.apply(
        bodyColor: InkPalette.ink,
        displayColor: InkPalette.ink,
      );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: InkPalette.paper,
    textTheme: text,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: InkPalette.ink,
      elevation: 0,
      centerTitle: true,
      // 每个页面的 AppBar 也保持米色 status bar + 深色图标，避免路由切换时闪回默认。
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: InkPalette.paper,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: InkPalette.paper,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: InkPalette.vermilion,
        foregroundColor: InkPalette.paper,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  );
}

