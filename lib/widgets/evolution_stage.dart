import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../services/voice_service.dart';

/// 演变：四种字形（甲骨/金文/小篆/楷书）铺成 2×2 网格，
/// 每隔一段间隔依次揭示一格，全部揭示后可继续。
class EvolutionStage extends StatefulWidget {
  const EvolutionStage(
      {super.key, required this.character, required this.onDone});
  final WonderCharacter character;
  final VoidCallback onDone;

  @override
  State<EvolutionStage> createState() => _EvolutionStageState();
}

class _EvolutionStageState extends State<EvolutionStage> {
  static const List<String> _labels = <String>['甲骨', '金文', '小篆', '楷书'];
  static const Duration _stepInterval = Duration(seconds: 2);

  int _revealed = 1; // 已揭示的帧数（第 1 帧一开始就在）
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    unawaited(context.read<VoiceService>().play(widget.character.voiceAsset));
    _timer = Timer.periodic(_stepInterval, (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_revealed >= _labels.length) {
        t.cancel();
        return;
      }
      context.read<VoiceService>().playSfx('chime');
      setState(() => _revealed += 1);
    });
  }

  bool get _allRevealed => _revealed >= _labels.length;

  @override
  Widget build(BuildContext context) {
    final WonderCharacter c = widget.character;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _allRevealed ? '${c.char} · ${c.pinyin}' : '字形演变中…',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: InkPalette.inkSoft),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InkPalette.paperDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints cons) {
                const double gap = 12;
                final double cellW = (cons.maxWidth - gap) / 2;
                final double cellH = (cons.maxHeight - gap) / 2;
                return Column(
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          _EvoCell(
                            label: _labels[0],
                            asset: c.evolutionFrames[0],
                            revealed: _revealed >= 1,
                            width: cellW,
                            height: cellH,
                          ),
                          const SizedBox(width: gap),
                          _EvoCell(
                            label: _labels[1],
                            asset: c.evolutionFrames[1],
                            revealed: _revealed >= 2,
                            width: cellW,
                            height: cellH,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: gap),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          _EvoCell(
                            label: _labels[2],
                            asset: c.evolutionFrames[2],
                            revealed: _revealed >= 3,
                            width: cellW,
                            height: cellH,
                          ),
                          const SizedBox(width: gap),
                          _EvoCell(
                            label: _labels[3],
                            asset: c.evolutionFrames[3],
                            revealed: _revealed >= 4,
                            width: cellW,
                            height: cellH,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: InkPalette.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: InkPalette.ink.withValues(alpha: 0.15)),
          ),
          child: Text(
            c.story,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: InkPalette.ink,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _allRevealed ? widget.onDone : null,
          child: Text(_allRevealed ? '继续' : '演变中…'),
        ),
      ],
    );
  }
}

class _EvoCell extends StatelessWidget {
  const _EvoCell({
    required this.label,
    required this.asset,
    required this.revealed,
    required this.width,
    required this.height,
  });

  final String label;
  final String asset;
  final bool revealed;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: InkPalette.paper.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: InkPalette.ink.withValues(alpha: 0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Column(
            children: <Widget>[
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 520),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: revealed
                      ? Padding(
                          key: const ValueKey<String>('img'),
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(asset, fit: BoxFit.contain),
                        )
                      : const _Veil(key: ValueKey<String>('veil')),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: revealed
                      ? InkPalette.ink
                      : InkPalette.inkSoft.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Veil extends StatelessWidget {
  const _Veil({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: InkPalette.paperDeep.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.hourglass_empty,
            size: 26, color: InkPalette.inkSoft),
      ),
    );
  }
}
