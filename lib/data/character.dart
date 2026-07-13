/// 一个汉字条目（对应字库 JSON 的一行）。
class WonderCharacter {
  const WonderCharacter({
    required this.id,
    required this.char,
    required this.pinyin,
    required this.scene,
    required this.order,
    required this.story,
    required this.quiz,
  });

  final String id;
  final String char;
  final String pinyin;
  final SceneId scene;
  final int order;
  final String story;
  final QuizConfig quiz;

  /// 演变四帧的资源路径：oracle → bronze → seal → kai。
  List<String> get evolutionFrames => <String>[
        'assets/glyph/$id/oracle.png',
        'assets/glyph/$id/bronze.png',
        'assets/glyph/$id/seal.png',
        'assets/glyph/$id/kai.png',
      ];

  /// 甲骨文碎片图（拼合阶段使用）。
  String get oracleImage => 'assets/glyph/$id/oracle.png';

  /// 楷体成品图（拼合完成的样子）。
  String get regularImage => 'assets/glyph/$id/kai.png';

  /// TTS 语音文件。
  String get voiceAsset => 'voice/$id.mp3';

  factory WonderCharacter.fromJson(Map<String, dynamic> json) {
    return WonderCharacter(
      id: json['id'] as String,
      char: json['char'] as String,
      pinyin: json['pinyin'] as String,
      scene: SceneId.fromKey(json['scene'] as String),
      order: json['order'] as int,
      story: json['story'] as String,
      quiz: QuizConfig.fromJson(json['quiz'] as Map<String, dynamic>),
    );
  }
}

class QuizConfig {
  const QuizConfig({required this.text, required this.answer});

  /// 例如 "太{blank}出来了"。
  final String text;
  final String answer;

  factory QuizConfig.fromJson(Map<String, dynamic> json) {
    return QuizConfig(
      text: json['text'] as String,
      answer: json['answer'] as String,
    );
  }
}

enum SceneId {
  river('river', '河岸', 'assets/scenes/river.png'),
  forest('forest', '山林', 'assets/scenes/forest.png'),
  village('village', '村落', 'assets/scenes/village.png'),
  field('field', '田野', 'assets/scenes/field.png');

  const SceneId(this.key, this.label, this.background);

  final String key;
  final String label;
  final String background;

  static SceneId fromKey(String key) {
    return SceneId.values.firstWhere((SceneId s) => s.key == key);
  }
}
