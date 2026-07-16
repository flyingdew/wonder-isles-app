import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../services/progress_store.dart';
import '../data/achievement.dart';
import '../services/voice_service.dart';
import '../widgets/achievement_dialog.dart';
import '../widgets/apply_stage.dart';
import '../widgets/assemble_stage.dart';
import '../widgets/dig_stage.dart';
import '../widgets/evolution_stage.dart';

enum FlowStep { dig, assemble, evolve, apply, done }

class CharacterFlowPage extends StatefulWidget {
  const CharacterFlowPage({super.key, required this.character});
  final WonderCharacter character;

  @override
  State<CharacterFlowPage> createState() => _CharacterFlowPageState();
}

class _CharacterFlowPageState extends State<CharacterFlowPage> {
  FlowStep _step = FlowStep.dig;
  VoiceService? _voice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voice = context.read<VoiceService>();
  }

  @override
  Widget build(BuildContext context) {
    final WonderCharacter c = widget.character;
    return Scaffold(
      appBar: AppBar(
        title: Text('${c.char} · ${c.pinyin}'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _StepIndicator(step: _step)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildStage(c),
        ),
      ),
    );
  }

  Widget _buildStage(WonderCharacter c) {
    switch (_step) {
      case FlowStep.dig:
        return DigStage(
          character: c,
          onDone: () => setState(() => _step = FlowStep.assemble),
        );
      case FlowStep.assemble:
        return AssembleStage(
          character: c,
          gridSize: 2,
          onDone: () => setState(() => _step = FlowStep.evolve),
        );
      case FlowStep.evolve:
        return EvolutionStage(
          character: c,
          onDone: () => setState(() => _step = FlowStep.apply),
        );
      case FlowStep.apply:
        return ApplyStage(
          character: c,
          onDone: _onFinish,
        );
      case FlowStep.done:
        return _CelebrationView(character: c, onExit: () => Navigator.of(context).pop<String>(c.id));
    }
  }

  Future<void> _onFinish() async {
    final List<Achievement> unlocked =
        await context.read<ProgressStore>().markLit(widget.character.id);
    if (!mounted) return;
    setState(() => _step = FlowStep.done);
    if (!mounted) return;
    await showAchievementUnlocked(context, unlocked);
  }

  @override
  void deactivate() {
    // 离开页面时确保语音停下。
    _voice?.stop();
    super.deactivate();
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final FlowStep step;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['勘探', '拼合', '演变', '应用'];
    final int idx = step.index.clamp(0, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < labels.length; i++) ...<Widget>[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= idx ? InkPalette.vermilion : InkPalette.paperDeep,
            ),
            child: Text('${i + 1}',
                style: TextStyle(
                  color: i <= idx ? InkPalette.paper : InkPalette.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ),
          if (i < labels.length - 1)
            Container(
              width: 12,
              height: 2,
              color: i < idx ? InkPalette.vermilion : InkPalette.paperDeep,
            ),
        ],
      ],
    );
  }
}

class _CelebrationView extends StatelessWidget {
  const _CelebrationView({required this.character, required this.onExit});
  final WonderCharacter character;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  InkPalette.glow,
                  Color(0x00F2C56A),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(character.char,
                style: const TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w700,
                  color: InkPalette.ink,
                )),
          ),
          const SizedBox(height: 24),
          const Text('点亮成功！',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${character.char} · ${character.pinyin}',
              style: const TextStyle(color: InkPalette.inkSoft)),
          const SizedBox(height: 32),
          FilledButton(onPressed: onExit, child: const Text('回到岛上')),
        ],
      ),
    );
  }
}
