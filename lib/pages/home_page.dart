import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../data/achievement.dart';
import '../data/poems.dart';
import '../services/progress_store.dart';
import '../services/voice_service.dart';
import '../services/update_service.dart';
import '../widgets/achievement_dialog.dart';
import '../widgets/app_version.dart';
import '../widgets/chapter_list.dart';
import '../widgets/update_dialog.dart';
import 'island_map_page.dart';
import 'number_isle_page.dart';
import 'parent_dashboard_page.dart';
import 'poem_stage_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<VoiceService>().stopBgm();
      final List<Achievement> unlocked =
          await context.read<ProgressStore>().recordDailyVisit();
      if (!mounted) return;
      await showAchievementUnlocked(context, unlocked);
      // 首页稳定 3 秒后再静默检查一次更新，避免影响冷启动 & 成就弹窗
      unawaited(_maybePromptUpdate());
    });
  }

  Future<void> _maybePromptUpdate() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final UpdateService service = UpdateService();
    final UpdateCheckResult result = await service.check();
    if (!mounted) return;
    if (result.status == UpdateCheckStatus.available) {
      await showUpdateDialog(context, service: service, result: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProgressStore progress = context.watch<ProgressStore>();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _PaperBackdrop(),
          SafeArea(
            child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints cons) {
              final double titleSize = cons.maxWidth < 340 ? 36 : 44;
              final bool tight = cons.maxHeight < 640;
              final double vPad = tight ? 24 : 40;
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cons.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28, vertical: vPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              const Text('🌴', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 10),
                              Text(
                                '奇思岛',
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  color: InkPalette.ink,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '一片漂浮在云海上的群岛 ✨',
                            style: TextStyle(
                              fontSize: 15,
                              color: InkPalette.inkSoft,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: tight ? 16 : 20),
                          if (progress.streakDays > 0) ...<Widget>[
                            _StreakBanner(days: progress.streakDays),
                            SizedBox(height: tight ? 14 : 18),
                          ],
                          ChapterList(entries: <ChapterEntry>[
                            ChapterEntry(
                              title: '第一章 · 字之岛',
                              subtitle: '万物有形',
                              emoji: '🖉',
                              icon: Icons.brush_outlined,
                              accent: InkPalette.vermilion,
                              status: ChapterStatus.playable,
                              badge: '点亮 ${progress.litCount} / 20',
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute<void>(
                                  builder: (_) => const IslandMapPage(),
                                ));
                              },
                            ),
                            ChapterEntry(
                              title: '第二章 · 数之岛',
                              subtitle: '云上小铺 · 一二三四五',
                              emoji: '🏪',
                              icon: Icons.storefront_outlined,
                              accent: InkPalette.ochre,
                              status: (progress.numberLitCount >= 5)
                                  ? ChapterStatus.playable
                                  : ChapterStatus.prototype,
                              badge: (progress.numberLitCount >= 5 &&
                                      progress.isNumberMathDone &&
                                      progress.isPoemDone('numbers_isle'))
                                  ? '🎉 圆满'
                                  : (progress.numberLitCount > 0
                                      ? '🎉 开张 ${progress.numberLitCount} / 5'
                                      : '原型'),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute<void>(
                                  builder: (_) => const NumberIslePage(),
                                ));
                              },
                            ),
                            const ChapterEntry(
                              title: '第三章 · 机关岛',
                              subtitle: '重力 · 杠杆 · 齿轮',
                              emoji: '⚙️',
                              icon: Icons.settings_outlined,
                              accent: InkPalette.dusk,
                              status: ChapterStatus.comingSoon,
                            ),
                            const ChapterEntry(
                              title: '第四章 · 故事岛',
                              subtitle: '词句 · 想象 · 续写',
                              emoji: '📖',
                              icon: Icons.menu_book_outlined,
                              accent: InkPalette.reed,
                              status: ChapterStatus.comingSoon,
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              child: InkWell(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                  builder: (_) => const ParentDashboardPage(),
                                )),
                                borderRadius: BorderRadius.circular(999),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text('🀄', style: TextStyle(fontSize: 16)),
                                      SizedBox(width: 6),
                                      Text('家长',
                                          style: TextStyle(
                                            color: InkPalette.inkSoft,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (kDebugMode && kIsWeb) ...<Widget>[
                            const SizedBox(height: 12),
                            const _DebugShortcuts(),
                          ],
                          const SizedBox(height: 24),
                          // 底部一行小字版本号，家长按需一眼看到，孩子基本忽略
                          const Center(child: AppVersionLabel()),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

}



class _PaperBackdrop extends StatelessWidget {
  const _PaperBackdrop();

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

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2C56A).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '已连续探索 $days 天！继续加油哦 💪',
              style: const TextStyle(
                color: Color(0xFF7A5A2E),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



/// 仅在 Web + Debug 下渲染的测试直达入口。
class _DebugShortcuts extends StatelessWidget {
  const _DebugShortcuts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: InkPalette.paperDeep.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: InkPalette.ink.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.bug_report,
                  size: 16, color: InkPalette.inkSoft),
              SizedBox(width: 6),
              Text('DEBUG · 仅 Web 调试可见',
                  style: TextStyle(
                    color: InkPalette.inkSoft,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              _DebugChip(
                label: '直达 · Boss 长诗',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const PoemStagePage.forPoem(poem: kBossPoem),
                  ),
                ),
              ),
              for (final ScenePoem p in kScenePoems)
                _DebugChip(
                  label: '直达 · ${p.title}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          PoemStagePage.forPoem(poem: p),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebugChip extends StatelessWidget {
  const _DebugChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: InkPalette.paper,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(label,
              style: const TextStyle(
                fontSize: 12,
                color: InkPalette.ink,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }
}


