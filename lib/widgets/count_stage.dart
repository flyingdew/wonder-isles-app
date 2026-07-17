import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/number_entry.dart';
import '../services/voice_service.dart';
import 'number_glyph.dart';

/// 数之岛第一步：数一数。
///
/// 货架上摆着 [entry.value] 件同款商品；孩子挨个点击，每点一件累计 +1，
/// 全部点完后启用"下一步"按钮。为了让节奏可复现，商品位置固定不打乱。
class CountStage extends StatefulWidget {
  const CountStage({super.key, required this.entry, required this.onDone});
  final NumberEntry entry;
  final VoidCallback onDone;

  @override
  State<CountStage> createState() => _CountStageState();
}

class _CountStageState extends State<CountStage> {
  final Set<int> _tapped = <int>{};

  bool get _allTapped => _tapped.length >= widget.entry.value;

  void _handleTap(int i) {
    if (_tapped.contains(i)) return;
    setState(() => _tapped.add(i));
    HapticFeedback.selectionClick();
    context.read<VoiceService>().playSfx('chime');
  }

  @override
  Widget build(BuildContext context) {
    final NumberEntry e = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '货架上有几件 ${e.good.name}？点一点，数一数。',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: InkPalette.inkSoft),
        ),
        const SizedBox(height: 16),
        _CountBadge(count: _tapped.length, total: e.value),
        const SizedBox(height: 16),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InkPalette.paperDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (BuildContext ctx, BoxConstraints cons) {
                  return Center(
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        for (int i = 0; i < e.value; i++)
                          _CountItem(
                            label: e.good.label,
                            colorKey: e.good.colorKey,
                            tapped: _tapped.contains(i),
                            onTap: () => _handleTap(i),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _allTapped ? widget.onDone : null,
          child: Text(_allTapped ? '一共 ${e.value} 个 · 继续' : '再数一数…'),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.total});
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: InkPalette.paperDeep,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: InkPalette.ink.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.tag, size: 18, color: InkPalette.vermilion),
            const SizedBox(width: 8),
            Text(
              '已数 $count / $total',
              style: const TextStyle(
                fontSize: 16,
                color: InkPalette.ink,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountItem extends StatelessWidget {
  const _CountItem({
    required this.label,
    required this.colorKey,
    required this.tapped,
    required this.onTap,
  });
  final String label;
  final String colorKey;
  final bool tapped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: tapped ? 1.06 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: tapped
                ? <BoxShadow>[
                    BoxShadow(
                      color: InkPalette.glow.withValues(alpha: 0.7),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: NumberGlyph(
            label: label,
            colorKey: colorKey,
            size: 72,
            dim: !tapped,
          ),
        ),
      ),
    );
  }
}