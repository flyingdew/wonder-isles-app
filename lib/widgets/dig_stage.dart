import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, rootBundle;
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../services/voice_service.dart';

/// 勘探：用手指刷开泥土，露出下方的甲骨文字形。
///
/// 完成判定基于「已刷开的墨迹像素比例」：预先把字形下采样成 64×64 网格，
/// 标出墨迹（alpha 高且亮度低）的格子；刷子经过时把落在字形内的墨格
/// 计入 [_brushedInk]。达到 [_revealTargetRatio] 即算完成，避免在空白
/// 处乱刷也能过关。
class DigStage extends StatefulWidget {
  const DigStage({super.key, required this.character, required this.onDone});
  final WonderCharacter character;
  final VoidCallback onDone;

  @override
  State<DigStage> createState() => _DigStageState();
}

class _DigStageState extends State<DigStage> {
  final List<Offset> _points = <Offset>[];
  Size _canvasSize = Size.zero;
  Rect _imageRect = Rect.zero;
  bool _finished = false;

  double get _brushRadius {
    final double side = _imageRect.shortestSide;
    if (side <= 0) return 34.0;
    return (side * 0.11).clamp(24.0, 44.0);
  }
  static const double _revealTargetRatio = 0.55;
  static const int _gridSide = 64;
  static const double _paperPad = 32;

  Uint8List? _inkMask;
  int _totalInk = 0;
  final Set<int> _brushedInk = <int>{};

  @override
  void initState() {
    super.initState();
    _loadInkMask();
  }

  @override
  void didUpdateWidget(covariant DigStage old) {
    super.didUpdateWidget(old);
    if (old.character.id != widget.character.id) {
      _points.clear();
      _brushedInk.clear();
      _finished = false;
      _inkMask = null;
      _totalInk = 0;
      _loadInkMask();
    }
  }

  Future<void> _loadInkMask() async {
    final String asset = widget.character.oracleImage;
    final ByteData raw = await rootBundle.load(asset);
    final ui.Codec codec = await ui.instantiateImageCodec(
      raw.buffer.asUint8List(),
      targetWidth: _gridSide,
      targetHeight: _gridSide,
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ByteData? bd =
        await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    if (bd == null || !mounted) return;
    final Uint8List bytes = bd.buffer.asUint8List();
    final Uint8List mask = Uint8List(_gridSide * _gridSide);
    int totalInk = 0;
    for (int i = 0; i < mask.length; i++) {
      final int r = bytes[i * 4];
      final int g = bytes[i * 4 + 1];
      final int b = bytes[i * 4 + 2];
      final int a = bytes[i * 4 + 3];
      final double lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
      // 认定为墨迹：足够不透明且颜色够深。
      if (a > 40 && lum < 0.55) {
        mask[i] = 1;
        totalInk++;
      }
    }
    // 极端情况下几乎全透明或全白，退回全格计数，避免除零。
    if (totalInk == 0) totalInk = mask.length;
    if (!mounted) return;
    setState(() {
      _inkMask = mask;
      _totalInk = totalInk;
    });
  }

  Rect _computeImageRect(Size canvas) {
    final Rect inner = Rect.fromLTWH(
      _paperPad,
      _paperPad,
      canvas.width - 2 * _paperPad,
      canvas.height - 2 * _paperPad,
    );
    if (inner.width <= 0 || inner.height <= 0) return Rect.zero;
    // 字形 PNG 为方形，BoxFit.contain 后取最短边居中。
    final double side = inner.shortestSide;
    return Rect.fromCenter(
      center: inner.center,
      width: side,
      height: side,
    );
  }

  double get _revealedRatio {
    if (_totalInk == 0) return 0;
    return (_brushedInk.length / _totalInk).clamp(0.0, 1.0);
  }

  void _markBrushed(Offset o) {
    final Uint8List? mask = _inkMask;
    if (mask == null || !_imageRect.contains(o)) return;
    final double relX = (o.dx - _imageRect.left) / _imageRect.width;
    final double relY = (o.dy - _imageRect.top) / _imageRect.height;
    if (relX < 0 || relX > 1 || relY < 0 || relY > 1) return;

    final double cxF = relX * _gridSide;
    final double cyF = relY * _gridSide;
    final double rXF = (_brushRadius / _imageRect.width) * _gridSide;
    final double rYF = (_brushRadius / _imageRect.height) * _gridSide;
    final int rX = rXF.ceil().clamp(1, _gridSide);
    final int rY = rYF.ceil().clamp(1, _gridSide);
    final int cx = cxF.floor();
    final int cy = cyF.floor();

    for (int dy = -rY; dy <= rY; dy++) {
      final int y = cy + dy;
      if (y < 0 || y >= _gridSide) continue;
      for (int dx = -rX; dx <= rX; dx++) {
        final int x = cx + dx;
        if (x < 0 || x >= _gridSide) continue;
        // 椭圆内判定，避免 x/y 缩放不同带来的偏差。
        final double nx = dx / rX;
        final double ny = dy / rY;
        if (nx * nx + ny * ny > 1) continue;
        final int idx = y * _gridSide + x;
        if (mask[idx] == 1) _brushedInk.add(idx);
      }
    }
  }

  void _addPoint(Offset o) {
    setState(() {
      _points.add(o);
      _markBrushed(o);
    });
    if (!_finished && _revealedRatio >= _revealTargetRatio) {
      _finished = true;
      HapticFeedback.mediumImpact();
      context.read<VoiceService>().playSfx('sparkle');
      Future<void>.delayed(const Duration(milliseconds: 250), widget.onDone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text('用手指刷开泥土',
            style: TextStyle(fontSize: 16, color: InkPalette.inkSoft)),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints cons) {
            _canvasSize = Size(cons.maxWidth, cons.maxHeight);
            _imageRect = _computeImageRect(_canvasSize);
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // 底层：甲骨文字形
                  ColoredBox(
                    color: InkPalette.paperDeep,
                    child: Padding(
                      padding: const EdgeInsets.all(_paperPad),
                      child: Image.asset(widget.character.oracleImage,
                          fit: BoxFit.contain),
                    ),
                  ),
                  // 上层：泥土遮罩 + 刷开的洞
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (DragDownDetails d) =>
                          _addPoint(d.localPosition),
                      onPanUpdate: (DragUpdateDetails d) =>
                          _addPoint(d.localPosition),
                      child: CustomPaint(
                        painter: _DirtMaskPainter(
                          points: _points,
                          brushRadius: _brushRadius,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _RevealProgress(ratio: _revealedRatio),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _finished ? null : widget.onDone,
          child: const Text('跳过'),
        ),
      ],
    );
  }
}

class _RevealProgress extends StatelessWidget {
  const _RevealProgress({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: InkPalette.paper.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('${(ratio * 100).clamp(0, 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            color: InkPalette.ink,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          )),
    );
  }
}

class _DirtMaskPainter extends CustomPainter {
  _DirtMaskPainter({required this.points, required this.brushRadius});

  final List<Offset> points;
  final double brushRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    // 泥土底色（不透明），带一点纹理感的两层叠加。
    final Paint dirtPaint = Paint()..color = const Color(0xFF6E4B2F);
    canvas.drawRect(rect, dirtPaint);

    final Paint noise = Paint()
      ..color = const Color(0x556E4B2F)
      ..blendMode = BlendMode.overlay;
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 4), noise);
    }

    // 用 dstOut 把手指经过的位置抠掉，露出下层字形。
    final Paint erase = Paint()
      ..blendMode = BlendMode.dstOut
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (final Offset p in points) {
      canvas.drawCircle(p, brushRadius, erase);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DirtMaskPainter old) =>
      old.points.length != points.length;
}
