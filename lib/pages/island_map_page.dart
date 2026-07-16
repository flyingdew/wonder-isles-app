import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../data/character_repository.dart';
import '../data/poems.dart';
import '../services/progress_store.dart';
import '../services/voice_service.dart';
import 'poem_stage_page.dart';
import 'scene_page.dart';

class IslandMapPage extends StatefulWidget {
  const IslandMapPage({super.key});

  @override
  State<IslandMapPage> createState() => _IslandMapPageState();
}

class _IslandMapPageState extends State<IslandMapPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VoiceService>().stopBgm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final CharacterRepository repo = context.read<CharacterRepository>();
    final ProgressStore progress = context.watch<ProgressStore>();

    final bool allScenePoemsDone = SceneId.values
        .every((SceneId s) => progress.isPoemDone(s.key));
    final bool bossUnlocked =
        allScenePoemsDone || (kDebugMode && kIsWeb);
    final bool bossDone = progress.isPoemDone(kBossPoem.sceneKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('字之岛 · 万物有形',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          for (final SceneId scene in SceneId.values) ...<Widget>[
            _sceneCardOf(context, repo, progress, scene),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          _BossEntry(
            unlocked: bossUnlocked,
            done: bossDone,
            onEnter: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const PoemStagePage.forPoem(poem: kBossPoem),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _sceneCardOf(BuildContext ctx, CharacterRepository repo,
      ProgressStore progress, SceneId scene) {
    final List<WonderCharacter> chars = repo.forScene(scene);
    final int lit =
        chars.where((WonderCharacter c) => progress.isLit(c.id)).length;
    final bool poemDone = progress.isPoemDone(scene.key);
    return _SceneCard(
      scene: scene,
      characters: chars,
      lit: lit,
      poemDone: poemDone,
      onTap: () {
        Navigator.of(ctx).push(MaterialPageRoute<void>(
          builder: (_) => ScenePage(scene: scene),
        ));
      },
    );
  }
}

class _BossEntry extends StatelessWidget {
  const _BossEntry({
    required this.unlocked,
    required this.done,
    required this.onEnter,
  });
  final bool unlocked;
  final bool done;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final Color bg = done
        ? InkPalette.glow.withValues(alpha: 0.95)
        : (unlocked
            ? InkPalette.dusk
            : InkPalette.paperDeep.withValues(alpha: 0.85));
    final Color fg = done ? InkPalette.ink : InkPalette.paper;
    final Color fgDim = done ? InkPalette.inkSoft : InkPalette.paper.withValues(alpha: 0.75);
    final IconData icon = done
        ? Icons.auto_awesome
        : (unlocked ? Icons.menu_book : Icons.lock_outline);
    final String label = done
        ? '重温万物有形'
        : (unlocked ? '进入章末长诗' : '完成四场景小诗后开启');
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: unlocked ? onEnter : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: <Widget>[
              Icon(icon,
                  color: unlocked ? fg : InkPalette.inkSoft, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('万物有形 · 章末长诗',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: unlocked ? fg : InkPalette.ink,
                          letterSpacing: 2,
                        )),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                          color: unlocked ? fgDim : InkPalette.inkSoft,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: unlocked ? fg : InkPalette.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.characters,
    required this.lit,
    required this.poemDone,
    required this.onTap,
  });

  final SceneId scene;
  final List<WonderCharacter> characters;
  final int lit;
  final bool poemDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: InkPalette.paperDeep,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 168,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(scene.background, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      Color(0xE6F6EEDD),
                      Color(0x00F6EEDD),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(scene.label,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: InkPalette.ink,
                          letterSpacing: 4,
                        )),
                    const SizedBox(height: 4),
                    Text('已点亮 $lit / ${characters.length} 字',
                        style: const TextStyle(color: InkPalette.inkSoft)),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      children: <Widget>[
                        for (final WonderCharacter c in characters)
                          _CharChip(char: c.char, lit: _isLit(context, c.id)),
                      ],
                    ),
                  ],
                ),
              ),
              if (poemDone)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: InkPalette.glow.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: InkPalette.ink.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.auto_stories,
                            size: 14, color: InkPalette.ink),
                        SizedBox(width: 4),
                        Text('诗成',
                            style: TextStyle(
                              fontSize: 12,
                              color: InkPalette.ink,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLit(BuildContext context, String id) =>
      context.read<ProgressStore>().isLit(id);
}

class _CharChip extends StatelessWidget {
  const _CharChip({required this.char, required this.lit});
  final String char;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lit ? InkPalette.glow.withValues(alpha: 0.85) : Colors.white70,
        border: Border.all(color: InkPalette.ink.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(char,
          style: TextStyle(
            fontSize: 18,
            color: lit ? InkPalette.ink : InkPalette.inkSoft,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}
