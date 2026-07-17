import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/number_entry.dart';
import '../services/progress_store.dart';
import '../services/voice_service.dart';
import '../widgets/count_stage.dart';
import '../widgets/make_stage.dart';
import '../widgets/change_stage.dart';
import '../widgets/number_glyph.dart';

enum NumberFlowStep { count, make, change, done }

/// 数之岛一局：数一数 → 配一配 → 找零 → 点亮。
class NumberFlowPage extends StatefulWidget {
  const NumberFlowPage({super.key, required this.entry});
  final NumberEntry entry;

  @override
  State<NumberFlowPage> createState() => _NumberFlowPageState();
}

class _NumberFlowPageState extends State<NumberFlowPage> {
  NumberFlowStep _step = NumberFlowStep.count;
  VoiceService? _voice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voice = context.read<VoiceService>();
  }

  @override
  Widget build(BuildContext context) {
    final NumberEntry e = widget.entry;
    return Scaffold(
      appBar: AppBar(
        title: Text('${e.char} · ${e.pinyin}'),
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
          child: _buildStage(e),
        ),
      ),
    );
  }

  Widget _buildStage(NumberEntry e) {
    switch (_step) {
      case NumberFlowStep.count:
        return CountStage(
          entry: e,
          onDone: () => setState(() => _step = NumberFlowStep.make),
        );
      case NumberFlowStep.make:
        return MakeStage(
          entry: e,
          onDone: () => setState(() => _step = NumberFlowStep.change),
        );
      case NumberFlowStep.change:
        return ChangeStage(
          entry: e,
          onDone: _onFinish,
        );
      case NumberFlowStep.done:
        return _Celebration(entry: e, onExit: () => Navigator.of(context).pop<String>(e.id));
    }
  }

  Future<void> _onFinish() async {
    await context.read<ProgressStore>().markNumberLit(widget.entry.id);
    if (!mounted) return;
    setState(() => _step = NumberFlowStep.done);
  }

  @override
  void deactivate() {
    _voice?.stop();
    super.deactivate();
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final NumberFlowStep step;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['数', '配', '找'];
    final int idx = step.index.clamp(0, 2);
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

class _Celebration extends StatelessWidget {
  const _Celebration({required this.entry, required this.onExit});
  final NumberEntry entry;
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
            child: Text(entry.char,
                style: const TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w700,
                  color: InkPalette.ink,
                )),
          ),
          const SizedBox(height: 20),
          const Text('这一天圆满收摊！',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(entry.rhyme,
              textAlign: TextAlign.center,
              style: const TextStyle(color: InkPalette.inkSoft, height: 1.5)),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              NumberGlyph(
                label: entry.good.label,
                colorKey: entry.good.colorKey,
                size: 44,
              ),
              const SizedBox(width: 12),
              Text('× ${entry.value}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: InkPalette.ink,
                  )),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onExit, child: const Text('回到小铺')),
        ],
      ),
    );
  }
}