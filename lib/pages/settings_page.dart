import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../app_theme.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
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
          const SizedBox(height: 16),
          const _AboutPanel(),
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


class _AboutPanel extends StatefulWidget {
  const _AboutPanel();

  @override
  State<_AboutPanel> createState() => _AboutPanelState();
}

class _AboutPanelState extends State<_AboutPanel> {
  final UpdateService _service = UpdateService();
  bool _busy = false;
  String? _statusText;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = '${info.version}+${info.buildNumber}';
      });
    } catch (_) {
      // 忽略：非移动端拿不到
    }
  }

  Future<void> _handleCheckUpdate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusText = '正在检查…';
    });
    // 手动检查：绕过 skipVersion，也允许 debug build 使用
    final UpdateCheckResult result = await _service.check(ignoreSkipped: true);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result.status) {
      case UpdateCheckStatus.available:
        setState(() => _statusText = '发现新版本 ${result.info!.tag}');
        await showUpdateDialog(context, service: _service, result: result);
        break;
      case UpdateCheckStatus.upToDate:
        setState(() => _statusText = '已是最新版本');
        break;
      case UpdateCheckStatus.skipped:
        setState(() => _statusText = '新版本已被跳过：${result.info?.tag ?? ""}');
        break;
      case UpdateCheckStatus.networkFailure:
        setState(() => _statusText = '检查失败：网络问题，稍后再试');
        break;
      case UpdateCheckStatus.malformed:
        setState(() => _statusText = '检查失败：无法解析版本信息');
        break;
      case UpdateCheckStatus.disabled:
        setState(() => _statusText = '当前平台不支持应用内更新');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '关于',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_version.isNotEmpty)
            Text(
              '版本 $_version',
              style: const TextStyle(color: InkPalette.inkSoft, height: 1.5),
            ),
          if (_statusText != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _statusText!,
              style: const TextStyle(color: InkPalette.inkSoft, height: 1.5),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _busy ? null : _handleCheckUpdate,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update_alt, size: 18),
              label: Text(_busy ? '检查中…' : '检查更新'),
            ),
          ),
        ],
      ),
    );
  }
}

