import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GitHub Releases 单个 apk 资产。
class UpdateAsset {
  const UpdateAsset({required this.name, required this.url, required this.size});
  final String name;
  final String url;
  final int size;
}

/// 一次成功的版本查询结果。
class UpdateInfo {
  const UpdateInfo({
    required this.tag,
    required this.name,
    required this.body,
    required this.assets,
    required this.htmlUrl,
    required this.publishedAt,
  });

  final String tag;             // 例如 v0.1.2
  final String name;            // release title
  final String body;            // release notes (markdown)
  final List<UpdateAsset> assets;
  final String htmlUrl;         // release 页面链接，作为兜底下载入口
  final DateTime? publishedAt;

  /// 按当前设备 abi 优先挑最合适的 apk：
  /// arm64-v8a > armeabi-v7a > x86_64 > universal > 其它任意 apk。
  UpdateAsset? pickApkFor(List<String> supportedAbis) {
    UpdateAsset? byAbi(String abi) {
      for (final UpdateAsset a in assets) {
        if (a.name.contains(abi)) return a;
      }
      return null;
    }
    for (final String abi in supportedAbis) {
      final UpdateAsset? hit = byAbi(abi);
      if (hit != null) return hit;
    }
    for (final UpdateAsset a in assets) {
      if (a.name.contains('universal')) return a;
    }
    for (final UpdateAsset a in assets) {
      if (a.name.toLowerCase().endsWith('.apk')) return a;
    }
    return null;
  }
}

/// 语义化版本 (major.minor.patch，忽略 -rc / +build 之类的后缀)。
@immutable
class _Semver implements Comparable<_Semver> {
  const _Semver(this.major, this.minor, this.patch);
  final int major;
  final int minor;
  final int patch;

  static _Semver? tryParse(String raw) {
    String s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    final int cut = s.indexOf(RegExp(r'[-+]'));
    if (cut >= 0) s = s.substring(0, cut);
    final List<String> parts = s.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final List<int> nums = <int>[];
    for (final String p in parts) {
      final int? n = int.tryParse(p);
      if (n == null || n < 0) return null;
      nums.add(n);
    }
    while (nums.length < 3) {
      nums.add(0);
    }
    return _Semver(nums[0], nums[1], nums[2]);
  }

  @override
  int compareTo(_Semver other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}

enum UpdateCheckStatus {
  disabled,        // 平台/环境不支持
  networkFailure,  // 拉不到 API（超时、DNS、限流…）
  malformed,       // API 返回但没法解析
  upToDate,        // 已是最新
  skipped,         // 有新版但用户之前选了"跳过此版"
  available,       // 有新版可提示
}

class UpdateCheckResult {
  const UpdateCheckResult(this.status, {this.info, this.currentVersion});
  final UpdateCheckStatus status;
  final UpdateInfo? info;
  final String? currentVersion;
}

typedef DownloadProgress = void Function(int received, int total);

/// 更新服务：
/// - 只在 Android 且 release build 生效；其它平台/模式全部静默返回 disabled；
/// - 只查询 public 仓库的 /releases/latest（无 token，60 req/h/IP 足够）；
/// - 下载到 external cache，安装通过 open_filex 拉起 PackageInstaller；
/// - "跳过此版"通过 shared_preferences 记忆。
class UpdateService {
  UpdateService({
    this.owner = 'flyingdew',
    this.repo = 'wonder-isles-app',
    Dio? dio,
    http.Client? httpClient,
  })  : _dio = dio ?? Dio(),
        _http = httpClient ?? http.Client();

  final String owner;
  final String repo;
  final Dio _dio;
  final http.Client _http;

  static const String _kSkipTag = 'wonder_isles.update.skipTag';
  static const Duration _timeout = Duration(seconds: 8);

  bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 只在 Android 且 release 模式下自动查更新；家长视图里的"手动检查"用 ignoreSkipped=true。
  Future<UpdateCheckResult> check({bool ignoreSkipped = false}) async {
    if (!isSupportedPlatform) {
      return const UpdateCheckResult(UpdateCheckStatus.disabled);
    }
    // 自动触发时才要求 release；手动检查放开限制以便调试
    if (!kReleaseMode && !ignoreSkipped) {
      return const UpdateCheckResult(UpdateCheckStatus.disabled);
    }

    final PackageInfo pkg;
    try {
      pkg = await PackageInfo.fromPlatform();
    } catch (_) {
      return const UpdateCheckResult(UpdateCheckStatus.disabled);
    }
    final String currentVersion = pkg.version;
    final _Semver? currentSemver = _Semver.tryParse(currentVersion);
    if (currentSemver == null) {
      return UpdateCheckResult(
        UpdateCheckStatus.malformed,
        currentVersion: currentVersion,
      );
    }

    final Uri api = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/releases/latest',
    );

    final http.Response resp;
    try {
      resp = await _http.get(api, headers: <String, String>{
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'wonder-isles-app/$currentVersion',
      }).timeout(_timeout);
    } catch (_) {
      return UpdateCheckResult(
        UpdateCheckStatus.networkFailure,
        currentVersion: currentVersion,
      );
    }
    if (resp.statusCode != 200) {
      return UpdateCheckResult(
        UpdateCheckStatus.networkFailure,
        currentVersion: currentVersion,
      );
    }

    final UpdateInfo? info = _parseRelease(resp.body);
    if (info == null) {
      return UpdateCheckResult(
        UpdateCheckStatus.malformed,
        currentVersion: currentVersion,
      );
    }

    final _Semver? latest = _Semver.tryParse(info.tag);
    if (latest == null) {
      return UpdateCheckResult(
        UpdateCheckStatus.malformed,
        currentVersion: currentVersion,
      );
    }

    if (latest.compareTo(currentSemver) <= 0) {
      return UpdateCheckResult(
        UpdateCheckStatus.upToDate,
        info: info,
        currentVersion: currentVersion,
      );
    }

    if (!ignoreSkipped) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? skipped = prefs.getString(_kSkipTag);
      if (skipped == info.tag) {
        return UpdateCheckResult(
          UpdateCheckStatus.skipped,
          info: info,
          currentVersion: currentVersion,
        );
      }
    }

    return UpdateCheckResult(
      UpdateCheckStatus.available,
      info: info,
      currentVersion: currentVersion,
    );
  }

  UpdateInfo? _parseRelease(String jsonBody) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(jsonBody) as Map<String, dynamic>;
      final String tag = (json['tag_name'] as String? ?? '').trim();
      if (tag.isEmpty) return null;
      final String name = (json['name'] as String? ?? tag).trim();
      final String body = (json['body'] as String? ?? '').trim();
      final String htmlUrl = (json['html_url'] as String? ?? '').trim();
      final DateTime? publishedAt =
          DateTime.tryParse(json['published_at'] as String? ?? '');
      final List<dynamic> rawAssets =
          (json['assets'] as List<dynamic>?) ?? const <dynamic>[];
      final List<UpdateAsset> assets = <UpdateAsset>[];
      for (final dynamic raw in rawAssets) {
        if (raw is! Map<String, dynamic>) continue;
        final String aname = (raw['name'] as String? ?? '').trim();
        final String url =
            (raw['browser_download_url'] as String? ?? '').trim();
        final int size = (raw['size'] as num?)?.toInt() ?? 0;
        if (aname.isEmpty || url.isEmpty) continue;
        if (!aname.toLowerCase().endsWith('.apk')) continue;
        assets.add(UpdateAsset(name: aname, url: url, size: size));
      }
      return UpdateInfo(
        tag: tag,
        name: name.isEmpty ? tag : name,
        body: body,
        assets: assets,
        htmlUrl: htmlUrl,
        publishedAt: publishedAt,
      );
    } catch (_) {
      return null;
    }
  }

  /// 记住"跳过此版"，直到下一次 tag 变化。
  Future<void> skipVersion(String tag) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSkipTag, tag);
  }

  Future<void> clearSkipped() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSkipTag);
  }

  /// 查询设备当前 abi 列表，用于挑最合适的 apk 资产。
  Future<List<String>> deviceAbis() async {
    if (defaultTargetPlatform != TargetPlatform.android) return const <String>[];
    try {
      final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      return info.supportedAbis;
    } catch (_) {
      return const <String>[];
    }
  }

  /// 下载 apk 到 external cache dir，返回本地文件。
  Future<File> downloadApk(
    UpdateAsset asset, {
    DownloadProgress? onProgress,
    CancelToken? cancelToken,
  }) async {
    // 用内部私有 cache（getCacheDir()），open_filex 4.5.x 在 external 路径上
    // 会误报需要 MANAGE_EXTERNAL_STORAGE；内部 cache 走 FileProvider content://
    // URI 交给 PackageInstaller，系统安装器正常受理，也不需要额外权限。
    final Directory baseCache = await getTemporaryDirectory();
    final Directory dir = Directory('${baseCache.path}/updates');
    if (!await dir.exists()) await dir.create(recursive: true);

    final File target = File('${dir.path}/${asset.name}');

    // 已完整下过就复用（size 精确匹配即视为完整）
    if (await target.exists()) {
      final int len = await target.length();
      if (asset.size > 0 && len == asset.size) {
        onProgress?.call(len, len);
        return target;
      }
      await target.delete();
    }

    // 先写 .part 临时文件，成功后 rename，避免半包被复用
    final File tmp = File('${target.path}.part');
    if (await tmp.exists()) await tmp.delete();

    await _dio.download(
      asset.url,
      tmp.path,
      cancelToken: cancelToken,
      options: Options(
        followRedirects: true,
        // GitHub 会 302 到 objects.githubusercontent.com
        validateStatus: (int? s) => s != null && s >= 200 && s < 400,
        headers: <String, dynamic>{
          'Accept': 'application/octet-stream',
          'User-Agent': 'wonder-isles-app-updater',
        },
      ),
      onReceiveProgress: onProgress,
    );

    await tmp.rename(target.path);
    return target;
  }

  /// 触发系统 PackageInstaller。
  ///
  /// 注意 REQUEST_INSTALL_PACKAGES 是 Android 的 special permission：
  /// - 不能通过标准 request 弹窗授权，只能引导用户到系统"未知来源"设置页；
  /// - permission_handler 在部分国产 ROM 上返回 denied 并不代表真的没授权。
  /// 因此这里不再拦截 permission_handler，直接让 Android Intent 自己决定：
  /// 已授权 → 拉起安装器；未授权 → 系统会自己弹"允许来自此来源"页面。
  Future<InstallResult> installApk(File apk) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const InstallResult(InstallOutcome.unsupported);
    }
    if (!await apk.exists()) {
      return InstallResult(
        InstallOutcome.error,
        message: '找不到已下载的 APK 文件：${apk.path}',
      );
    }
    // 仅调用一次以刷新状态，不拦截；返回结果用于日志、不做拒绝依据。
    PermissionStatus? preStatus;
    try {
      preStatus = await Permission.requestInstallPackages.status;
    } catch (_) {
      preStatus = null;
    }
    final OpenResult result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    switch (result.type) {
      case ResultType.done:
        return const InstallResult(InstallOutcome.launched);
      case ResultType.noAppToOpen:
        return InstallResult(
          InstallOutcome.noHandler,
          message: result.message,
        );
      case ResultType.permissionDenied:
        return InstallResult(
          InstallOutcome.permissionDenied,
          message: 'open_filex: ${result.message}'
              '  |  permission_handler=$preStatus',
        );
      case ResultType.fileNotFound:
      case ResultType.error:
        return InstallResult(
          InstallOutcome.error,
          message: 'open_filex(${result.type.name}): ${result.message}',
        );
    }
  }
}

enum InstallOutcome {
  launched,           // 已把 apk 交给系统安装器
  permissionDenied,   // 系统层判定未授权（多数国产 ROM 上此路径不会走到）
  noHandler,          // 没有 PackageInstaller，罕见
  unsupported,        // 非 Android
  error,              // 其它异常
}

/// 携带 native 端错误消息，便于在 UI 上显示诊断信息。
class InstallResult {
  const InstallResult(this.outcome, {this.message});
  final InstallOutcome outcome;
  final String? message;
}


