import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/character.dart';
import '../data/character_repository.dart';
import '../data/parent_tips.dart';
import '../data/poems.dart';
import '../services/progress_store.dart';

/// 家长视图：整章进度、最喜欢的字、共读建议、清空进度。
///
/// 定位是"陪伴"而不是"考核"，不出现分数、排名、时长曲线之类容易让家长焦虑的数字。
class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CharacterRepository repo = context.read<CharacterRepository>();
    final ProgressStore progress = context.watch<ProgressStore>();

    final Map<String, int> visits = progress.allVisits;
    final List<WonderCharacter> ranked = repo.all
        .where((WonderCharacter c) => (visits[c.id] ?? 0) > 0)
        .toList()
      ..sort((WonderCharacter a, WonderCharacter b) =>
          (visits[b.id] ?? 0).compareTo(visits[a.id] ?? 0));
    final WonderCharacter? favorite = ranked.isEmpty ? null : ranked.first;

    final int scenePoems = SceneId.values
        .where((SceneId s) => progress.isPoemDone(s.key))
        .length;
    final bool bossDone = progress.isPoemDone(kBossPoem.sceneKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('家长视图',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
          _SummaryCard(
            lit: progress.litCount,
            scenePoems: scenePoems,
            bossDone: bossDone,
          ),
          const SizedBox(height: 16),
          _FavoriteCard(favorite: favorite, visits: visits),
          const SizedBox(height: 16),
          _RecentlyVisited(chars: ranked.take(5).toList(), visits: visits),
          const SizedBox(height: 16),
          _ReadTogether(favorite: favorite),
          const SizedBox(height: 24),
          _DangerZone(onReset: () => _confirmReset(context, progress)),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
      BuildContext context, ProgressStore progress) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('清空进度'),
        content: const Text('这会删除所有已点亮的字、小诗完成状态和回访次数，无法恢复。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: InkPalette.vermilion),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await progress.reset();
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.lit,
    required this.scenePoems,
    required this.bossDone,
  });
  final int lit;
  final int scenePoems;
  final bool bossDone;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '本章进度',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StatRow(
            icon: Icons.wb_sunny_outlined,
            label: '已点亮的字',
            value: '$lit / 20',
          ),
          const SizedBox(height: 10),
          _StatRow(
            icon: Icons.auto_stories,
            label: '场景小诗',
            value: '$scenePoems / 4',
          ),
          const SizedBox(height: 10),
          _StatRow(
            icon: Icons.auto_awesome,
            label: '章末长诗',
            value: bossDone ? '已完成' : '未完成',
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.favorite, required this.visits});
  final WonderCharacter? favorite;
  final Map<String, int> visits;

  @override
  Widget build(BuildContext context) {
    final WonderCharacter? c = favorite;
    return _Panel(
      title: '最喜欢的字',
      child: c == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '孩子还没进入过任何一个字，等第一次点亮之后这里就会亮起来。',
                style: TextStyle(color: InkPalette.inkSoft, height: 1.5),
              ),
            )
          : Row(
              children: <Widget>[
                Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: InkPalette.glow.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: InkPalette.ink.withValues(alpha: 0.3)),
                  ),
                  child: Text(c.char,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: InkPalette.ink,
                      )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${c.char} · ${c.pinyin}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: InkPalette.ink,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        '回访 ${visits[c.id] ?? 0} 次 · 来自${c.scene.label}',
                        style: const TextStyle(color: InkPalette.inkSoft),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.story,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: InkPalette.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _RecentlyVisited extends StatelessWidget {
  const _RecentlyVisited({required this.chars, required this.visits});
  final List<WonderCharacter> chars;
  final Map<String, int> visits;

  @override
  Widget build(BuildContext context) {
    if (chars.isEmpty) return const SizedBox.shrink();
    return _Panel(
      title: '回访最多的 ${chars.length} 个字',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          for (final WonderCharacter c in chars)
            _MiniChar(char: c, count: visits[c.id] ?? 0),
        ],
      ),
    );
  }
}

class _MiniChar extends StatelessWidget {
  const _MiniChar({required this.char, required this.count});
  final WonderCharacter char;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: InkPalette.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: InkPalette.ink.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: <Widget>[
          Text(char.char,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: InkPalette.ink,
              )),
          const SizedBox(height: 2),
          Text('× $count',
              style: const TextStyle(
                fontSize: 12,
                color: InkPalette.inkSoft,
              )),
        ],
      ),
    );
  }
}

class _ReadTogether extends StatelessWidget {
  const _ReadTogether({required this.favorite});
  final WonderCharacter? favorite;

  @override
  Widget build(BuildContext context) {
    final WonderCharacter? c = favorite;
    final String tip = c == null
        ? '还没有可以推荐的共读片段。让孩子先玩一会儿，回来看看这里。'
        : (kParentTips[c.id] ??
            '在生活里找一次机会指给孩子看"${c.char}"，比在书里再多看一遍更有用。');
    return _Panel(
      title: '共读小片段',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            tip,
            style: const TextStyle(
              color: InkPalette.ink,
              height: 1.6,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '不追求"记住"，只求下一次在生活里遇见时孩子能一起念出来。',
            style: TextStyle(
              color: InkPalette.inkSoft.withValues(alpha: 0.9),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onReset,
        icon: const Icon(Icons.restart_alt, size: 18),
        label: const Text('清空进度'),
        style: TextButton.styleFrom(foregroundColor: InkPalette.inkSoft),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: InkPalette.paperDeep.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InkPalette.ink.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: InkPalette.inkSoft,
                letterSpacing: 2,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: InkPalette.vermilion),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: InkPalette.ink, fontSize: 15)),
        ),
        Text(value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: InkPalette.ink,
              fontSize: 16,
            )),
      ],
    );
  }
}
