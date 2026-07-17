/// 数之岛一条数字（对应 assets/data/numbers.json 的一行）。
class NumberEntry {
  const NumberEntry({
    required this.id,
    required this.value,
    required this.char,
    required this.pinyin,
    required this.day,
    required this.good,
    required this.rhyme,
    required this.change,
  });

  final String id;
  final int value;
  final String char;
  final String pinyin;
  final int day;
  final GoodStyle good;
  final String rhyme;
  final ChangeConfig change;

  /// 童谣 TTS 资源（相对 assets/ 根，对应 audioplayers AssetSource）。
  String get rhymeVoiceAsset => 'voice/num_$id.mp3';

  factory NumberEntry.fromJson(Map<String, dynamic> json) {
    return NumberEntry(
      id: json['id'] as String,
      value: (json['num'] as num).toInt(),
      char: json['char'] as String,
      pinyin: json['pinyin'] as String,
      day: (json['day'] as num).toInt(),
      good: GoodStyle.fromJson(json['good'] as Map<String, dynamic>),
      rhyme: json['rhyme'] as String,
      change:
          ChangeConfig.fromJson(json['change'] as Map<String, dynamic>),
    );
  }
}

/// 商品的视觉描述。
class GoodStyle {
  const GoodStyle({
    required this.label,
    required this.name,
    required this.asset,
    required this.colorKey,
  });

  final String label;
  final String name;
  /// 位图资源 id，对应 assets/numbers/goods/<asset>.png。
  final String asset;
  /// 兜底色（水墨阴影/色块 dim 状态使用）。
  /// 键：vermilion / ochre / reed / dusk / glow。
  final String colorKey;

  /// 完整资源路径。
  String get assetPath => 'assets/numbers/goods/$asset.png';

  factory GoodStyle.fromJson(Map<String, dynamic> json) {
    return GoodStyle(
      label: json['label'] as String,
      name: json['name'] as String,
      asset: json['asset'] as String,
      colorKey: json['color'] as String,
    );
  }
}

/// 找零配置：顾客付 [given]，商品价 [price]，孩子需要凑出的差额 = given - price。
class ChangeConfig {
  const ChangeConfig({required this.given, required this.price});

  final int given;
  final int price;
  int get diff => given - price;

  factory ChangeConfig.fromJson(Map<String, dynamic> json) {
    return ChangeConfig(
      given: (json['given'] as num).toInt(),
      price: (json['price'] as num).toInt(),
    );
  }
}