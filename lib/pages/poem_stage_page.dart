import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../data/character_repository.dart';
import '../data/poems.dart';
import '../services/progress_store.dart';

/// 小诗关：把诗行里的空槽拖回正确的字。既服务场景小诗，也服务章末大诗。
class PoemStagePage extends StatefulWidget {
  const PoemStagePage.forScene({super.key, required SceneId scene})
      : poem = null,
        _scene = scene;

  const PoemStagePage.forPoem({super.key, required this.poem})
      : _scene = null;

  final ScenePoem? poem;
  final SceneId? _scene;

  ScenePoem get resolvedPoem => poem ?? poemFor(_scene!);

  @override
  State<PoemStagePage> createState() => _PoemStagePageState();
}

class _PoemStagePageState extends State<PoemStagePage>
    with SingleTickerProviderStateMixin {
  late final ScenePoem _poem = widget.resolvedPoem;
  late final List<String> _slotIds = _poem.slotCharIds;
  late final List<String> _bankOrder;

  final Map<int, String> _placed = <int, String>{};
  int? _shakeSlot;
  late final AnimationController _celebrateCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final math.Random rng = math.Random(_poem.sceneKey.hashCode);
    _bankOrder = _slotIds.toSet().toList()..shuffle(rng);
  }

  @override
  void dispose() {
    _celebrateCtrl.dispose();
    super.dispose();
  }

  bool get _allFilled => _placed.length == _slotIds.length;

  void _onDropped(int slotIndex, String charId) {
    if (_placed.containsKey(slotIndex)) return;
    final bool correct = _slotIds[slotIndex] == charId;
    if (!correct) {
      setState(() => _shakeSlot = slotIndex);
      Future<void>.delayed(const Duration(milliseconds: 380), () {
        if (!mounted) return;
        if (_shakeSlot == slotIndex) setState(() => _shakeSlot = null);
      });
      return;
    }
    setState(() {
      _placed[slotIndex] = charId;
      _shakeSlot = null;
    });
    if (_allFilled && !_finished) {
      _finished = true;
      _celebrateCtrl.forward(from: 0);
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        context.read<ProgressStore>().markPoemDone(_poem.sceneKey);
      });
    }
  }

  Set<String> get _usedCharIds => _placed.values.toSet();

  @override
  Widget build(BuildContext context) {
    final CharacterRepository repo = context.read<CharacterRepository>();
    final bool isBoss = _poem.scene == null;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(_poem.title)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (isBoss)
            _BossBackdrop(brighten: _celebrateCtrl)
          else
            _SceneBackdrop(scene: _poem.scene!, brighten: _celebrateCtrl),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Text(
                    isBoss
                        ? '把 20 个字牌拖回它们在长诗里的位置'
                        : '把字牌拖回它在诗里的位置',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: InkPalette.inkSoft,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: _PoemBoard(
                          repo: repo,
                          poem: _poem,
                          slotIds: _slotIds,
                          placed: _placed,
                          shakeSlot: _shakeSlot,
                          celebrate: _celebrateCtrl,
                          onDropped: _onDropped,
                          compact: isBoss,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _WordBank(
                    repo: repo,
                    order: _bankOrder,
                    used: _usedCharIds,
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _finished
                        ? FilledButton(
                            key: const ValueKey<String>('done'),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(isBoss ? '整章完成' : '回到岛上'),
                          )
                        : const SizedBox(
                            key: ValueKey<String>('progress'), height: 48),
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

class _SceneBackdrop extends StatelessWidget {
  const _SceneBackdrop({required this.scene, required this.brighten});
  final SceneId scene;
  final Animation<double> brighten;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: brighten,
      builder: (BuildContext ctx, _) {
        final double t = Curves.easeOut.transform(brighten.value);
        return Stack(fit: StackFit.expand, children: <Widget>[
          Image.asset(scene.background, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              color: InkPalette.paper.withValues(alpha: 0.55 - 0.25 * t),
            ),
          ),
          IgnorePointer(
            child: Opacity(
              opacity: t,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 0.9,
                    colors: <Color>[
                      Color(0x66F2C56A),
                      Color(0x00F2C56A),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

/// Boss 关背景：四场景以 2×2 平铺，中央淡墨蒙层随进度点亮。
class _BossBackdrop extends StatelessWidget {
  const _BossBackdrop({required this.brighten});
  final Animation<double> brighten;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: brighten,
      builder: (BuildContext ctx, _) {
        final double t = Curves.easeOut.transform(brighten.value);
        return Stack(fit: StackFit.expand, children: <Widget>[
          Column(children: <Widget>[
            Expanded(child: Row(children: <Widget>[
              Expanded(child: Image.asset(SceneId.river.background,
                  fit: BoxFit.cover)),
              Expanded(child: Image.asset(SceneId.forest.background,
                  fit: BoxFit.cover)),
            ])),
            Expanded(child: Row(children: <Widget>[
              Expanded(child: Image.asset(SceneId.village.background,
                  fit: BoxFit.cover)),
              Expanded(child: Image.asset(SceneId.field.background,
                  fit: BoxFit.cover)),
            ])),
          ]),
          DecoratedBox(
            decoration: BoxDecoration(
              color: InkPalette.paper.withValues(alpha: 0.7 - 0.35 * t),
            ),
          ),
          IgnorePointer(
            child: Opacity(
              opacity: t,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: <Color>[
                      Color(0x88F2C56A),
                      Color(0x00F2C56A),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class _PoemBoard extends StatelessWidget {
  const _PoemBoard({
    required this.repo,
    required this.poem,
    required this.slotIds,
    required this.placed,
    required this.shakeSlot,
    required this.celebrate,
    required this.onDropped,
    this.compact = false,
  });

  final CharacterRepository repo;
  final ScenePoem poem;
  final List<String> slotIds;
  final Map<int, String> placed;
  final int? shakeSlot;
  final Animation<double> celebrate;
  final void Function(int slotIndex, String charId) onDropped;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    int slotCounter = 0;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18, vertical: compact ? 14 : 20),
      decoration: BoxDecoration(
        color: InkPalette.paper.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InkPalette.ink.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (final PoemLine line in poem.lines)
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 3 : 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                runSpacing: 4,
                children: <Widget>[
                  for (final PoemToken t in line.tokens)
                    if (t.isSlot)
                      _buildSlot(context, slotCounter++)
                    else
                      _StaticGlyph(
                          text: t.text,
                          celebrate: celebrate,
                          compact: compact),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, int index) {
    final String? filledId = placed[index];
    final bool filled = filledId != null;
    final bool shaking = shakeSlot == index;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !filled,
      onAcceptWithDetails: (DragTargetDetails<String> d) =>
          onDropped(index, d.data),
      builder: (BuildContext ctx, List<String?> candidate, List<dynamic> _) {
        final bool hover = candidate.isNotEmpty && !filled;
        return _SlotBox(
          filled: filled,
          hover: hover,
          shaking: shaking,
          celebrate: celebrate,
          compact: compact,
          child: filled
              ? Text(
                  repo.byId(filledId).char,
                  style: TextStyle(
                    fontSize: compact ? 20 : 26,
                    fontWeight: FontWeight.w700,
                    color: InkPalette.ink,
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _StaticGlyph extends StatelessWidget {
  const _StaticGlyph({
    required this.text,
    required this.celebrate,
    this.compact = false,
  });
  final String text;
  final Animation<double> celebrate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: celebrate,
      builder: (BuildContext ctx, _) {
        final double t = celebrate.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          child: Text(
            text,
            style: TextStyle(
              fontSize: compact ? 18 : 22,
              height: 1.4,
              color:
                  Color.lerp(InkPalette.ink, InkPalette.vermilion, t * 0.6)!,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}

class _SlotBox extends StatelessWidget {
  const _SlotBox({
    required this.filled,
    required this.hover,
    required this.shaking,
    required this.celebrate,
    required this.child,
    this.compact = false,
  });

  final bool filled;
  final bool hover;
  final bool shaking;
  final Animation<double> celebrate;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 34 : 42;
    return AnimatedBuilder(
      animation: celebrate,
      builder: (BuildContext ctx, Widget? _) {
        final double glow = filled ? celebrate.value : 0;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: shaking ? 1 : 0),
          duration: const Duration(milliseconds: 320),
          builder: (BuildContext c, double s, Widget? __) {
            final double dx =
                shaking ? math.sin(s * math.pi * 6) * 6 * (1 - s) : 0.0;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled
                      ? Color.lerp(InkPalette.paper,
                          InkPalette.glow.withValues(alpha: 0.9), glow)
                      : (hover
                          ? InkPalette.paperDeep.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.6)),
                  border: Border.all(
                    color: filled
                        ? InkPalette.ochre
                        : (shaking
                            ? InkPalette.vermilion
                            : InkPalette.ink.withValues(alpha: 0.45)),
                    width: filled || shaking ? 2 : 1.2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

class _WordBank extends StatelessWidget {
  const _WordBank({
    required this.repo,
    required this.order,
    required this.used,
  });

  final CharacterRepository repo;
  final List<String> order;
  final Set<String> used;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: InkPalette.paperDeep.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InkPalette.ink.withValues(alpha: 0.15)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 172),
        child: SingleChildScrollView(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              for (final String id in order)
                _BankTile(char: repo.byId(id), used: used.contains(id)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({required this.char, required this.used});
  final WonderCharacter char;
  final bool used;

  @override
  Widget build(BuildContext context) {
    final Widget tile = _Tile(char: char);
    if (used) {
      return Opacity(
        opacity: 0.25,
        child: IgnorePointer(child: tile),
      );
    }
    return Draggable<String>(
      data: char.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: _Tile(char: char, floating: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.char, this.floating = false});
  final WonderCharacter char;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: InkPalette.paper,
        border: Border.all(color: InkPalette.ink.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: floating
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(char.char,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: InkPalette.ink,
              )),
          Text(char.pinyin,
              style: const TextStyle(
                fontSize: 10,
                color: InkPalette.inkSoft,
              )),
        ],
      ),
    );
  }
}

