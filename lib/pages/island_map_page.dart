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

/// 场景配色（pastel）：主色、浅色、emoji、装饰 emoji。
class _SceneStyle {
  const _SceneStyle(this.primary, this.soft, this.emoji, this.deco);
  final Color primary;
  final Color soft;
  final String emoji;
  final String deco;
}

const Map<SceneId, _SceneStyle> _sceneStyles = <SceneId, _SceneStyle>{
  SceneId.river: _SceneStyle(Color(0xFF8FCBE8), Color(0xFFC7E6F5), '🌊', '〰️'),
  SceneId.forest: _SceneStyle(Color(0xFF8FB86A), Color(0xFFC9DDA5), '🌲', '🍃'),
  SceneId.village: _SceneStyle(Color(0xFFF0A667), Color(0xFFF8D3A5), '🏠', '☀️'),
  SceneId.field: _SceneStyle(Color(0xFFF5C556), Color(0xFFFBE39B), '🌾', '🌼'),
};

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
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _PastelBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 18),
                  for (final SceneId scene in SceneId.values) ...<Widget>[
                    _SceneCard(
                      scene: scene,
                      characters: repo.forScene(scene),
                      lit: repo
                          .forScene(scene)
                          .where((WonderCharacter c) => progress.isLit(c.id))
                          .length,
                      poemDone: progress.isPoemDone(scene.key),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => ScenePage(scene: scene),
                        ));
                      },
                      progress: progress,
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 6),
                  _BossEntry(
                    unlocked: bossUnlocked,
                    done: bossDone,
                    onEnter: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) =>
                            const PoemStagePage.forPoem(poem: kBossPoem),
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

class _PastelBackdrop extends StatelessWidget {
  const _PastelBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF8EC),
            Color(0xFFFCE9D0),
          ],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _RoundIconBtn(icon: Icons.arrow_back_ios_new, onTap: onBack),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '字之岛 · 万物有形',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: InkPalette.ink,
                  letterSpacing: 3,
                ),
              ),
            ),
            const Text('🖉', style: TextStyle(fontSize: 26)),
          ],
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.only(left: 52),
          child: Text(
            '点击场景，去万物里认字吧 🌟',
            style: TextStyle(
              color: InkPalette.inkSoft,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: InkPalette.ink),
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
    required this.progress,
  });

  final SceneId scene;
  final List<WonderCharacter> characters;
  final int lit;
  final bool poemDone;
  final VoidCallback onTap;
  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    final _SceneStyle style = _sceneStyles[scene]!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: InkPalette.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SceneBanner(style: style, poemDone: poemDone),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          scene.label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: InkPalette.ink,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _LitPill(
                            lit: lit,
                            total: characters.length,
                            accent: style.primary),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            color:
                                InkPalette.inkSoft.withValues(alpha: 0.6)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final WonderCharacter c in characters)
                          _CharChip(
                            char: c.char,
                            lit: progress.isLit(c.id),
                            accent: style.primary,
                          ),
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
}

class _SceneBanner extends StatelessWidget {
  const _SceneBanner({required this.style, required this.poemDone});
  final _SceneStyle style;
  final bool poemDone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[style.primary, style.soft],
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 10,
            child:
                Text(style.emoji, style: const TextStyle(fontSize: 54)),
          ),
          Positioned(
            right: 16,
            top: 14,
            child: Text(style.deco,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white.withValues(alpha: 0.9),
                )),
          ),
          Positioned(
            right: 46,
            bottom: 12,
            child: Text(style.deco,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.7),
                )),
          ),
          if (poemDone)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: InkPalette.ink.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('✨', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text('诗成',
                        style: TextStyle(
                          fontSize: 12,
                          color: InkPalette.ink,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LitPill extends StatelessWidget {
  const _LitPill(
      {required this.lit, required this.total, required this.accent});
  final int lit;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '已点亮 $lit / $total 字',
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CharChip extends StatelessWidget {
  const _CharChip(
      {required this.char, required this.lit, required this.accent});
  final String char;
  final bool lit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lit
            ? accent.withValues(alpha: 0.22)
            : const Color(0xFFF3F0EA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: lit
              ? accent.withValues(alpha: 0.55)
              : InkPalette.ink.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        lit ? char : '?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: lit
              ? InkPalette.ink
              : InkPalette.inkSoft.withValues(alpha: 0.55),
        ),
      ),
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
    final Color border = done
        ? const Color(0xFFF2C56A)
        : (unlocked
            ? const Color(0xFFF0A667)
            : InkPalette.ink.withValues(alpha: 0.08));
    final Color fg = unlocked ? InkPalette.ink : InkPalette.inkSoft;
    final String subtitle = done
        ? '重温万物有形 · 再听一次这首长诗 🎵'
        : (unlocked
            ? '四场景已通关，长诗正在等你 ✨'
            : '完成四个场景的小诗后开启 ✨');
    final Color cardBg = done
        ? const Color(0xFFFFF3D6)
        : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: 0.55), width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: InkPalette.ink.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: unlocked ? onEnter : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (done
                            ? const Color(0xFFF2C56A)
                            : const Color(0xFFF0A667))
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('📜',
                      style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '万物有形 · 章末长诗',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: InkPalette.inkSoft
                              .withValues(alpha: unlocked ? 0.9 : 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!unlocked)
                  const Text('🔒', style: TextStyle(fontSize: 18))
                else
                  Icon(Icons.chevron_right,
                      color: InkPalette.inkSoft.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
