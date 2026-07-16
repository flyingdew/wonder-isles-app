import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/update_service.dart';

/// 底部 sheet 形态的升级提示 / 下载进度 / 结果反馈。
///
/// 由 UpdateService 的调用方（首页启动检查 / 家长视图手动检查）弹出：
///
/// ```dart
/// await showUpdateDialog(context, service: service, result: result);
/// ```
Future<void> showUpdateDialog(
  BuildContext context, {
  required UpdateService service,
  required UpdateCheckResult result,
}) async {
  final UpdateInfo? info = result.info;
  if (info == null || result.status != UpdateCheckStatus.available) {
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useSafeArea: true,
    backgroundColor: InkPalette.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext ctx) => _UpdateSheet(
      service: service,
      info: info,
      currentVersion: result.currentVersion ?? '',
    ),
  );
}

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet({
    required this.service,
    required this.info,
    required this.currentVersion,
  });
  final UpdateService service;
  final UpdateInfo info;
  final String currentVersion;

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

enum _Phase { prompt, downloading, ready, failed }

class _UpdateSheetState extends State<_UpdateSheet> {
  _Phase _phase = _Phase.prompt;
  int _received = 0;
  int _total = 0;
  String? _errorMsg;
  File? _apk;
  CancelToken? _cancelToken;

  double get _progress =>
      _total > 0 ? (_received / _total).clamp(0.0, 1.0) : 0.0;

  String _fmtMb(int bytes) => (bytes / 1024 / 1024).toStringAsFixed(1);

  Future<void> _startDownload() async {
    final List<String> abis = await widget.service.deviceAbis();
    final UpdateAsset? asset = widget.info.pickApkFor(abis);
    if (asset == null) {
      setState(() {
        _phase = _Phase.failed;
        _errorMsg = '这一版没有可用于当前设备的 APK，稍后再试或从 GitHub Releases 手动下载。';
      });
      return;
    }
    setState(() {
      _phase = _Phase.downloading;
      _received = 0;
      _total = asset.size;
      _errorMsg = null;
      _cancelToken = CancelToken();
    });
    try {
      final File file = await widget.service.downloadApk(
        asset,
        cancelToken: _cancelToken,
        onProgress: (int r, int t) {
          if (!mounted) return;
          setState(() {
            _received = r;
            if (t > 0) _total = t;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _phase = _Phase.ready;
        _apk = file;
      });
      // 下载完立即拉起安装
      await _install();
    } on DioException catch (e) {
      if (!mounted) return;
      if (CancelToken.isCancel(e)) {
        setState(() => _phase = _Phase.prompt);
        return;
      }
      setState(() {
        _phase = _Phase.failed;
        _errorMsg = '下载失败：${e.message ?? e.type.name}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _errorMsg = '下载失败：$e';
      });
    }
  }

  Future<void> _install() async {
    final File? apk = _apk;
    if (apk == null) return;
    final InstallResult installResult = await widget.service.installApk(apk);
    if (!mounted) return;
    // 兜底：native 端返回的错误消息附加在文案后面，便于用户/开发者一眼看到真正原因。
    final String detail =
        (installResult.message != null && installResult.message!.isNotEmpty)
            ? '\n\n诊断：${installResult.message}'
            : '';
    switch (installResult.outcome) {
      case InstallOutcome.launched:
        // 交给系统安装器后就可以关掉了；下次启动会再检查一次
        Navigator.of(context).maybePop();
        break;
      case InstallOutcome.permissionDenied:
        setState(() {
          _phase = _Phase.failed;
          _errorMsg = '需要在系统设置 → 应用 → 奇思岛 → 权限里，'
              '把"安装其它应用 / 未知来源"打开，然后重试。$detail';
        });
        break;
      case InstallOutcome.noHandler:
        setState(() {
          _phase = _Phase.failed;
          _errorMsg = '系统没有找到安装器，可以在 GitHub Releases 页面手动下载。$detail';
        });
        break;
      case InstallOutcome.unsupported:
        setState(() {
          _phase = _Phase.failed;
          _errorMsg = '当前平台不支持应用内安装。$detail';
        });
        break;
      case InstallOutcome.error:
        setState(() {
          _phase = _Phase.failed;
          _errorMsg = '安装未能开始，可以尝试重试；或到 GitHub Releases '
              '页面下载 APK 手动安装。$detail';
        });
        break;
    }
  }

  Future<void> _skipThisVersion() async {
    await widget.service.skipVersion(widget.info.tag);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: InkPalette.ink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '发现新版本 ${widget.info.tag}',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '当前版本 ${widget.currentVersion}',
              style: text.bodySmall?.copyWith(
                color: InkPalette.inkSoft,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.info.body.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Text(
                    widget.info.body,
                    style: text.bodyMedium,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _buildActionArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(BuildContext context) {
    switch (_phase) {
      case _Phase.prompt:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FilledButton(
              onPressed: _startDownload,
              child: const Text('立即升级'),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('稍后再说'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _skipThisVersion,
                    child: const Text('跳过此版'),
                  ),
                ),
              ],
            ),
          ],
        );
      case _Phase.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LinearProgressIndicator(
              value: _total > 0 ? _progress : null,
              minHeight: 6,
              backgroundColor: InkPalette.ink.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 10),
            Text(
              _total > 0
                  ? '下载中… ${_fmtMb(_received)} / ${_fmtMb(_total)} MB'
                  : '下载中… ${_fmtMb(_received)} MB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _cancelToken?.cancel('user cancelled');
              },
              child: const Text('取消'),
            ),
          ],
        );
      case _Phase.ready:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('下载完成，即将唤起系统安装器…'),
        );
      case _Phase.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_errorMsg != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _errorMsg!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: InkPalette.vermilion,
                          height: 1.5,
                        ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _startDownload,
              child: const Text('重试'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('关闭'),
            ),
          ],
        );
    }
  }
}



