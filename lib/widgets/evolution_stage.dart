import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../services/voice_service.dart';

/// 演变：4 张字形帧顺序过渡，同时播 TTS 与字幕。
class EvolutionStage extends StatefulWidget {
  const EvolutionStage({super.key, required this.character, required this.onDone});
  final WonderCharacter character;
  final VoidCallback onDone;

  @override
  State<EvolutionStage> createState() => _EvolutionStageState();
}

class _EvolutionStageState extends State<EvolutionStage> {
  static const List<String> _labels = <String>['甲骨', '金文', '小篆', '楷书'];
  int _index = 0;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    unawaited(context.read<VoiceService>().play(widget.character.voiceAsset));
    for (int i = 1; i < _labels.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() => _index = i);
    }
    if (!mounted) return;
    setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final WonderCharacter c = widget.character;
    return Column(
      children: <Widget>[
        Text('${_labels[_index]} · ${c.pinyin}',
            style: const TextStyle(fontSize: 16, color: InkPalette.inkSoft)),
        const SizedBox(height: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InkPalette.paperDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOut,
                child: Image.asset(
                  c.evolutionFrames[_index],
                  key: ValueKey<int>(_index),
                  fit: BoxFit.contain,
                ),
              ),
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
          child: Text(c.story,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: InkPalette.ink,
              )),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _playing ? null : widget.onDone,
          child: Text(_playing ? '演变中…' : '继续'),
        ),
      ],
    );
  }
}
