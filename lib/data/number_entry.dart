/// 数之岛一条数字（对应 assets/data/numbers.json 的一行）。
///
/// v0 只覆盖 1-5，用于"云上小铺"经营场景：
///   - 数一数：货架摆 [num] 件商品
///   - 配一配：顾客要 [num] 件，孩子拖入箩筐
///   - 找零：顾客给 [change.given]，商品价 [change.price]，差额 = given - price
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

/// 商品的临时视觉描述。v0 用色块 + 单字标签兜底，
/// W2 会替换为 assets/numbers/goods/<id>.png。
class GoodStyle {
  const GoodStyle({
    required this.label,
    required this.name,
    required this.colorKey,
  });

  final String label;
  final String name;
  /// 对应 InkPalette 中的键：vermilion / ochre / reed / dusk / glow。
  final String colorKey;

  factory GoodStyle.fromJson(Map<String, dynamic> json) {
    return GoodStyle(
      label: json['label'] as String,
      name: json['name'] as String,
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