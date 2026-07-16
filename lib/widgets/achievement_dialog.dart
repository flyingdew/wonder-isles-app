import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/achievement.dart';

/// 弹出解锁弹窗。传入本次新解锁的成就列表，逐条展示。
///
/// 一般在 markLit / markPoemDone / recordDailyVisit 返回后调用。
Future<void> showAchievementUnlocked(
  BuildContext context,
  List<Achievement> unlocked,
) async {
  if (unlocked.isEmpty) return;
  for (final Achievement a in unlocked) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: InkPalette.ink.withValues(alpha: 0.35),
      builder: (BuildContext ctx) => _AchievementDialog(achievement: a),
    );
  }
}

class _AchievementDialog extends StatelessWidget {
  const _AchievementDialog({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        decoration: BoxDecoration(
          color: InkPalette.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: InkPalette.ochre.withValues(alpha: 0.55)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: InkPalette.ink.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '解 · 锁',
              style: TextStyle(
                color: InkPalette.inkSoft,
                letterSpacing: 8,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            AchievementBadge(achievement: achievement, size: 76),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              style: const TextStyle(
                color: InkPalette.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: InkPalette.inkSoft,
                height: 1.6,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('继续'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 家长视图 / 弹窗中共用的圆形徽章。
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
    this.unlocked = true,
    this.size = 56,
  });

  final Achievement achievement;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color fill = unlocked
        ? InkPalette.glow.withValues(alpha: 0.22)
        : InkPalette.paperDeep.withValues(alpha: 0.4);
    final Color border = unlocked
        ? InkPalette.ochre
        : InkPalette.ink.withValues(alpha: 0.18);
    final Color iconColor =
        unlocked ? InkPalette.vermilion : InkPalette.inkSoft.withValues(alpha: 0.55);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Icon(achievement.icon, color: iconColor, size: size * 0.5),
    );
  }
}