import 'package:audioplayers/audioplayers.dart';

/// 字源 TTS 语音播放，包一层单实例，避免同时播放多段。
class VoiceService {
  VoiceService() : _player = AudioPlayer();

  final AudioPlayer _player;
  bool _enabled = true;

  bool get enabled => _enabled;
  set enabled(bool v) {
    _enabled = v;
    if (!v) _player.stop();
  }

  /// [asset] 例如 "voice/ri.mp3"（相对于 assets/）。
  Future<void> play(String asset) async {
    if (!_enabled) return;
    await _player.stop();
    await _player.play(AssetSource(asset));
  }

  Future<void> stop() => _player.stop();

  void dispose() {
    _player.dispose();
  }
}
