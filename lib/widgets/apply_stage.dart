import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../data/character_repository.dart';

/// 应用挑战：三选一填空。
///
/// 题面来自 quiz.text，例如 "太{blank}出来了"；正确答案是 quiz.answer。
/// 干扰项优先从当前字所在场景的其它字里挑（"离得近"），不足时兜底用全字库。
/// 极少数题目的 answer 本身不在字库中（如 "阳"、"树"），此时同场景其它字仍然是最佳干扰。
class ApplyStage extends StatefulWidget {
  const ApplyStage({super.key, required this.character, required this.onDone});
  final WonderCharacter character;
  final VoidCallback onDone;

  @override
  State<ApplyStage> createState() => _ApplyStageState();
}

class _ApplyStageState extends State<ApplyStage> {
  late final List<String> _options;
  String? _picked;

  @override
  void initState() {
    super.initState();
    final String correct = widget.character.quiz.answer;
    final CharacterRepository repo = context.read<CharacterRepository>();
    final math.Random rng = math.Random(widget.character.id.hashCode);

    final List<String> sameScene = repo
        .forScene(widget.character.scene)
        .where((WonderCharacter c) =>
            c.id != widget.character.id && c.char != correct)
        .map((WonderCharacter c) => c.char)
        .toList()
      ..shuffle(rng);

    final List<String> otherScenes = repo.all
        .where((WonderCharacter c) =>
            c.scene != widget.character.scene && c.char != correct)
        .map((WonderCharacter c) => c.char)
        .toList()
      ..shuffle(rng);

    final List<String> distractors = <String>[
      ...sameScene,
      ...otherScenes,
    ].where((String s) => s != correct).toList();

    _options = <String>[correct, distractors[0], distractors[1]]..shuffle(rng);
  }

  @override
  Widget build(BuildContext context) {
    final WonderCharacter c = widget.character;
    final bool correct = _picked == c.quiz.answer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('把正确的字填进去',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: InkPalette.inkSoft)),
        const SizedBox(height: 20),
        _ClozeText(text: c.quiz.text, filled: _picked),
        const Spacer(),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: <Widget>[
            for (final String opt in _options)
              _OptionTile(
                text: opt,
                state: _picked == null
                    ? _OptionState.idle
                    : opt == c.quiz.answer
                        ? _OptionState.correct
                        : opt == _picked
                            ? _OptionState.wrong
                            : _OptionState.idle,
                onTap: _picked == null
                    ? () => setState(() => _picked = opt)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: correct ? widget.onDone : null,
          child: const Text('点亮'),
        ),
        const SizedBox(height: 8),
        if (_picked != null && !correct)
          TextButton(
            onPressed: () => setState(() => _picked = null),
            child: const Text('再想想'),
          ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.text, required this.state, required this.onTap});
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = switch (state) {
      _OptionState.correct => InkPalette.glow,
      _OptionState.wrong => InkPalette.vermilion.withValues(alpha: 0.3),
      _OptionState.idle => InkPalette.paperDeep,
    };
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: InkPalette.ink.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 78,
          height: 78,
          child: Center(
            child: Text(text,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: InkPalette.ink,
                )),
          ),
        ),
      ),
    );
  }
}

class _ClozeText extends StatelessWidget {
  const _ClozeText({required this.text, required this.filled});
  final String text;
  final String? filled;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = text.split('{blank}');
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: InkPalette.ink,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (parts.isNotEmpty) Text(parts[0]),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: filled == null ? Colors.transparent : InkPalette.glow,
              border: Border(
                bottom: BorderSide(
                  color: InkPalette.ink.withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
            ),
            child: Text(filled ?? '　',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (parts.length > 1) Text(parts[1]),
        ],
      ),
    );
  }
}
