import 'package:flutter/material.dart';

/// 一枚成就的静态定义。解锁状态在 `ProgressStore` 里持久化。
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
}

/// 奇思岛的成就清单。评估逻辑在 `ProgressStore._evaluate` 中。
///
/// 顺序即家长视图中展示顺序，也影响弹窗中多条同时解锁时的先后。
const List<Achievement> kAchievements = <Achievement>[
  Achievement(
    id: 'first_lit',
    title: '初见字光',
    description: '点亮了第一个字。',
    icon: Icons.auto_awesome,
  ),
  Achievement(
    id: 'scene_complete',
    title: '一处圆满',
    description: '集齐了一个场景的五个字。',
    icon: Icons.landscape_outlined,
  ),
  Achievement(
    id: 'all_lit',
    title: '字之岛守护者',
    description: '点亮了字之岛全部二十字。',
    icon: Icons.emoji_events_outlined,
  ),
  Achievement(
    id: 'poem_boss',
    title: '长诗成篇',
    description: '在字之岛结尾完成了整章长诗。',
    icon: Icons.menu_book_outlined,
  ),
  Achievement(
    id: 'streak_3',
    title: '三日结伴',
    description: '连续三天来到奇思岛。',
    icon: Icons.wb_sunny_outlined,
  ),
  Achievement(
    id: 'numbers_first',
    title: '小铺开张',
    description: '在数之岛开张了第一天的小铺。',
    icon: Icons.storefront_outlined,
  ),
  Achievement(
    id: 'numbers_all',
    title: '数之岛守护者',
    description: '走完了数之岛五天的小铺。',
    icon: Icons.stars_outlined,
  ),
  Achievement(
    id: 'numbers_math',
    title: '小铺算术',
    description: '在数之岛的算术小铺里做对了六道加减题。',
    icon: Icons.calculate_outlined,
  ),
  Achievement(
    id: 'numbers_rhyme',
    title: '顺口成谣',
    description: '在数之岛念完了章末的顺口溜。',
    icon: Icons.music_note_outlined,
  ),
];

Achievement achievementById(String id) =>
    kAchievements.firstWhere((Achievement a) => a.id == id);