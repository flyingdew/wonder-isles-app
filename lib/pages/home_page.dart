import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../services/progress_store.dart';
import 'island_map_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProgressStore progress = context.watch<ProgressStore>();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _PaperBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '奇思岛',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: InkPalette.ink,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '第一章 · 字之岛 · 万物有形',
                    style: TextStyle(
                      fontSize: 16,
                      color: InkPalette.inkSoft,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  _LitBadge(count: progress.litCount),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => const IslandMapPage(),
                          ));
                        },
                        child: const Text('登岛探字'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => _showParentSheet(context, progress),
                        style: TextButton.styleFrom(
                          foregroundColor: InkPalette.inkSoft,
                        ),
                        child: const Text('家长'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showParentSheet(BuildContext context, ProgressStore progress) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: InkPalette.paper,
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('家长视图',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text('本章已点亮：${progress.litCount} / 20 字',
                  style: const TextStyle(color: InkPalette.inkSoft)),
              const SizedBox(height: 8),
              const Text('v1 极简，仅显示当前进度；后续会加入回访最多的字与共读建议。',
                  style: TextStyle(color: InkPalette.inkSoft)),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await progress.reset();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('清空进度'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LitBadge extends StatelessWidget {
  const _LitBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: InkPalette.paperDeep,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.wb_sunny_outlined,
              size: 20, color: InkPalette.vermilion),
          const SizedBox(width: 8),
          Text('已点亮 $count / 20 字',
              style: const TextStyle(
                color: InkPalette.ink,
                fontWeight: FontWeight.w500,
              )),
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
            InkPalette.paper,
            InkPalette.paperDeep,
          ],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}
