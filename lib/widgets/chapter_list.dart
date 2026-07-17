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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final ChapterStatus status;
  final VoidCallback? onTap;
  /// 右上角可选徽标，如"点亮 8/20"或"新"。
  final String? badge;

  bool get enabled =>
      status != ChapterStatus.comingSoon && onTap != null;
}

/// 首页岛屿列表：一列卡片，最上一张最主，后面依次跟随。
///
/// 视觉沿用之前的 _ChapterCard：主图左侧图标底色 = accent，
/// "敬请期待"的卡片降透明度、去 chevron，点击不响应。
class ChapterList extends StatelessWidget {
  const ChapterList({super.key, required this.entries});
  final List<ChapterEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < entries.length; i++) ...<Widget>[
          _ChapterCard(entry: entries[i]),
          if (i < entries.length - 1) const SizedBox(height: 10),
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
    final Color cardBg = enabled
        ? InkPalette.paperDeep
        : InkPalette.paperDeep.withValues(alpha: 0.55);
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? entry.onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: entry.accent.withValues(alpha: enabled ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(entry.icon,
                    color: entry.accent
                        .withValues(alpha: enabled ? 1 : 0.5),
                    size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(entry.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: enabled
                                    ? InkPalette.ink
                                    : InkPalette.inkSoft,
                                letterSpacing: 2,
                              )),
                        ),
                        if (entry.badge != null) ...<Widget>[
                          const SizedBox(width: 8),
                          _StatusBadge(
                            text: entry.badge!,
                            status: entry.status,
                          ),
                        ] else ...<Widget>[
                          const SizedBox(width: 8),
                          _StatusBadge(
                            text: _defaultBadge(entry.status),
                            status: entry.status,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(entry.subtitle,
                        style: TextStyle(
                          color: InkPalette.inkSoft
                              .withValues(alpha: enabled ? 1 : 0.6),
                          letterSpacing: 1,
                        )),
                  ],
                ),
              ),
              Icon(
                enabled ? Icons.chevron_right : Icons.lock_outline,
                color: InkPalette.inkSoft
                    .withValues(alpha: enabled ? 1 : 0.7),
              ),
            ],
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
  const _StatusBadge({required this.text, required this.status});
  final String text;
  final ChapterStatus status;

  @override
  Widget build(BuildContext context) {
    late Color fg;
    late Color bg;
    switch (status) {
      case ChapterStatus.playable:
        fg = InkPalette.reed;
        bg = InkPalette.reed.withValues(alpha: 0.15);
        break;
      case ChapterStatus.prototype:
        fg = InkPalette.ochre;
        bg = InkPalette.ochre.withValues(alpha: 0.18);
        break;
      case ChapterStatus.comingSoon:
        fg = InkPalette.inkSoft;
        bg = InkPalette.paper.withValues(alpha: 0.7);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          )),
    );
  }
}