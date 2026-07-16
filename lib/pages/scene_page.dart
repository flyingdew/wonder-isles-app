import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../data/character_repository.dart';
import '../services/progress_store.dart';
import '../services/voice_service.dart';
import 'character_flow_page.dart';
import 'poem_stage_page.dart';

/// 一个场景（河岸/山林/…）里的 5 个字入口。
/// 从单字四步返回时若字被点亮，会给对应格子放一次"从灰变亮"的仪式感动画。
class ScenePage extends StatefulWidget {
  const ScenePage({super.key, required this.scene});
  final SceneId scene;

  @override
  State<ScenePage> createState() => _ScenePageState();
}

class _ScenePageState extends State<ScenePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _litCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  String? _justLitId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VoiceService>().playBgmForScene(widget.scene.key);
    });
  }

  @override
  void dispose() {
    _litCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCharacter(BuildContext context, WonderCharacter c) async {
    final String? litId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => CharacterFlowPage(character: c),
      ),
    );
    if (!mounted || litId == null) return;
    setState(() => _justLitId = litId);
    _litCtrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _justLitId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final CharacterRepository repo = context.read<CharacterRepository>();
    final ProgressStore progress = context.watch<ProgressStore>();
    final List<WonderCharacter> chars = repo.forScene(widget.scene);
    final int lit =
        chars.where((WonderCharacter c) => progress.isLit(c.id)).length;
    final bool allLit = lit == chars.length;
    final bool poemDone = progress.isPoemDone(widget.scene.key);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(widget.scene.label)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              InkPalette.paper.withValues(alpha: poemDone ? 0.15 : 0.35),
              BlendMode.lighten,
            ),
            child: Image.asset(widget.scene.background, fit: BoxFit.cover),
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
                            justLit: _justLitId == c.id,
                            reveal: _litCtrl,
                            onTap: () => _openCharacter(context, c),
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
                        builder: (_) =>
                            PoemStagePage.forScene(scene: widget.scene),
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
    required this.justLit,
    required this.reveal,
    required this.onTap,
  });

  final WonderCharacter character;
  final bool lit;
  final bool justLit;
  final Animation<double> reveal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (BuildContext ctx, Widget? _) {
        // t=0 前是灰暗土堆；仅在 justLit 时把 0 → 1 播一遍。
        final double t = justLit ? Curves.easeOutBack.transform(reveal.value.clamp(0.0, 1.0)) : (lit ? 1.0 : 0.0);
        final Color bg = Color.lerp(
          InkPalette.paperDeep.withValues(alpha: 0.9),
          InkPalette.glow.withValues(alpha: 0.9),
          t.clamp(0.0, 1.0),
        )!;
        final double scale = 1 + (justLit ? 0.08 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0) : 0);
        return Transform.scale(
          scale: scale,
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: justLit
                    ? Color.lerp(InkPalette.ochre, InkPalette.ink,
                            t.clamp(0.0, 1.0))!
                        .withValues(alpha: 0.6)
                    : InkPalette.ink.withValues(alpha: 0.25),
                width: justLit ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _GlyphOrMound(
                      char: character.char,
                      lit: lit,
                      reveal: justLit ? t : (lit ? 1.0 : 0.0),
                    ),
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
          ),
        );
      },
    );
  }
}

class _GlyphOrMound extends StatelessWidget {
  const _GlyphOrMound({
    required this.char,
    required this.lit,
    required this.reveal,
  });
  final String char;
  final bool lit;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    if (!lit && reveal <= 0) {
      return const Icon(Icons.landscape_outlined,
          size: 36, color: InkPalette.inkSoft);
    }
    // reveal 从 0 到 1：土堆图标淡出，字形淡入并轻微放大。
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (reveal < 1)
          Opacity(
            opacity: 1 - reveal,
            child: const Icon(Icons.landscape_outlined,
                size: 36, color: InkPalette.inkSoft),
          ),
        Opacity(
          opacity: reveal,
          child: Transform.scale(
            scale: 0.85 + 0.15 * reveal,
            child: Text(
              char,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: InkPalette.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
