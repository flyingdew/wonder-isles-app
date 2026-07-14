import 'package:audioplayers/audioplayers.dart';

/// 字源 TTS 语音播放。
/// 资源约定放在 assets/voice/<id>.mp3，例如 assets/voice/ri.mp3。
class VoiceService {
  VoiceService() : _player = AudioPlayer() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player;
  bool _enabled = true;

  bool get enabled => _enabled;
  set enabled(bool v) {
    _enabled = v;
    if (!v) {
      _player.stop();
    }
  }

  /// [asset] 例：'voice/ri.mp3'（相对于 assets/ 根）
  Future<void> play(String asset) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // 静默忽略播放失败，避免打断儿童体验流。
    }
  }

  Future<void> stop() => _player.stop();

  void dispose() {
    _player.dispose();
  }
}
