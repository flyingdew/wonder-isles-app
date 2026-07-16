import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 音频服务：TTS 讲述、场景 BGM 循环、界面 SFX。
///
/// 资源约定：
///   assets/voice/<id>.mp3   —— 字源讲述（TTS 通道）
///   assets/bgm/<scene>.mp3  —— 场景背景乐（BGM 通道，loop）
///   assets/sfx/<name>.mp3   —— 界面音效（SFX 通道，one-shot）
///
/// 状态持久化到 SharedPreferences：三通道各自的 enabled + volume。
class VoiceService extends ChangeNotifier {
  VoiceService()
      : _ttsPlayer = AudioPlayer(),
        _bgmPlayer = AudioPlayer(),
        _sfxPlayer = AudioPlayer() {
    _ttsPlayer.setReleaseMode(ReleaseMode.stop);
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
  }

  static const String _kEnabled = 'wonder_isles.voice.enabled';
  static const String _kVolume = 'wonder_isles.voice.volume';
  static const String _kBgmEnabled = 'wonder_isles.bgm.enabled';
  static const String _kBgmVolume = 'wonder_isles.bgm.volume';
  static const String _kSfxEnabled = 'wonder_isles.sfx.enabled';
  static const String _kSfxVolume = 'wonder_isles.sfx.volume';

  final AudioPlayer _ttsPlayer;
  final AudioPlayer _bgmPlayer;
  final AudioPlayer _sfxPlayer;
  SharedPreferences? _prefs;

  bool _enabled = true;
  double _volume = 0.9;
  bool _bgmEnabled = true;
  double _bgmVolume = 0.35;
  bool _sfxEnabled = true;
  double _sfxVolume = 0.8;
  String? _currentBgm;

  bool get enabled => _enabled;
  double get volume => _volume;
  bool get bgmEnabled => _bgmEnabled;
  double get bgmVolume => _bgmVolume;
  bool get sfxEnabled => _sfxEnabled;
  double get sfxVolume => _sfxVolume;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _enabled = _prefs?.getBool(_kEnabled) ?? true;
    _volume = _prefs?.getDouble(_kVolume) ?? 0.9;
    _bgmEnabled = _prefs?.getBool(_kBgmEnabled) ?? true;
    _bgmVolume = _prefs?.getDouble(_kBgmVolume) ?? 0.35;
    _sfxEnabled = _prefs?.getBool(_kSfxEnabled) ?? true;
    _sfxVolume = _prefs?.getDouble(_kSfxVolume) ?? 0.8;
    await _ttsPlayer.setVolume(_volume);
    await _bgmPlayer.setVolume(_bgmVolume);
    await _sfxPlayer.setVolume(_sfxVolume);
    notifyListeners();
  }

  // ---- TTS ------------------------------------------------------------
  Future<void> setEnabled(bool v) async {
    if (_enabled == v) return;
    _enabled = v;
    await _prefs?.setBool(_kEnabled, v);
    if (!v) await _ttsPlayer.stop();
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    final double clamped = v.clamp(0.0, 1.0);
    if ((_volume - clamped).abs() < 0.001) return;
    _volume = clamped;
    await _ttsPlayer.setVolume(clamped);
    await _prefs?.setDouble(_kVolume, clamped);
    notifyListeners();
  }

  /// [asset] 例：'voice/ri.mp3'（相对于 assets/ 根）
  Future<void> play(String asset) async {
    if (!_enabled) return;
    try {
      await _ttsPlayer.stop();
      await _ttsPlayer.setVolume(_volume);
      await _ttsPlayer.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> stop() => _ttsPlayer.stop();

  // ---- BGM ------------------------------------------------------------
  Future<void> setBgmEnabled(bool v) async {
    if (_bgmEnabled == v) return;
    _bgmEnabled = v;
    await _prefs?.setBool(_kBgmEnabled, v);
    if (!v) {
      await _bgmPlayer.stop();
    } else if (_currentBgm != null) {
      await _startBgm(_currentBgm!);
    }
    notifyListeners();
  }

  Future<void> setBgmVolume(double v) async {
    final double clamped = v.clamp(0.0, 1.0);
    if ((_bgmVolume - clamped).abs() < 0.001) return;
    _bgmVolume = clamped;
    await _bgmPlayer.setVolume(clamped);
    await _prefs?.setDouble(_kBgmVolume, clamped);
    notifyListeners();
  }

  /// 切换到指定场景的 BGM。[sceneKey] 例：'river'、'forest'、'boss'。
  /// 相同 key 重复调用不会重启。
  Future<void> playBgmForScene(String sceneKey) async {
    final String asset = 'bgm/$sceneKey.mp3';
    if (_currentBgm == asset) return;
    _currentBgm = asset;
    if (!_bgmEnabled) return;
    await _startBgm(asset);
  }

  Future<void> _startBgm(String asset) async {
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    _currentBgm = null;
    await _bgmPlayer.stop();
  }

  // ---- SFX ------------------------------------------------------------
  Future<void> setSfxEnabled(bool v) async {
    if (_sfxEnabled == v) return;
    _sfxEnabled = v;
    await _prefs?.setBool(_kSfxEnabled, v);
    if (!v) await _sfxPlayer.stop();
    notifyListeners();
  }

  Future<void> setSfxVolume(double v) async {
    final double clamped = v.clamp(0.0, 1.0);
    if ((_sfxVolume - clamped).abs() < 0.001) return;
    _sfxVolume = clamped;
    await _sfxPlayer.setVolume(clamped);
    await _prefs?.setDouble(_kSfxVolume, clamped);
    notifyListeners();
  }

  /// [name] 例：'brush'（对应 assets/sfx/brush.mp3）
  Future<void> playSfx(String name) async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('sfx/$name.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _ttsPlayer.dispose();
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}