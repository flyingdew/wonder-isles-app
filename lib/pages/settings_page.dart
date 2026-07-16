import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../services/progress_store.dart';
import '../services/voice_service.dart';

/// 设置：TTS / BGM / SFX 三通道开关与音量，以及清空进度。
///
/// 家长入口下的二级页面，主菜单不直接暴露，避免孩子误触。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final VoiceService voice = context.watch<VoiceService>();
    final ProgressStore progress = context.read<ProgressStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
          _AudioChannelPanel(
            title: '字源讲述',
            subtitle: '关闭后单字演变阶段不再自动播放语音',
            enabled: voice.enabled,
            volume: voice.volume,
            onEnabledChanged: voice.setEnabled,
            onVolumeChanged: voice.setVolume,
          ),
          const SizedBox(height: 16),
          _AudioChannelPanel(
            title: '背景乐',
            subtitle: '进入场景与长诗时播放，回到首页与地图会停止',
            enabled: voice.bgmEnabled,
            volume: voice.bgmVolume,
            onEnabledChanged: voice.setBgmEnabled,
            onVolumeChanged: voice.setBgmVolume,
          ),
          const SizedBox(height: 16),
          _AudioChannelPanel(
            title: '界面音效',
            subtitle: '挖掘、拼合、演变、答对、点亮等操作反馈',
            enabled: voice.sfxEnabled,
            volume: voice.sfxVolume,
            onEnabledChanged: voice.setSfxEnabled,
            onVolumeChanged: voice.setSfxVolume,
          ),
          const SizedBox(height: 16),
          _Panel(
            title: '进度',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '已点亮 ${progress.litCount} / 20 字。清空进度会删除所有点亮记录、'
                  '小诗完成状态和回访次数，无法恢复。',
                  style: const TextStyle(
                    color: InkPalette.inkSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _confirmReset(context, progress),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('清空进度'),
                    style: TextButton.styleFrom(
                        foregroundColor: InkPalette.vermilion),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '奇思岛 · 字之岛 · 象形篇',
              style: TextStyle(
                color: InkPalette.inkSoft,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
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

class _AudioChannelPanel extends StatelessWidget {
  const _AudioChannelPanel({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.volume,
    required this.onEnabledChanged,
    required this.onVolumeChanged,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final double volume;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: InkPalette.vermilion,
            title: Text(title,
                style: const TextStyle(color: InkPalette.ink)),
            subtitle: Text(subtitle,
                style: const TextStyle(color: InkPalette.inkSoft)),
            value: enabled,
            onChanged: onEnabledChanged,
          ),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.volume_up_outlined,
                  size: 22, color: InkPalette.inkSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Slider(
                  value: volume,
                  onChanged: enabled ? onVolumeChanged : null,
                  activeColor: InkPalette.vermilion,
                  inactiveColor:
                      InkPalette.paperDeep.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(
                width: 42,
                child: Text('${(volume * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: enabled
                          ? InkPalette.ink
                          : InkPalette.inkSoft.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title,
              style: const TextStyle(
                color: InkPalette.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 2,
              )),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}