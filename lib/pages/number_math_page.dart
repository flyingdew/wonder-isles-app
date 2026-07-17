import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/achievement.dart';
import '../data/number_math.dart';
import '../services/progress_store.dart';
import '../services/voice_service.dart';
import '../widgets/achievement_dialog.dart';

/// 数之岛收官：小铺算术。
///
/// 5 天点亮后开放；6 道加减混合题，答对全部方可标记完成并解锁
/// numbers_math 成就。答错只有轻微反馈 + 允许重试，不推进计数。
class NumberMathPage extends StatefulWidget {
  const NumberMathPage({super.key});

  @override
  State<NumberMathPage> createState() => _NumberMathPageState();
}

class _NumberMathPageState extends State<NumberMathPage>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int? _shake;
  int? _picked;
  bool _finished = false;
  late final AnimationController _celebrateCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VoiceService>().stopBgm();
    });
  }

  @override
  void dispose() {
    _celebrateCtrl.dispose();
    super.dispose();
  }

  MathQuestion get _q => kMathQuestions[_index];
  int get _total => kMathQuestions.length;

  void _pick(int value) {
    if (_finished) return;
    if (_picked != null) return;
    final bool correct = value == _q.answer;
    final VoiceService voice = context.read<VoiceService>();
    if (!correct) {
      voice.playSfx('wrong');
      HapticFeedback.selectionClick();
      setState(() => _shake = value);
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        if (_shake == value) setState(() => _shake = null);
      });
      return;
    }
    voice.playSfx('chime');
    HapticFeedback.lightImpact();
    setState(() => _picked = value);
    Future<void>.delayed(const Duration(milliseconds: 550), () async {
      if (!mounted) return;
      if (_index + 1 < _total) {
        setState(() {
          _index += 1;
          _picked = null;
          _shake = null;
        });
      } else {
        setState(() => _finished = true);
        voice.playSfx('sparkle');
        HapticFeedback.mediumImpact();
        _celebrateCtrl.forward(from: 0);
        final List<Achievement> unlocked =
            await context.read<ProgressStore>().markNumberMathDone();
        if (!mounted) return;
        await showAchievementUnlocked(context, unlocked);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小铺算术 · 加减合练',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: _finished
              ? _DoneView(controller: _celebrateCtrl,
                  onExit: () => Navigator.of(context).pop(true))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _ProgressDots(index: _index, total: _total),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _QuestionCard(
                        question: _q,
                        picked: _picked,
                        shake: _shake,
                        onPick: _pick,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.index, required this.total});
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < index
                  ? InkPalette.vermilion
                  : (i == index
                      ? InkPalette.glow
                      : InkPalette.inkSoft.withValues(alpha: 0.25)),
              border: Border.all(
                  color: InkPalette.ink.withValues(alpha: 0.25), width: 1),
            ),
          ),
      ],
    );
  }
}
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.picked,
    required this.shake,
    required this.onPick,
  });

  final MathQuestion question;
  final int? picked;
  final int? shake;
  final void Function(int value) onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: InkPalette.paperDeep.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InkPalette.ink.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            question.prompt,
            style: const TextStyle(
              fontSize: 17,
              height: 1.6,
              color: InkPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _GoodsRow(question: question),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: <Widget>[
              for (final int opt in question.options)
                _AnswerChip(
                  value: opt,
                  correct: picked == opt,
                  shaking: shake == opt,
                  disabled: picked != null,
                  onTap: () => onPick(opt),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoodsRow extends StatelessWidget {
  const _GoodsRow({required this.question});
  final MathQuestion question;

  @override
  Widget build(BuildContext context) {
    const double size = 52;
    if (question.isAdd) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _GoodsCluster(count: question.a, assetPath: question.assetPath, size: size),
          const _OpGlyph(text: '+'),
          _GoodsCluster(count: question.b, assetPath: question.assetPath, size: size),
          const _OpGlyph(text: '='),
          const _QMark(),
        ],
      );
    }
    // 减法：a 个中把最后 b 个划掉。
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < question.a; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _GoodsCell(
              assetPath: question.assetPath,
              size: size,
              crossed: i >= question.a - question.b,
            ),
          ),
        const _OpGlyph(text: '='),
        const _QMark(),
      ],
    );
  }
}

class _GoodsCluster extends StatelessWidget {
  const _GoodsCluster({required this.count, required this.assetPath, required this.size});
  final int count;
  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _GoodsCell(assetPath: assetPath, size: size),
          ),
      ],
    );
  }
}

class _GoodsCell extends StatelessWidget {
  const _GoodsCell({
    required this.assetPath,
    required this.size,
    this.crossed = false,
  });
  final String assetPath;
  final double size;
  final bool crossed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(
            opacity: crossed ? 0.4 : 1.0,
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
          if (crossed)
            CustomPaint(
              size: Size(size, size),
              painter: _StrikePainter(),
            ),
        ],
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = InkPalette.vermilion.withValues(alpha: 0.85)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.15),
        Offset(size.width * 0.85, size.height * 0.85), p);
    canvas.drawLine(Offset(size.width * 0.85, size.height * 0.15),
        Offset(size.width * 0.15, size.height * 0.85), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OpGlyph extends StatelessWidget {
  const _OpGlyph({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: InkPalette.ink,
        ),
      ),
    );
  }
}

class _QMark extends StatelessWidget {
  const _QMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: InkPalette.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: InkPalette.ink.withValues(alpha: 0.35), width: 2),
      ),
      child: const Text(
        '?',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: InkPalette.ink,
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({
    required this.value,
    required this.correct,
    required this.shaking,
    required this.disabled,
    required this.onTap,
  });
  final int value;
  final bool correct;
  final bool shaking;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: shaking ? 1 : 0),
      duration: const Duration(milliseconds: 320),
      builder: (BuildContext c, double s, Widget? _) {
        final double dx = shaking ? math.sin(s * math.pi * 6) * 6 * (1 - s) : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Material(
            color: correct
                ? InkPalette.glow.withValues(alpha: 0.9)
                : (shaking
                    ? InkPalette.vermilion.withValues(alpha: 0.15)
                    : InkPalette.paper),
            borderRadius: BorderRadius.circular(12),
            elevation: correct ? 3 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: disabled ? null : onTap,
              child: Container(
                width: 76,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: correct
                        ? InkPalette.ochre
                        : InkPalette.ink.withValues(alpha: 0.35),
                    width: correct ? 2 : 1.2,
                  ),
                ),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: InkPalette.ink,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.controller, required this.onExit});
  final AnimationController controller;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext ctx, _) {
        final double t = Curves.easeOut.transform(controller.value);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Opacity(
              opacity: t,
              child: const Icon(Icons.emoji_events_outlined,
                  size: 64, color: InkPalette.vermilion),
            ),
            const SizedBox(height: 14),
            Text(
              '算术小铺 · 六题过关',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color.lerp(
                    InkPalette.ink, InkPalette.vermilion, t * 0.6)!,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '加也顺，减也顺，云上小铺，数得心中。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: InkPalette.inkSoft,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: FilledButton(
                onPressed: onExit,
                child: const Text('回到岛上'),
              ),
            ),
          ],
        );
      },
    );
  }
}