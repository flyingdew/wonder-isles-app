import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/number_entry.dart';
import '../services/voice_service.dart';
import 'number_glyph.dart';

/// 数之岛第三步：找零。
///
/// 顾客给一枚 `entry.change.given` 面值的大贝币，商品价 `entry.change.price`；
/// 孩子从"钱盘"里点选 1 / 2 / 5 面值的小贝币，累加到差额即可。
///
/// v0 只允许点选累加，不做拖拽。多点了让最后一枚回弹并轻抖，避免惩罚。
class ChangeStage extends StatefulWidget {
  const ChangeStage({
    super.key,
    required this.entry,
    required this.onDone,
  });

  final NumberEntry entry;
  final VoidCallback onDone;

  @override
  State<ChangeStage> createState() => _ChangeStageState();
}

class _ChangeStageState extends State<ChangeStage>
    with SingleTickerProviderStateMixin {
  static const List<int> _denominations = <int>[1, 2, 5];

  final List<int> _paid = <int>[];
  late AnimationController _shakeCtrl;

  int get _need => widget.entry.change.diff;
  int get _current => _paid.fold(0, (int a, int b) => a + b);
  bool get _ok => _current == _need;

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

  void _tapCoin(int face) {
    if (_current + face > _need) {
      HapticFeedback.lightImpact();
      _shakeCtrl.forward(from: 0);
      return;
    }
    setState(() => _paid.add(face));
    if (_current == _need) {
      HapticFeedback.mediumImpact();
      context.read<VoiceService>().playSfx('chime');
    } else {
      HapticFeedback.selectionClick();
      context.read<VoiceService>().playSfx('brush');
    }
  }

  void _undoLast() {
    if (_paid.isEmpty) return;
    setState(() => _paid.removeLast());
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final NumberEntry e = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ReceiptCard(entry: e, current: _current, need: _need),
        const SizedBox(height: 14),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InkPalette.paperDeep,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: InkPalette.ink.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  const Text('已找回',
                      style: TextStyle(
                        color: InkPalette.inkSoft,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _shakeWrapper(
                      child: _ChangeTray(paid: _paid, need: _need),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _paid.isEmpty ? null : _undoLast,
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('撤一枚'),
                      style: TextButton.styleFrom(
                          foregroundColor: InkPalette.inkSoft),
                    ),
                  ),
                  const Divider(color: InkPalette.paper, height: 8),
                  const SizedBox(height: 8),
                  const Text('钱盘',
                      style: TextStyle(
                        color: InkPalette.inkSoft,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      for (final int face in _denominations)
                        _CoinButton(
                          face: face,
                          disabled: _current + face > _need,
                          onTap: () => _tapCoin(face),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _ok ? widget.onDone : null,
          child: Text(_ok
              ? '找齐了 · 继续'
              : '再凑 ${_need - _current} 贝币'),
        ),
      ],
    );
  }

  Widget _shakeWrapper({required Widget child}) {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (BuildContext ctx, Widget? c) {
        final double t = _shakeCtrl.value;
        final double dx = t == 0 ? 0 : 6 * (1 - t) * math.sin(3 * math.pi * t);
        return Transform.translate(offset: Offset(dx, 0), child: c);
      },
      child: child,
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.entry,
    required this.current,
    required this.need,
  });
  final NumberEntry entry;
  final int current;
  final int need;

  @override
  Widget build(BuildContext context) {
    final bool ok = current == need;
    final bool over = current > need;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: InkPalette.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InkPalette.ink.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _BigCoin(face: entry.change.given, glow: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('顾客给了 ${entry.change.given} 贝币',
                        style: const TextStyle(
                          fontSize: 15,
                          color: InkPalette.ink,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 2),
                    Text(
                        '${entry.value} 个 ${entry.good.name} · 每个 1 贝币 · 共 ${entry.change.price} 贝币',
                        style: const TextStyle(
                          color: InkPalette.inkSoft,
                          fontSize: 12,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text('要找 $need 贝币',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: InkPalette.vermilion,
                    letterSpacing: 1,
                  )),
              const Spacer(),
              Text(
                ok
                    ? '刚好 · $current'
                    : (over ? '多了 $current' : '已凑 $current'),
                style: TextStyle(
                  color: ok
                      ? InkPalette.reed
                      : (over
                          ? InkPalette.vermilion
                          : InkPalette.inkSoft),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeTray extends StatelessWidget {
  const _ChangeTray({required this.paid, required this.need});
  final List<int> paid;
  final int need;

  @override
  Widget build(BuildContext context) {
    if (paid.isEmpty) {
      return Center(
        child: Text(
          '钱盘上还没有贝币\n点下方的 1 / 2 / 5 凑到 $need',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: InkPalette.inkSoft.withValues(alpha: 0.75), height: 1.5),
        ),
      );
    }
    return SingleChildScrollView(
      child: Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final int face in paid) _SmallCoin(face: face),
          ],
        ),
      ),
    );
  }
}

class _CoinButton extends StatelessWidget {
  const _CoinButton({
    required this.face,
    required this.disabled,
    required this.onTap,
  });
  final int face;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: _BigCoin(face: face, glow: !disabled),
      ),
    );
  }
}

class _BigCoin extends StatelessWidget {
  const _BigCoin({required this.face, required this.glow});
  final int face;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return CoinGlyph(face: face, size: 72, glow: glow);
  }
}

class _SmallCoin extends StatelessWidget {
  const _SmallCoin({required this.face});
  final int face;

  @override
  Widget build(BuildContext context) {
    return CoinGlyph(face: face, size: 44);
  }
}