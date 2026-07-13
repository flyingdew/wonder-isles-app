import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../data/character_repository.dart';
import '../services/progress_store.dart';
import 'scene_page.dart';

class IslandMapPage extends StatelessWidget {
  const IslandMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CharacterRepository repo = context.read<CharacterRepository>();
    final ProgressStore progress = context.watch<ProgressStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('字之岛 · 万物有形',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: SceneId.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (BuildContext ctx, int i) {
          final SceneId scene = SceneId.values[i];
          final List<WonderCharacter> chars = repo.forScene(scene);
          final int lit =
              chars.where((WonderCharacter c) => progress.isLit(c.id)).length;
          return _SceneCard(
            scene: scene,
            characters: chars,
            lit: lit,
            onTap: () {
              Navigator.of(ctx).push(MaterialPageRoute<void>(
                builder: (_) => ScenePage(scene: scene),
              ));
            },
          );
        },
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.characters,
    required this.lit,
    required this.onTap,
  });

  final SceneId scene;
  final List<WonderCharacter> characters;
  final int lit;
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
        color: lit ? InkPalette.glow.withOpacity(0.85) : Colors.white70,
        border: Border.all(color: InkPalette.ink.withOpacity(0.35)),
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
