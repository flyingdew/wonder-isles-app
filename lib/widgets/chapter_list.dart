import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 章节状态：可玩 / 原型开发中 / 敬请期待。
enum ChapterStatus { playable, prototype, comingSoon }

/// 首页展示的一条"岛"。
class ChapterEntry {
  const ChapterEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.status,
    this.onTap,
    this.badge,
    this.emoji,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final ChapterStatus status;
  final VoidCallback? onTap;
  final String? badge;
  final String? emoji;

  bool get enabled =>
      status != ChapterStatus.comingSoon && onTap != null;
}

/// 首页岛屿列表：亲子活泼版。
///
/// 卡片：奶白底 + 18 圆角 + 淡阴影；左侧圆角方块图标区用 accent 15% 底色；
/// 右上角 pill 状态章根据 status 变色。
class ChapterList extends StatelessWidget {
  const ChapterList({super.key, required this.entries});
  final List<ChapterEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < entries.length; i++) ...<Widget>[
          _ChapterCard(entry: entries[i]),
          if (i < entries.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.entry});
  final ChapterEntry entry;

  @override
  Widget build(BuildContext context) {
    final bool enabled = entry.enabled;
    final Color cardBg = enabled ? Colors.white : Colors.white.withValues(alpha: 0.72);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: InkPalette.ink.withValues(alpha: enabled ? 0.06 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? entry.onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.accent.withValues(alpha: enabled ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: entry.emoji != null
                      ? Text(entry.emoji!, style: const TextStyle(fontSize: 30))
                      : Icon(entry.icon,
                          color: entry.accent
                              .withValues(alpha: enabled ? 1 : 0.5),
                          size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(entry.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: enabled
                                ? InkPalette.ink
                                : InkPalette.inkSoft,
                            letterSpacing: 0,
                          )),
                      const SizedBox(height: 4),
                      Text(entry.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: InkPalette.inkSoft
                                .withValues(alpha: enabled ? 0.9 : 0.6),
                            letterSpacing: 0.6,
                          )),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatusBadge(
                            text: entry.badge ?? _defaultBadge(entry.status),
                            status: entry.status,
                            accent: entry.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!enabled)
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

  static String _defaultBadge(ChapterStatus s) {
    switch (s) {
      case ChapterStatus.playable:
        return '可玩';
      case ChapterStatus.prototype:
        return '原型';
      case ChapterStatus.comingSoon:
        return '敬请期待';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.status,
    required this.accent,
  });
  final String text;
  final ChapterStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    late Color fg;
    late Color bg;
    switch (status) {
      case ChapterStatus.playable:
        fg = accent;
        bg = accent.withValues(alpha: 0.18);
        break;
      case ChapterStatus.prototype:
        fg = accent;
        bg = accent.withValues(alpha: 0.14);
        break;
      case ChapterStatus.comingSoon:
        fg = InkPalette.inkSoft;
        bg = InkPalette.inkSoft.withValues(alpha: 0.10);
        break;
    }
    // 徽章宽度随内容自适应，避免固定宽度挤压标题或截断多字文案。
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          )),
    );
  }
}