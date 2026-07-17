import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/number_entry.dart';
import '../services/voice_service.dart';
import 'number_glyph.dart';

/// 数之岛第二步：配一配。
///
/// 货架上摆着 `entry.value + 2` 件同款商品（1-5 上限至多 7），孩子从货架拖
/// 到箩筐里；数量到 `entry.value` 时可继续。多拖不给过、可以再点回货架。
class MakeStage extends StatefulWidget {
  const MakeStage({
    super.key,
    required this.entry,
    required this.onDone,
  });

  final NumberEntry entry;
  final VoidCallback onDone;

  @override
  State<MakeStage> createState() => _MakeStageState();
}

class _MakeStageState extends State<MakeStage>
    with SingleTickerProviderStateMixin {
  final Set<int> _takenIds = <int>{};
  late AnimationController _shakeCtrl;
  bool _rejectHint = false;

  int get _target => widget.entry.value;
  int get _shelfSize {
    // 目标数量 + 2 件多余货，最多 7 件避免铺不下。
    final int raw = _target + 2;
    return raw > 7 ? 7 : raw;
  }

  bool get _exactMatch => _takenIds.length == _target;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _put(int idx) {
    if (_takenIds.contains(idx)) return;
    if (_takenIds.length >= _target) {
      _bounce();
      return;
    }
    setState(() => _takenIds.add(idx));
    if (_exactMatch) {
      HapticFeedback.mediumImpact();
      context.read<VoiceService>().playSfx('chime');
    } else {
      HapticFeedback.selectionClick();
      context.read<VoiceService>().playSfx('brush');
    }
  }

  void _take(int idx) {
    if (!_takenIds.contains(idx)) return;
    setState(() => _takenIds.remove(idx));
    HapticFeedback.lightImpact();
  }

  void _bounce() {
    HapticFeedback.lightImpact();
    setState(() => _rejectHint = true);
    _shakeCtrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _rejectHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final NumberEntry e = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '顾客要 ${e.value} 个 ${e.good.name}，把货架上的 ${e.good.name} 拖进箩筐。',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: InkPalette.inkSoft),
        ),
        const SizedBox(height: 14),
        _Counter(count: _takenIds.length, total: _target),
        const SizedBox(height: 14),
        Expanded(
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: _Shelf(
                  size: _shelfSize,
                  taken: _takenIds,
                  entry: e,
                  onDragEndOutside: _bounce,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 5,
                child: _shakeWrapper(
                  child: _Basket(
                    taken: _takenIds.toList(),
                    entry: e,
                    target: _target,
                    rejectHint: _rejectHint,
                    onAccept: _put,
                    onTapChip: _take,
                    willAccept: () => _takenIds.length < _target,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _exactMatch ? widget.onDone : null,
          child: Text(_exactMatch
              ? '配好了 · 继续'
              : (_takenIds.length > _target
                  ? '多了，先点箩筐里的取回'
                  : '再放 ${_target - _takenIds.length} 个')),
        ),
      ],
    );
  }

  Widget _shakeWrapper({required Widget child}) {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (BuildContext ctx, Widget? c) {
        // 一个短暂的水平左右抖动：sin(3π * t) * 6px * (1 - t)
        final double t = _shakeCtrl.value;
        final double dx = t == 0 ? 0 : 6 * (1 - t) * math.sin(3 * math.pi * t);
        return Transform.translate(offset: Offset(dx, 0), child: c);
      },
      child: child,
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.count, required this.total});
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final bool over = count > total;
    final bool ok = count == total;
    final Color bg = ok
        ? InkPalette.glow.withValues(alpha: 0.8)
        : (over
            ? InkPalette.vermilion.withValues(alpha: 0.15)
            : InkPalette.paperDeep);
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: InkPalette.ink.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              ok
                  ? Icons.check_circle
                  : (over ? Icons.error_outline : Icons.shopping_basket_outlined),
              size: 18,
              color: ok
                  ? InkPalette.ink
                  : (over ? InkPalette.vermilion : InkPalette.vermilion),
            ),
            const SizedBox(width: 8),
            Text('箩筐里 $count / $total',
                style: const TextStyle(
                  fontSize: 16,
                  color: InkPalette.ink,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                )),
          ],
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.size,
    required this.taken,
    required this.entry,
    required this.onDragEndOutside,
  });
  final int size;
  final Set<int> taken;
  final NumberEntry entry;
  final VoidCallback onDragEndOutside;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: InkPalette.paperDeep.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: InkPalette.ink.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('货架',
                style: TextStyle(
                  color: InkPalette.inkSoft,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    for (int i = 0; i < size; i++)
                      _ShelfItem(
                        idx: i,
                        entry: entry,
                        taken: taken.contains(i),
                        onDragEndOutside: onDragEndOutside,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShelfItem extends StatelessWidget {
  const _ShelfItem({
    required this.idx,
    required this.entry,
    required this.taken,
    required this.onDragEndOutside,
  });
  final int idx;
  final NumberEntry entry;
  final bool taken;
  final VoidCallback onDragEndOutside;

  @override
  Widget build(BuildContext context) {
    if (taken) {
      return NumberGlyph(
        label: entry.good.label,
        colorKey: entry.good.colorKey,
        size: 56,
        dim: true,
      );
    }
    final NumberGlyph glyph = NumberGlyph(
      label: entry.good.label,
      colorKey: entry.good.colorKey,
      size: 56,
    );
    return Draggable<int>(
      data: idx,
      feedback: Material(
        color: Colors.transparent,
        child: NumberGlyph(
          label: entry.good.label,
          colorKey: entry.good.colorKey,
          size: 64,
        ),
      ),
      childWhenDragging: NumberGlyph(
        label: entry.good.label,
        colorKey: entry.good.colorKey,
        size: 56,
        dim: true,
      ),
      onDraggableCanceled: (_, __) => onDragEndOutside(),
      child: glyph,
    );
  }
}

class _Basket extends StatelessWidget {
  const _Basket({
    required this.taken,
    required this.entry,
    required this.target,
    required this.rejectHint,
    required this.onAccept,
    required this.onTapChip,
    required this.willAccept,
  });
  final List<int> taken;
  final NumberEntry entry;
  final int target;
  final bool rejectHint;
  final ValueChanged<int> onAccept;
  final ValueChanged<int> onTapChip;
  final bool Function() willAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => willAccept(),
      onAcceptWithDetails: (DragTargetDetails<int> d) => onAccept(d.data),
      builder: (BuildContext ctx, List<int?> candidate, List<dynamic> rej) {
        final bool active = candidate.isNotEmpty && willAccept();
        final bool blocked = candidate.isNotEmpty && !willAccept();
        final Color border = blocked
            ? InkPalette.vermilion
            : (active
                ? InkPalette.reed
                : InkPalette.ink.withValues(alpha: 0.25));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: rejectHint
                ? InkPalette.vermilion.withValues(alpha: 0.08)
                : InkPalette.paperDeep.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text('箩筐',
                        style: TextStyle(
                          color: InkPalette.inkSoft,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 8),
                    Text(
                      blocked ? '已经够啦' : (active ? '放这里' : '拖进来'),
                      style: TextStyle(
                        color: blocked
                            ? InkPalette.vermilion
                            : (active
                                ? InkPalette.reed
                                : InkPalette.inkSoft.withValues(alpha: 0.6)),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: taken.isEmpty
                      ? Center(
                          child: Text(
                            '空空的\n拖 $target 个 ${entry.good.name} 过来',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: InkPalette.inkSoft
                                  .withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            for (final int i in taken)
                              GestureDetector(
                                onTap: () => onTapChip(i),
                                child: NumberGlyph(
                                  label: entry.good.label,
                                  colorKey: entry.good.colorKey,
                                  size: 52,
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}