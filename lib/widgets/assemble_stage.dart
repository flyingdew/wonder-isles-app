import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/character.dart';

/// 拼合：把打乱的甲骨文碎片拖到中央轮廓的对应格子里。
///
/// 关键点：
/// - 网格支持 2x2 和 3x3（`gridSize`），由外层根据难度传入。
/// - 每片有稳定的 id（对应它在完成图中的目标格）。
/// - 落下时找最近的格子：仅当那格正是自己的目标格才吸附；否则弹回并抖动提示。
class AssembleStage extends StatefulWidget {
  const AssembleStage({
    super.key,
    required this.character,
    required this.onDone,
    this.gridSize = 2,
  });

  final WonderCharacter character;
  final VoidCallback onDone;

  /// 拼图边长（2 或 3）。
  final int gridSize;

  @override
  State<AssembleStage> createState() => _AssembleStageState();
}

class _AssembleStageState extends State<AssembleStage> {
  Size _canvas = Size.zero;
  Rect _targetRect = Rect.zero;

  /// 每片当前左上角坐标（key = 拼图中的目标格 index, 0..n*n-1）。
  final Map<int, Offset> _piecePos = <int, Offset>{};

  /// 已经吸附到正确格子的片 id。
  final Set<int> _snapped = <int>{};

  /// 每格当前被占据的片 id；空则为 null。
  final Map<int, int?> _slotOwner = <int, int?>{};

  /// 触发一次抖动 / 红边的片 id。
  int? _shakingPiece;

  int get _n => widget.gridSize;
  int get _total => _n * _n;
  bool get _finished => _snapped.length == _total;

  @override
  void didUpdateWidget(covariant AssembleStage old) {
    super.didUpdateWidget(old);
    if (old.character.id != widget.character.id ||
        old.gridSize != widget.gridSize) {
      _canvas = Size.zero;
      _piecePos.clear();
      _snapped.clear();
      _slotOwner.clear();
      _shakingPiece = null;
    }
  }

  void _ensureLayout(BoxConstraints cons) {
    final Size s = Size(cons.maxWidth, cons.maxHeight);
    if (s == _canvas) return;
    _canvas = s;

    // 中央目标框：随难度略缩，给外围碎片留出摆放空间。
    final double scale = _n == 2 ? 0.60 : 0.66;
    final double side = math.min(s.width * scale, s.height * scale);
    final double left = (s.width - side) / 2;
    final double top = (s.height - side) / 2 - 12;
    _targetRect = Rect.fromLTWH(left, top, side, side);

    final double pieceSide = side / _n;

    // 围绕画布外圈生成停靠位并随机打乱作为初始位置。
    final List<Offset> parkSpots = _generateParkingSpots(s, pieceSide);
    final math.Random rng = math.Random(widget.character.id.hashCode ^ _n);
    parkSpots.shuffle(rng);

    for (int i = 0; i < _total; i++) {
      _piecePos[i] = parkSpots[i % parkSpots.length];
      _slotOwner[i] = null;
    }
    _snapped.clear();
    _shakingPiece = null;
  }

  /// 生成围绕画布的停靠位，避免与中央 _targetRect 重叠。
  List<Offset> _generateParkingSpots(Size s, double pieceSide) {
    final List<Offset> spots = <Offset>[];
    const double gap = 8;
    const double topY = gap;
    final double bottomY = s.height - pieceSide - gap;
    const double leftX = gap;
    final double rightX = s.width - pieceSide - gap;

    final int perRow = _n + 1;
    for (int i = 0; i < perRow; i++) {
      final double t = perRow == 1 ? 0.5 : i / (perRow - 1);
      final double x = gap + t * (s.width - pieceSide - 2 * gap);
      spots.add(Offset(x, topY));
      spots.add(Offset(x, bottomY));
    }
    final int perCol = math.max(1, _n - 1);
    for (int i = 0; i < perCol; i++) {
      final double t = perCol == 1 ? 0.5 : (i + 1) / (perCol + 1);
      final double y =
          _targetRect.top + t * (_targetRect.height - pieceSide);
      spots.add(Offset(leftX, y));
      spots.add(Offset(rightX, y));
    }
    return spots;
  }

  void _handleDragEnd(int pieceId, Offset pos, double pieceSide) {
    // 找到落点最近的目标格。
    int nearestSlot = -1;
    double nearestDist = double.infinity;
    for (int s = 0; s < _total; s++) {
      final Offset slotTL = _slotTopLeft(s, pieceSide);
      final double d = (pos - slotTL).distance;
      if (d < nearestDist) {
        nearestDist = d;
        nearestSlot = s;
      }
    }
    final double snapRadius = pieceSide * 0.45;
    final bool inRange = nearestDist < snapRadius;
    final bool slotFree = _slotOwner[nearestSlot] == null ||
        _slotOwner[nearestSlot] == pieceId;
    final bool matchesSelf = nearestSlot == pieceId;

    setState(() {
      if (inRange && slotFree && matchesSelf) {
        _piecePos[pieceId] = _slotTopLeft(nearestSlot, pieceSide);
        _slotOwner[nearestSlot] = pieceId;
        _snapped.add(pieceId);
        _shakingPiece = null;
      } else {
        _piecePos[pieceId] = pos;
        _shakingPiece = pieceId;
      }
    });

    if (!(inRange && slotFree && matchesSelf)) {
      Future<void>.delayed(const Duration(milliseconds: 340), () {
        if (!mounted) return;
        if (_shakingPiece == pieceId) {
          setState(() => _shakingPiece = null);
        }
      });
    }

    if (_finished) {
      Future<void>.delayed(const Duration(milliseconds: 420), widget.onDone);
    }
  }

  Offset _slotTopLeft(int slot, double pieceSide) {
    final int r = slot ~/ _n;
    final int c = slot % _n;
    return Offset(
      _targetRect.left + c * pieceSide,
      _targetRect.top + r * pieceSide,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '把 $_total 块碎片拖回轮廓里，拼出完整的 "${widget.character.char}"',
          style: const TextStyle(fontSize: 16, color: InkPalette.inkSoft),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
              builder: (BuildContext ctx, BoxConstraints cons) {
            _ensureLayout(cons);
            final double pieceSide = _targetRect.width / _n;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: InkPalette.paperDeep,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fromRect(
                    rect: _targetRect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: InkPalette.paper.withValues(alpha: 0.6),
                        border: Border.all(
                          color: InkPalette.ink.withValues(alpha: 0.35),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: <Widget>[
                          CustomPaint(
                            painter: _GridLinesPainter(n: _n),
                            size: Size.infinite,
                          ),
                          Opacity(
                            opacity: 0.18,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(widget.character.oracleImage,
                                  fit: BoxFit.contain),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (int i = 0; i < _total; i++)
                    _Piece(
                      key: ValueKey<String>(
                          '${widget.character.id}-$_n-$i'),
                      image: widget.character.oracleImage,
                      row: i ~/ _n,
                      col: i % _n,
                      n: _n,
                      side: pieceSide,
                      position: _piecePos[i]!,
                      snapped: _snapped.contains(i),
                      shaking: _shakingPiece == i,
                      onDragEnd: (Offset p) =>
                          _handleDragEnd(i, p, pieceSide),
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

class _GridLinesPainter extends CustomPainter {
  _GridLinesPainter({required this.n});
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (int i = 1; i < n; i++) {
      final double x = size.width * i / n;
      final double y = size.height * i / n;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridLinesPainter old) => old.n != n;
}

class _Piece extends StatefulWidget {
  const _Piece({
    super.key,
    required this.image,
    required this.row,
    required this.col,
    required this.n,
    required this.side,
    required this.position,
    required this.snapped,
    required this.shaking,
    required this.onDragEnd,
  });

  final String image;
  final int row;
  final int col;
  final int n;
  final double side;
  final Offset position;
  final bool snapped;
  final bool shaking;
  final ValueChanged<Offset> onDragEnd;

  @override
  State<_Piece> createState() => _PieceState();
}

class _PieceState extends State<_Piece>
    with SingleTickerProviderStateMixin {
  late Offset _pos = widget.position;
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(covariant _Piece old) {
    super.didUpdateWidget(old);
    if (widget.snapped && widget.position != _pos) {
      _pos = widget.position;
    } else if (!widget.snapped && widget.position != old.position) {
      // 父组件重置（换字/换难度）时同步位置。
      _pos = widget.position;
    }
    if (widget.shaking && !old.shaking) {
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration:
          widget.snapped ? const Duration(milliseconds: 240) : Duration.zero,
      curve: Curves.easeOutBack,
      left: _pos.dx,
      top: _pos.dy,
      width: widget.side,
      height: widget.side,
      child: AnimatedBuilder(
        animation: _shakeCtrl,
        builder: (BuildContext ctx, Widget? child) {
          final double t = _shakeCtrl.value;
          final double dx =
              widget.shaking ? math.sin(t * math.pi * 6) * 6 * (1 - t) : 0;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: GestureDetector(
          onPanUpdate: widget.snapped
              ? null
              : (DragUpdateDetails d) {
                  setState(() => _pos += d.delta);
                },
          onPanEnd: widget.snapped ? null : (_) => widget.onDragEnd(_pos),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.snapped
                  ? InkPalette.glow.withValues(alpha: 0.4)
                  : InkPalette.paper,
              border: Border.all(
                color: widget.shaking
                    ? InkPalette.vermilion
                    : InkPalette.ink.withValues(alpha: 0.45),
                width: widget.shaking ? 2 : 1,
              ),
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
                  widget.n == 1
                      ? 0
                      : (widget.col * 2 / (widget.n - 1)) - 1,
                  widget.n == 1
                      ? 0
                      : (widget.row * 2 / (widget.n - 1)) - 1,
                ),
                widthFactor: 1 / widget.n,
                heightFactor: 1 / widget.n,
                child: Image.asset(
                  widget.image,
                  fit: BoxFit.contain,
                  width: widget.side * widget.n,
                  height: widget.side * widget.n,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}