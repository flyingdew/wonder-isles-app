import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/achievement.dart';
import '../services/progress_store.dart';
import '../services/voice_service.dart';
import '../widgets/achievement_dialog.dart';

/// 数之岛章末顺口溜。
///
/// 五句一次一句地缓入，配 chime；全部呈现后触发 `markPoemDone('numbers_isle')`。
/// 复用与字之岛 Boss 长诗一致的仪式感（纸底 + 中文竖排感的居中排版）。
class NumberPoemPage extends StatefulWidget {
  const NumberPoemPage({super.key});

  static const List<String> lines = <String>[
    '一叶落',
    '二鸟啼',
    '三月里',
    '四时新',
    '五指连心，掌心生光。',
  ];
  static const String sceneKey = 'numbers_isle';

  @override
  State<NumberPoemPage> createState() => _NumberPoemPageState();
}

class _NumberPoemPageState extends State<NumberPoemPage> {
  int _revealed = 0;
  Timer? _timer;
  bool _celebrated = false;

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
    context.read<VoiceService>().playSfx('page');
    _timer = Timer.periodic(const Duration(milliseconds: 900), (Timer t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_revealed >= NumberPoemPage.lines.length) {
        t.cancel();
        await _celebrate();
        return;
      }
      setState(() => _revealed += 1);
      context.read<VoiceService>().playSfx('chime');
    });
  }

  Future<void> _celebrate() async {
    if (_celebrated) return;
    _celebrated = true;
    context.read<VoiceService>().playSfx('sparkle');
    final List<Achievement> unlocked =
        await context.read<ProgressStore>().markPoemDone(NumberPoemPage.sceneKey);
    if (!mounted) return;
    await showAchievementUnlocked(context, unlocked);
  }

  @override
  Widget build(BuildContext context) {
    final bool allShown = _revealed >= NumberPoemPage.lines.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('数之岛 · 顺口溜',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              const Text('小铺关门了，掌柜哼一段小顺口溜。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: InkPalette.inkSoft)),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    color: InkPalette.paperDeep.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: InkPalette.ink.withValues(alpha: 0.15)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (int i = 0; i < NumberPoemPage.lines.length; i++) ...<Widget>[
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: i < _revealed ? 1 : 0,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 500),
                              offset: i < _revealed
                                  ? Offset.zero
                                  : const Offset(0, 0.15),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  NumberPoemPage.lines[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: i == NumberPoemPage.lines.length - 1 ? 22 : 26,
                                    fontWeight: FontWeight.w700,
                                    color: InkPalette.ink,
                                    letterSpacing: 6,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: allShown ? () => Navigator.of(context).pop() : null,
                child: Text(allShown ? '收摊回岛' : '细细品…'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}