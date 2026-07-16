import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 错误上报封装。
///
/// 设计原则：
/// - 不采集任何 PII / 定位 / 设备指纹；儿童向 App，合规优先。
/// - DSN 通过 --dart-define=SENTRY_DSN=... 注入；未配置时 API 全部 no-op。
/// - 仅 release build 启用；debug/profile 走本地打印，避免开发期干扰。
class ErrorReporter {
  ErrorReporter._();

  static const String _dsn = String.fromEnvironment('SENTRY_DSN');
  static const String _envOverride =
      String.fromEnvironment('SENTRY_ENVIRONMENT');
  static const String _buildSha = String.fromEnvironment('BUILD_SHA');

  static bool get enabled => _dsn.isNotEmpty && kReleaseMode;

  /// 用 SentryFlutter.init 包裹 runApp。未启用时行为完全透明。
  static Future<void> guard(FutureOr<void> Function() appRunner) async {
    if (!enabled) {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };
      await appRunner();
      return;
    }

    String? release;
    try {
      final PackageInfo pkg = await PackageInfo.fromPlatform();
      release = 'wonder_isles@' + pkg.version + '+' + pkg.buildNumber;
    } catch (_) {}

    await SentryFlutter.init(
      (SentryFlutterOptions options) {
        options.dsn = _dsn;
        options.release = release;
        options.environment =
            _envOverride.isNotEmpty ? _envOverride : 'production';
        options.dist = _buildSha.isNotEmpty ? _buildSha : null;

        options.sendDefaultPii = false;
        options.attachScreenshot = false;
        options.attachViewHierarchy = false;

        options.sampleRate = 1.0;
        options.tracesSampleRate = 0.1;

        options.enableAutoNativeBreadcrumbs = true;
      },
      appRunner: () async {
        await appRunner();
      },
    );
  }

  /// 主动上报异常。业务代码 catch 后调用。
  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    if (!enabled) {
      // ignore: avoid_print
      print('[error_reporter] ' + error.toString());
      if (stackTrace != null) {
        // ignore: avoid_print
        print(stackTrace.toString());
      }
      return;
    }
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      // hint 目前只做人肉标记，不走 Sentry Hint API（各版本 API 有差异）；
      // 需要时改用 withScope + setTag 更稳。
    );
    if (hint != null && hint.isNotEmpty) {
      Sentry.configureScope((Scope scope) {
        scope.setTag('hint', hint);
      });
    }
  }

  /// 记录一条 breadcrumb（用户行为轨迹），非异常。
  static void addBreadcrumb(String message, {String? category}) {
    if (!enabled) return;
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      level: SentryLevel.info,
      timestamp: DateTime.now().toUtc(),
    ));
  }

  /// 手动触发测试异常。用于在 Sentry 上校验通路。
  static Future<void> triggerTestException() async {
    if (!enabled) {
      throw StateError(
        'Sentry 未启用：SENTRY_DSN 未配置，或当前是 debug/profile build。',
      );
    }
    try {
      throw Exception(
        'wonder-isles test exception @ ' + DateTime.now().toIso8601String(),
      );
    } catch (e, st) {
      await captureException(e, stackTrace: st, hint: 'manual test');
    }
  }
}

