import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/number_entry.dart';
import '../data/number_repository.dart';
import '../services/progress_store.dart';
import '../services/voice_service.dart';
import '../widgets/number_glyph.dart';
import 'number_flow_page.dart';
import 'number_poem_page.dart';

/// 数之岛（第二章） · 云上小铺。
///
/// v0：5 天日签形式的一列卡片，孩子按顺序解锁。每完成一天，数字点亮。
class NumberIslePage extends StatefulWidget {
  const NumberIslePage({super.key});

  @override
  State<NumberIslePage> createState() => _NumberIslePageState();
}

class _NumberIslePageState extends State<NumberIslePage> {
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
    final NumberRepository repo = context.read<NumberRepository>();
    final ProgressStore progress = context.watch<ProgressStore>();
    final List<NumberEntry> entries = repo.all;
    final bool allDone =
        entries.every((NumberEntry e) => progress.isNumberLit(e.id));
    final bool poemDone =
        progress.isPoemDone(NumberPoemPage.sceneKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数之岛 · 云上小铺',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          const _Intro(),
          const SizedBox(height: 12),
          for (int i = 0; i < entries.length; i++) ...<Widget>[
            _DayCard(
              entry: entries[i],
              lit: progress.isNumberLit(entries[i].id),
              unlocked: _unlockedAt(progress, entries, i),
              onEnter: () async {
                await Navigator.of(context).push(MaterialPageRoute<String>(
                  builder: (_) => NumberFlowPage(entry: entries[i]),
                ));
                if (!mounted) return;
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          _RhymeEntry(
            done: progress.numberLitCount,
            total: entries.length,
            unlocked: allDone,
            poemDone: poemDone,
            onEnter: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const NumberPoemPage(),
              ));
              if (!mounted) return;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  bool _unlockedAt(ProgressStore progress, List<NumberEntry> all, int i) {
    if (i == 0) return true;
    return progress.isNumberLit(all[i - 1].id);
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: InkPalette.paperDeep.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: InkPalette.ink.withValues(alpha: 0.12)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('你是云上小铺的小掌柜。',
              style: TextStyle(
                fontSize: 16,
                color: InkPalette.ink,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              )),
          SizedBox(height: 6),
          Text('每天一位客人上门，先点一点货，再配一配，最后找零。',
              style: TextStyle(color: InkPalette.inkSoft, height: 1.5)),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.entry,
    required this.lit,
    required this.unlocked,
    required this.onEnter,
  });
  final NumberEntry entry;
  final bool lit;
  final bool unlocked;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final Color bg = lit
        ? InkPalette.glow.withValues(alpha: 0.9)
        : (unlocked
            ? InkPalette.paperDeep
            : InkPalette.paperDeep.withValues(alpha: 0.5));
    final IconData tail = lit
        ? Icons.auto_awesome
        : (unlocked ? Icons.chevron_right : Icons.lock_outline);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: unlocked ? onEnter : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: <Widget>[
              _DayBadge(day: entry.day, char: entry.char),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('第 ${entry.day} 天 · 顾客要 ${entry.value} 个${entry.good.name}',
                        style: TextStyle(
                          fontSize: 16,
                          color: unlocked ? InkPalette.ink : InkPalette.inkSoft,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      lit ? entry.rhyme : (unlocked ? '进入这一天' : '完成前一天后开启'),
                      style: TextStyle(
                        color: unlocked ? InkPalette.inkSoft : InkPalette.inkSoft.withValues(alpha: 0.7),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              NumberGlyph(
                label: entry.good.label,
                colorKey: entry.good.colorKey,
                size: 40,
                dim: !lit,
              ),
              const SizedBox(width: 8),
              Icon(tail,
                  color: unlocked ? InkPalette.ink : InkPalette.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.day, required this.char});
  final int day;
  final String char;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: InkPalette.paper,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: InkPalette.ink.withValues(alpha: 0.35)),
      ),
      child: Text(char,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: InkPalette.ink,
          )),
    );
  }
}

class _RhymeEntry extends StatelessWidget {
  const _RhymeEntry({
    required this.done,
    required this.total,
    required this.unlocked,
    required this.poemDone,
    required this.onEnter,
  });
  final int done;
  final int total;
  final bool unlocked;
  final bool poemDone;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final Color bg = poemDone
        ? InkPalette.glow.withValues(alpha: 0.9)
        : (unlocked ? InkPalette.dusk : InkPalette.paperDeep);
    final Color fg = poemDone ? InkPalette.ink : InkPalette.paper;
    final Color fgDim = poemDone
        ? InkPalette.inkSoft
        : InkPalette.paper.withValues(alpha: 0.75);
    final IconData icon = poemDone
        ? Icons.auto_awesome
        : (unlocked ? Icons.auto_stories : Icons.lock_outline);
    final String label = poemDone
        ? '重温顺口溜'
        : (unlocked
            ? '小铺关门 · 一起哼一段'
            : '完成 5 天后开启（$done / $total）');
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: unlocked ? onEnter : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: <Widget>[
              Icon(icon,
                  color: unlocked ? fg : InkPalette.inkSoft, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('章末顺口溜 · 一二三四五',
                        style: TextStyle(
                          fontSize: 17,
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