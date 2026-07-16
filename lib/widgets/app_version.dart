import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_theme.dart';
import '../services/error_reporter.dart';
import '../services/update_service.dart';
import 'update_dialog.dart';

/// 只显示"v0.1.3 (build 3)"这一行小字，异步加载。
/// 用于首页底部等非关键位置：拿不到时静默不占位。
class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({
    super.key,
    this.style,
    this.prefix = 'v',
    this.showBuildNumber = true,
    this.textAlign = TextAlign.center,
  });

  final TextStyle? style;
  final String prefix;
  final bool showBuildNumber;
  final TextAlign textAlign;

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  String? _text;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _text = widget.showBuildNumber && info.buildNumber.isNotEmpty
            ? '${widget.prefix}${info.version} · build ${info.buildNumber}'
            : '${widget.prefix}${info.version}';
      });
    } catch (_) {
      // Web / 桌面上偶尔拿不到，安静即可
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? text = _text;
    if (text == null) return const SizedBox.shrink();
    final TextStyle base = widget.style ??
        const TextStyle(
          color: InkPalette.inkSoft,
          fontSize: 12,
          letterSpacing: 1.5,
        );
    return Text(text, style: base, textAlign: widget.textAlign);
  }
}

/// 完整卡片：显示版本号 + 最近一次检查状态 + "检查更新"按钮。
///
/// 家长视图底部与设置页都会使用；样式采用米色内嵌卡片，与
/// 现有 `_Panel` 视觉一致，但不依赖各页面私有的 _Panel。
class AboutCard extends StatefulWidget {
  const AboutCard({super.key, this.title = '关于'});

  final String title;

  @override
  State<AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<AboutCard> {
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
        _version = info.buildNumber.isNotEmpty
            ? 'v${info.version} · build ${info.buildNumber}'
            : 'v${info.version}';
      });
    } catch (_) {}
  }

  Future<void> _handleCheck() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusText = '正在检查…';
    });
    // 手动检查：绕过 skipVersion，也允许 debug/非 android 平台走完流程（会得到 disabled 提示）
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
        setState(() =>
            _statusText = '新版本已被跳过：${result.info?.tag ?? ""}');
        break;
      case UpdateCheckStatus.networkFailure:
        setState(() => _statusText = '检查失败：网络不通，稍后再试');
        break;
      case UpdateCheckStatus.malformed:
        setState(() => _statusText = '检查失败：无法解析版本信息');
        break;
      case UpdateCheckStatus.disabled:
        setState(() => _statusText = '当前平台不支持应用内更新');
        break;
    }
  }

  Future<void> _handleSentryTest() async {
    await ErrorReporter.triggerTestException();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已发送一条测试异常到 Sentry'),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: InkPalette.inkSoft,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          if (_version.isNotEmpty)
            Text(
              '当前版本  $_version',
              style: const TextStyle(color: InkPalette.ink, height: 1.5),
            ),
          if (_statusText != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _statusText!,
              style: const TextStyle(color: InkPalette.inkSoft, height: 1.5),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (ErrorReporter.enabled)
                TextButton.icon(
                  onPressed: _busy ? null : _handleSentryTest,
                  icon: const Icon(Icons.bug_report_outlined, size: 18),
                  label: const Text('上报测试'),
                  style: TextButton.styleFrom(
                      foregroundColor: InkPalette.inkSoft),
                ),
              TextButton.icon(
                onPressed: _busy ? null : _handleCheck,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_alt, size: 18),
                label: Text(_busy ? '检查中…' : '检查更新'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

