import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/character.dart';

/// 勘探：用手指刷开泥土，露出下方的甲骨文字形。
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
  bool _finished = false;

  static const double _brushRadius = 34.0;
  static const double _revealTargetRatio = 0.55;

  double get _revealedRatio {
    if (_canvasSize.isEmpty || _points.isEmpty) return 0;
    // 粗略估算：每一点覆盖 π r²，与画布面积对比。上限 1.0。
    final double covered = _points.length * 3.14159 * _brushRadius * _brushRadius * 0.35;
    final double area = _canvasSize.width * _canvasSize.height;
    return (covered / area).clamp(0.0, 1.0);
  }

  void _addPoint(Offset o) {
    setState(() => _points.add(o));
    if (!_finished && _revealedRatio >= _revealTargetRatio) {
      _finished = true;
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
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // 底层：甲骨文字形
                  ColoredBox(
                    color: InkPalette.paperDeep,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Image.asset(widget.character.oracleImage,
                          fit: BoxFit.contain),
                    ),
                  ),
                  // 上层：泥土遮罩 + 刷开的洞
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (DragDownDetails d) => _addPoint(d.localPosition),
                      onPanUpdate: (DragUpdateDetails d) => _addPoint(d.localPosition),
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
        color: InkPalette.paper.withOpacity(0.85),
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