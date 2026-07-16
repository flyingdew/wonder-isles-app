import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 字源 TTS 语音播放服务。
///
/// 资源约定放在 assets/voice/<id>.mp3，例如 assets/voice/ri.mp3。
/// 状态持久化到 SharedPreferences：开关 + 音量（0.0-1.0）。
class VoiceService extends ChangeNotifier {
  VoiceService() : _player = AudioPlayer() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  static const String _kEnabled = 'wonder_isles.voice.enabled';
  static const String _kVolume = 'wonder_isles.voice.volume';

  final AudioPlayer _player;
  SharedPreferences? _prefs;

  bool _enabled = true;
  double _volume = 0.9;

  bool get enabled => _enabled;
  double get volume => _volume;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _enabled = _prefs?.getBool(_kEnabled) ?? true;
    _volume = _prefs?.getDouble(_kVolume) ?? 0.9;
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setEnabled(bool v) async {
    if (_enabled == v) return;
    _enabled = v;
    await _prefs?.setBool(_kEnabled, v);
    if (!v) {
      await _player.stop();
    }
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    final double clamped = v.clamp(0.0, 1.0);
    if ((_volume - clamped).abs() < 0.001) return;
    _volume = clamped;
    await _player.setVolume(clamped);
    await _prefs?.setDouble(_kVolume, clamped);
    notifyListeners();
  }

  /// [asset] 例：'voice/ri.mp3'（相对于 assets/ 根）
  Future<void> play(String asset) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.setVolume(_volume);
      await _player.play(AssetSource(asset));
    } catch (_) {
      // 静默忽略播放失败，避免打断儿童体验流。
    }
  }

  Future<void> stop() => _player.stop();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
