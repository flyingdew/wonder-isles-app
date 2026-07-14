import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/character.dart';

/// 拼合：把 4 个字形碎片拖到中央轮廓里，磁吸辅助。
///
/// 用甲骨文整图切成 2×2 网格，每片独立位置，用户拖入对应格子即可。
class AssembleStage extends StatefulWidget {
  const AssembleStage({super.key, required this.character, required this.onDone});
  final WonderCharacter character;
  final VoidCallback onDone;

  @override
  State<AssembleStage> createState() => _AssembleStageState();
}

class _AssembleStageState extends State<AssembleStage> {
  static const int _rows = 2;
  static const int _cols = 2;

  Size _canvas = Size.zero;
  Rect _targetRect = Rect.zero;
  final Map<int, Offset> _piecePos = <int, Offset>{};
  final Set<int> _snapped = <int>{};

  bool get _finished => _snapped.length == _rows * _cols;

  void _ensureLayout(BoxConstraints cons) {
    final Size s = Size(cons.maxWidth, cons.maxHeight);
    if (s == _canvas) return;
    _canvas = s;
    // 目标框：中间大约 55% 宽的正方形。
    final double side = math.min(s.width * 0.55, s.height * 0.55);
    final double left = (s.width - side) / 2;
    final double top = (s.height - side) / 2 - 20;
    _targetRect = Rect.fromLTWH(left, top, side, side);

    // 起始位置：绕着画布四角/边缘随机撒。
    final math.Random rng = math.Random(widget.character.id.hashCode);
    final double pieceSide = side / _cols;
    for (int i = 0; i < _rows * _cols; i++) {
      final int r = i ~/ _cols;
      final int c = i % _cols;
      // 分布到画布四角
      final Offset origin = <Offset>[
        const Offset(12, 12),
        Offset(s.width - pieceSide - 12, 12),
        Offset(12, s.height - pieceSide - 12),
        Offset(s.width - pieceSide - 12, s.height - pieceSide - 12),
      ][i];
      _piecePos[i] = origin +
          Offset(rng.nextDouble() * 8 - 4, rng.nextDouble() * 8 - 4);
      _snapped.remove(i);
      // 记录格子编号用（r,c）在 build 里读。
      _rowCol[i] = (r, c);
    }
  }

  final Map<int, (int, int)> _rowCol = <int, (int, int)>{};

  void _handleDragEnd(int idx, Offset pos, double pieceSide) {
    final int r = _rowCol[idx]!.$1;
    final int c = _rowCol[idx]!.$2;
    final Offset target = Offset(
      _targetRect.left + c * pieceSide,
      _targetRect.top + r * pieceSide,
    );
    final double dist = (pos - target).distance;
    setState(() {
      if (dist < pieceSide * 0.4) {
        _piecePos[idx] = target;
        _snapped.add(idx);
      } else {
        _piecePos[idx] = pos;
      }
    });
    if (_finished) {
      Future<void>.delayed(const Duration(milliseconds: 400), widget.onDone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text('把碎片拖到轮廓里，拼出完整的字',
            style: TextStyle(fontSize: 16, color: InkPalette.inkSoft)),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints cons) {
            _ensureLayout(cons);
            final double pieceSide = _targetRect.width / _cols;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: InkPalette.paperDeep,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: <Widget>[
                  // 目标轮廓（虚线框 + 淡淡的字影）
                  Positioned.fromRect(
                    rect: _targetRect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: InkPalette.paper.withValues(alpha: 0.6),
                        border: Border.all(
                          color: InkPalette.ink.withValues(alpha: 0.4),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Opacity(
                        opacity: 0.18,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(widget.character.oracleImage,
                              fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  // 碎片
                  for (int i = 0; i < _rows * _cols; i++)
                    _Piece(
                      key: ValueKey<String>('${widget.character.id}-$i'),
                      image: widget.character.oracleImage,
                      row: _rowCol[i]!.$1,
                      col: _rowCol[i]!.$2,
                      rows: _rows,
                      cols: _cols,
                      side: pieceSide,
                      position: _piecePos[i]!,
                      snapped: _snapped.contains(i),
                      onDragEnd: (Offset p) => _handleDragEnd(i, p, pieceSide),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Piece extends StatefulWidget {
  const _Piece({
    super.key,
    required this.image,
    required this.row,
    required this.col,
    required this.rows,
    required this.cols,
    required this.side,
    required this.position,
    required this.snapped,
    required this.onDragEnd,
  });

  final String image;
  final int row;
  final int col;
  final int rows;
  final int cols;
  final double side;
  final Offset position;
  final bool snapped;
  final ValueChanged<Offset> onDragEnd;

  @override
  State<_Piece> createState() => _PieceState();
}

class _PieceState extends State<_Piece> {
  late Offset _pos = widget.position;

  @override
  void didUpdateWidget(covariant _Piece old) {
    super.didUpdateWidget(old);
    // 若吸附完成后被父组件改了位置，跟着更新。
    if (widget.snapped && widget.position != _pos) {
      _pos = widget.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: widget.snapped
          ? const Duration(milliseconds: 220)
          : Duration.zero,
      curve: Curves.easeOut,
      left: _pos.dx,
      top: _pos.dy,
      width: widget.side,
      height: widget.side,
      child: GestureDetector(
        onPanUpdate: widget.snapped
            ? null
            : (DragUpdateDetails d) {
                setState(() => _pos += d.delta);
              },
        onPanEnd: widget.snapped
            ? null
            : (_) => widget.onDragEnd(_pos),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.snapped
                ? InkPalette.glow.withValues(alpha: 0.4)
                : InkPalette.paper,
            border: Border.all(
                color: InkPalette.ink.withValues(alpha: 0.45), width: 1),
            borderRadius: BorderRadius.circular(6),
            boxShadow: widget.snapped
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRect(
            child: Align(
              alignment: Alignment(
                widget.cols == 1
                    ? 0
                    : (widget.col * 2 / (widget.cols - 1)) - 1,
                widget.rows == 1
                    ? 0
                    : (widget.row * 2 / (widget.rows - 1)) - 1,
              ),
              widthFactor: 1 / widget.cols,
              heightFactor: 1 / widget.rows,
              child: Image.asset(widget.image,
                  fit: BoxFit.contain,
                  width: widget.side * widget.cols,
                  height: widget.side * widget.rows),
            ),
          ),
        ),
      ),
    );
  }
}
