import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../data/character_repository.dart';
import '../services/progress_store.dart';
import 'character_flow_page.dart';
import 'poem_stage_page.dart';

/// 一个场景（河岸/山林/…）里的 5 个字入口。
class ScenePage extends StatelessWidget {
  const ScenePage({super.key, required this.scene});
  final SceneId scene;

  @override
  Widget build(BuildContext context) {
    final CharacterRepository repo = context.read<CharacterRepository>();
    final ProgressStore progress = context.watch<ProgressStore>();
    final List<WonderCharacter> chars = repo.forScene(scene);
    final int lit = chars.where((WonderCharacter c) => progress.isLit(c.id)).length;
    final bool allLit = lit == chars.length;
    final bool poemDone = progress.isPoemDone(scene.key);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(scene.label)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              InkPalette.paper.withValues(alpha: poemDone ? 0.15 : 0.35),
              BlendMode.lighten,
            ),
            child: Image.asset(scene.background, fit: BoxFit.cover),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Text(
                    poemDone
                        ? '小诗已成，此处已被点亮'
                        : (allLit ? '五字齐亮，可以试着写小诗了' : '点击一处可疑之地，开始挖掘'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: InkPalette.inkSoft,
                      fontSize: 15,
                      shadows: <Shadow>[
                        Shadow(
                          color: InkPalette.paper.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.9,
                      children: <Widget>[
                        for (final WonderCharacter c in chars)
                          _DigSpot(
                            character: c,
                            lit: progress.isLit(c.id),
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute<void>(
                                builder: (_) =>
                                    CharacterFlowPage(character: c),
                              ));
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PoemEntry(
                    allLit: allLit,
                    poemDone: poemDone,
                    onEnter: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => PoemStagePage.forScene(scene: scene),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoemEntry extends StatelessWidget {
  const _PoemEntry({
    required this.allLit,
    required this.poemDone,
    required this.onEnter,
  });
  final bool allLit;
  final bool poemDone;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final bool enabled = allLit;
    final String label = poemDone
        ? '重温小诗'
        : (enabled ? '进入小诗关' : '点亮全部 5 字后开启');
    final IconData icon = poemDone
        ? Icons.auto_stories
        : (enabled ? Icons.brush : Icons.lock_outline);
    return Material(
      color: poemDone
          ? InkPalette.glow.withValues(alpha: 0.9)
          : (enabled
              ? InkPalette.vermilion
              : InkPalette.paperDeep.withValues(alpha: 0.85)),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onEnter : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon,
                  color: enabled ? InkPalette.paper : InkPalette.inkSoft,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: poemDone
                      ? InkPalette.ink
                      : (enabled ? InkPalette.paper : InkPalette.inkSoft),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DigSpot extends StatelessWidget {
  const _DigSpot({
    required this.character,
    required this.lit,
    required this.onTap,
  });

  final WonderCharacter character;
  final bool lit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: lit
          ? InkPalette.glow.withValues(alpha: 0.85)
          : InkPalette.paperDeep.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: InkPalette.ink.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              lit
                  ? Text(character.char,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: InkPalette.ink,
                      ))
                  : const Icon(Icons.landscape_outlined,
                      size: 36, color: InkPalette.inkSoft),
              const SizedBox(height: 6),
              Text(
                lit ? character.pinyin : '土堆',
                style: const TextStyle(
                  color: InkPalette.inkSoft,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

