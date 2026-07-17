import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 数之岛的占位阶段：给 make（配一配）/ change（找零）两步用。
/// v0 只保证能走通闭环，把真正的交互放到下一轮迭代。
class NumberTodoStage extends StatelessWidget {
  const NumberTodoStage({
    super.key,
    required this.title,
    required this.hint,
    required this.onDone,
  });

  final String title;
  final String hint;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: InkPalette.ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: const TextStyle(color: InkPalette.inkSoft),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InkPalette.paperDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: InkPalette.ink.withValues(alpha: 0.12)),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '这一步的交互正在打磨中。\n先点下方按钮跳过，走完整个闭环。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: InkPalette.inkSoft,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onDone, child: const Text('先跳过 · 继续')),
      ],
    );
  }
}