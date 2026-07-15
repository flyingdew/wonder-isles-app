import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/character.dart';

/// 拼合：把打乱的甲骨文碎片拖到中央轮廓的对应格子里。
///
/// 关键点：
/// - 网格支持 2x2 和 3x3（`gridSize`），由外层根据难度传入。
/// - 每片有稳定的 id（对应它在完成图中的目标格）。
/// - 悬浮态碎片略小（park scale），吸附后放大到整格，避免和目标框打架。
/// - 拖动过程中给出目标格实时提示：正确格绿色描边，错格/被占红色描边。
/// - 松手时最近格必须正是自己的目标格才吸附；否则弹回并抖动提示。
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
  double _pieceSideSnap = 0;
  double _pieceSidePark = 0;

  final Map<int, Offset> _piecePos = <int, Offset>{};
  final Set<int> _snapped = <int>{};
  final Map<int, int?> _slotOwner = <int, int?>{};

  int? _shakingPiece;
  int? _draggingPiece;
  int? _hoveredSlot;

  int get _n => widget.gridSize;
  int get _total => _n * _n;
  bool get _finished => _snapped.length == _total;

  static const double _kParkScale = 0.72;
  static const double _kOuterGap = 10;

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
      _draggingPiece = null;
      _hoveredSlot = null;
    }
  }

  void _ensureLayout(BoxConstraints cons) {
    final Size s = Size(cons.maxWidth, cons.maxHeight);
    if (s == _canvas) return;
    _canvas = s;

    // 目标框边长 = pieceSideSnap * n；外圈需要能放下一整块 park 碎片 + 间距。
    // t + 2*(park + 2*_kOuterGap) <= min(w, h)
    // => t * (1 + 2 * _kParkScale / n) <= min(w, h) - 4 * _kOuterGap
    final double minSide = math.min(s.width, s.height);
    final double denom = 1 + 2 * _kParkScale / _n;
    double side = (minSide - 4 * _kOuterGap) / denom;
    side = math.min(side, minSide * 0.78);

    final double left = (s.width - side) / 2;
    final double top = (s.height - side) / 2;
    _targetRect = Rect.fromLTWH(left, top, side, side);
    _pieceSideSnap = side / _n;
    _pieceSidePark = _pieceSideSnap * _kParkScale;

    final List<Offset> parkSpots = _generateParkingSpots(s, _pieceSidePark);
    final math.Random rng = math.Random(widget.character.id.hashCode ^ _n);
    parkSpots.shuffle(rng);

    for (int i = 0; i < _total; i++) {
      _piecePos[i] = parkSpots[i % parkSpots.length];
      _slotOwner[i] = null;
    }
    _snapped.clear();
    _shakingPiece = null;
    _draggingPiece = null;
    _hoveredSlot = null;
  }

  List<Offset> _generateParkingSpots(Size s, double park) {
    final List<Offset> spots = <Offset>[];
    const double gap = _kOuterGap;
    const double topY = gap;
    final double bottomY = s.height - park - gap;
    const double leftX = gap;
    final double rightX = s.width - park - gap;

    for (int i = 0; i < _n; i++) {
      final double t = _n == 1 ? 0.5 : i / (_n - 1);
      final double x = gap + t * (s.width - park - 2 * gap);
      spots.add(Offset(x, topY));
      spots.add(Offset(x, bottomY));
    }
    final double columnTop = _targetRect.top;
    final double columnBottom = _targetRect.bottom - park;
    for (int i = 0; i < _n; i++) {
      final double t = _n == 1 ? 0.5 : i / (_n - 1);
      final double y = columnTop + t * (columnBottom - columnTop);
      spots.add(Offset(leftX, y));
      spots.add(Offset(rightX, y));
    }
    return spots;
  }

  Offset _slotTopLeft(int slot) {
    final int r = slot ~/ _n;
    final int c = slot % _n;
    return Offset(
      _targetRect.left + c * _pieceSideSnap,
      _targetRect.top + r * _pieceSideSnap,
    );
  }

  int _nearestSlot(Offset centerPos) {
    int nearest = 0;
    double best = double.infinity;
    for (int i = 0; i < _total; i++) {
      final Offset c = _slotTopLeft(i) +
          Offset(_pieceSideSnap / 2, _pieceSideSnap / 2);
      final double d = (centerPos - c).distance;
      if (d < best) {
        best = d;
        nearest = i;
      }
    }
    return nearest;
  }

  void _handleDragStart(int pieceId) {
    setState(() {
      _draggingPiece = pieceId;
      _hoveredSlot = null;
    });
  }

  void _handleDragUpdate(int pieceId, Offset pos) {
    final Offset center =
        pos + Offset(_pieceSidePark / 2, _pieceSidePark / 2);
    final int nearest = _nearestSlot(center);
    final Offset slotCenter = _slotTopLeft(nearest) +
        Offset(_pieceSideSnap / 2, _pieceSideSnap / 2);
    final double d = (center - slotCenter).distance;
    final int? next = d < _pieceSideSnap * 0.75 ? nearest : null;
    setState(() {
      _piecePos[pieceId] = pos;
      _hoveredSlot = next;
    });
  }

  void _handleDragEnd(int pieceId, Offset pos) {
    final Offset center =
        pos + Offset(_pieceSidePark / 2, _pieceSidePark / 2);
    final int nearest = _nearestSlot(center);
    final Offset slotCenter = _slotTopLeft(nearest) +
        Offset(_pieceSideSnap / 2, _pieceSideSnap / 2);
    final double d = (center - slotCenter).distance;
    final bool inRange = d < _pieceSideSnap * 0.55;
    final bool slotFree = _slotOwner[nearest] == null ||
        _slotOwner[nearest] == pieceId;
    final bool matches = nearest == pieceId;

    setState(() {
      _draggingPiece = null;
      _hoveredSlot = null;
      if (inRange && slotFree && matches) {
        _piecePos[pieceId] = _slotTopLeft(nearest);
        _slotOwner[nearest] = pieceId;
        _snapped.add(pieceId);
        _shakingPiece = null;
      } else {
        _piecePos[pieceId] = pos;
        _shakingPiece = pieceId;
      }
    });

    if (!(inRange && slotFree && matches)) {
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
                  if (_draggingPiece != null && _hoveredSlot != null)
                    Positioned.fromRect(
                      rect: Rect.fromLTWH(
                        _slotTopLeft(_hoveredSlot!).dx,
                        _slotTopLeft(_hoveredSlot!).dy,
                        _pieceSideSnap,
                        _pieceSideSnap,
                      ),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: (_hoveredSlot == _draggingPiece &&
                                    _slotOwner[_hoveredSlot!] == null)
                                ? InkPalette.reed.withValues(alpha: 0.22)
                                : InkPalette.vermilion.withValues(alpha: 0.18),
                            border: Border.all(
                              color: (_hoveredSlot == _draggingPiece &&
                                      _slotOwner[_hoveredSlot!] == null)
                                  ? InkPalette.reed
                                  : InkPalette.vermilion,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
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
                      snapSide: _pieceSideSnap,
                      parkSide: _pieceSidePark,
                      position: _piecePos[i]!,
                      snapped: _snapped.contains(i),
                      shaking: _shakingPiece == i,
                      dragging: _draggingPiece == i,
                      onDragStart: () => _handleDragStart(i),
                      onDragUpdate: (Offset p) => _handleDragUpdate(i, p),
                      onDragEnd: (Offset p) => _handleDragEnd(i, p),
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
    required this.snapSide,
    required this.parkSide,
    required this.position,
    required this.snapped,
    required this.shaking,
    required this.dragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final String image;
  final int row;
  final int col;
  final int n;
  final double snapSide;
  final double parkSide;
  final Offset position;
  final bool snapped;
  final bool shaking;
  final bool dragging;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
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
    final double side =
        widget.snapped ? widget.snapSide : widget.parkSide;
    return AnimatedPositioned(
      duration: widget.dragging
          ? Duration.zero
          : (widget.snapped
              ? const Duration(milliseconds: 260)
              : const Duration(milliseconds: 180)),
      curve: Curves.easeOutBack,
      left: _pos.dx,
      top: _pos.dy,
      width: side,
      height: side,
      child: AnimatedBuilder(
        animation: _shakeCtrl,
        builder: (BuildContext ctx, Widget? child) {
          final double t = _shakeCtrl.value;
          final double dx =
              widget.shaking ? math.sin(t * math.pi * 6) * 6 * (1 - t) : 0;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart:
              widget.snapped ? null : (_) => widget.onDragStart(),
          onPanUpdate: widget.snapped
              ? null
              : (DragUpdateDetails d) {
                  setState(() => _pos += d.delta);
                  widget.onDragUpdate(_pos);
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
                    : (widget.dragging
                        ? InkPalette.ochre
                        : InkPalette.ink.withValues(alpha: 0.45)),
                width: widget.shaking || widget.dragging ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: widget.snapped
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: widget.dragging ? 8 : 4,
                        offset: Offset(0, widget.dragging ? 4 : 2),
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
                  width: side * widget.n,
                  height: side * widget.n,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
