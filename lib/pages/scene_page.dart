import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../data/character_repository.dart';
import '../services/progress_store.dart';
import '../services/voice_service.dart';
import 'character_flow_page.dart';
import 'poem_stage_page.dart';

/// 场景配色（pastel）：主色、浅色、emoji、装饰 emoji。
class _SceneStyle {
  const _SceneStyle(this.primary, this.soft, this.emoji, this.deco);
  final Color primary;
  final Color soft;
  final String emoji;
  final String deco;
}

const Map<SceneId, _SceneStyle> _sceneStyles = <SceneId, _SceneStyle>{
  SceneId.river: _SceneStyle(Color(0xFF8FCBE8), Color(0xFFDFF1F9), '🌊', '〰️'),
  SceneId.forest: _SceneStyle(Color(0xFF8FB86A), Color(0xFFE0EDCC), '🌲', '🍃'),
  SceneId.village: _SceneStyle(Color(0xFFF0A667), Color(0xFFFCE3C7), '🏠', '☀️'),
  SceneId.field: _SceneStyle(Color(0xFFF5C556), Color(0xFFFCEDC1), '🌾', '🌼'),
};

/// 一个场景（河岸/山林/…）里的 5 个字入口。
/// 从单字四步返回时若字被点亮，会给对应格子放一次“从灰变亮”的仪式感动画。
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
    final _SceneStyle style = _sceneStyles[widget.scene]!;
    final CharacterRepository repo = context.read<CharacterRepository>();
    final ProgressStore progress = context.watch<ProgressStore>();
    final List<WonderCharacter> chars = repo.forScene(widget.scene);
    final int lit =
        chars.where((WonderCharacter c) => progress.isLit(c.id)).length;
    final bool allLit = lit == chars.length;
    final bool poemDone = progress.isPoemDone(widget.scene.key);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _PastelBackdrop(style: style),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Header(
                    label: widget.scene.label,
                    emoji: style.emoji,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 14),
                  _GuidePill(
                    allLit: allLit,
                    poemDone: poemDone,
                    accent: style.primary,
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
                            accent: style.primary,
                            onTap: () => _openCharacter(context, c),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PoemEntry(
                    allLit: allLit,
                    poemDone: poemDone,
                    accent: style.primary,
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

class _PastelBackdrop extends StatelessWidget {
  const _PastelBackdrop({required this.style});
  final _SceneStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            style.primary.withValues(alpha: 0.55),
            style.soft,
            const Color(0xFFFFF8EC),
          ],
          stops: const <double>[0, 0.45, 1],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.label, required this.emoji, required this.onBack});
  final String label;
  final String emoji;
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
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: InkPalette.ink,
                  letterSpacing: 3,
                ),
              ),
            ),
            Text(emoji, style: const TextStyle(fontSize: 26)),
          ],
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.only(left: 52),
          child: Text(
            '点击一处可疑之地，开始挖掘 🔍',
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

class _GuidePill extends StatelessWidget {
  const _GuidePill(
      {required this.allLit,
      required this.poemDone,
      required this.accent});
  final bool allLit;
  final bool poemDone;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final String text = poemDone
        ? '小诗已成，此处已被点亮'
        : (allLit ? '五字齐亮，可以试着写小诗了' : '小探险家，选择一处开始挖掘吧');
    final String emoji = poemDone ? '🌟' : (allLit ? '📜' : '🧭');
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: InkPalette.ink.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: InkPalette.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoemEntry extends StatelessWidget {
  const _PoemEntry({
    required this.allLit,
    required this.poemDone,
    required this.accent,
    required this.onEnter,
  });
  final bool allLit;
  final bool poemDone;
  final Color accent;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final bool enabled = allLit || poemDone;
    if (!enabled) {
      return _PoemCardLocked();
    }
    final String label = poemDone ? '重读今日小诗' : '题一首小诗';
    final String emoji = poemDone ? '🎵' : '🖉';
    final Color bg = poemDone ? const Color(0xFFF2C56A) : accent;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onEnter,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoemCardLocked extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: InkPalette.ink.withValues(alpha: 0.08), width: 1),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Text('🔒', style: TextStyle(fontSize: 20)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '点亮全部 5 字后开启',
                    style: TextStyle(
                      color: InkPalette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '完成所有汉字挖掘，解锁隐藏宝藏 🎁',
                    style: TextStyle(
                      color: InkPalette.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    required this.accent,
    required this.onTap,
  });

  final WonderCharacter character;
  final bool lit;
  final bool justLit;
  final Animation<double> reveal;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (BuildContext ctx, Widget? _) {
        final double t = justLit
            ? Curves.easeOutBack.transform(reveal.value.clamp(0.0, 1.0))
            : (lit ? 1.0 : 0.0);
        final Color bg = lit || justLit
            ? Color.lerp(
                Colors.white,
                accent.withValues(alpha: 0.22),
                t.clamp(0.0, 1.0),
              )!
            : Colors.white;
        final double scale = 1 +
            (justLit
                ? 0.08 *
                    (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0)
                : 0);
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (lit || justLit)
                    ? accent.withValues(alpha: 0.45 + 0.25 * t)
                    : InkPalette.ink.withValues(alpha: 0.08),
                width: (lit || justLit) ? 1.4 : 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: InkPalette.ink.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _GlyphOrMound(
                        char: character.char,
                        lit: lit,
                        reveal: justLit ? t : (lit ? 1.0 : 0.0),
                        accent: accent,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lit ? character.pinyin : '土堆',
                        style: TextStyle(
                          color: (lit || justLit)
                              ? accent
                              : InkPalette.inkSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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

class _GlyphOrMound extends StatelessWidget {
  const _GlyphOrMound({
    required this.char,
    required this.lit,
    required this.reveal,
    required this.accent,
  });
  final String char;
  final bool lit;
  final double reveal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (!lit && reveal <= 0) {
      return const Text('⛰', style: TextStyle(fontSize: 40));
    }
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (reveal < 1)
          Opacity(
            opacity: 1 - reveal,
            child: const Text('⛰', style: TextStyle(fontSize: 40)),
          ),
        Opacity(
          opacity: reveal,
          child: Transform.scale(
            scale: 0.85 + 0.15 * reveal,
            child: Text(
              char,
              style: const TextStyle(
                fontSize: 38,
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
