/// 小铺算术：数之岛全 5 天点亮后开放的收官关。
///
/// 6 道题，加减混合，值域 [0, 5]（与数之岛现有 5 天字库对齐）。选项固定 4 个，
/// 全部落在值域内，含答案 + 三条常见误答。视觉复用 assets/numbers/goods/。
class MathQuestion {
  const MathQuestion({
    required this.prompt,
    required this.a,
    required this.b,
    required this.isAdd,
    required this.goodAsset,
    required this.options,
  });

  final String prompt;
  final int a;
  final int b;
  final bool isAdd;

  /// 商品位图名，映射到 assets/numbers/goods/<goodAsset>.png。
  final String goodAsset;

  /// 4 个选项，其中恰好一个 == answer。
  final List<int> options;

  int get answer => isAdd ? a + b : a - b;
  String get op => isAdd ? '+' : '-';
  String get assetPath => 'assets/numbers/goods/$goodAsset.png';
}

const List<MathQuestion> kMathQuestions = <MathQuestion>[
  MathQuestion(
    prompt: '篮里摆着 2 个苹果，掌柜又添了 3 个，一共几个？',
    a: 2, b: 3, isAdd: true, goodAsset: 'apple',
    options: <int>[3, 4, 5, 6],
  ),
  MathQuestion(
    prompt: '货架上先摆了 1 个梨，接着又来了 3 个，一共几个？',
    a: 1, b: 3, isAdd: true, goodAsset: 'pear',
    options: <int>[2, 3, 4, 5],
  ),
  MathQuestion(
    prompt: '小客人挑了 2 颗枣，掌柜再拈 2 颗放进袋子，一共几颗？',
    a: 2, b: 2, isAdd: true, goodAsset: 'jujube',
    options: <int>[3, 4, 5, 2],
  ),
  MathQuestion(
    prompt: '筐里 5 只桃儿，卖出 2 只，还剩几只？',
    a: 5, b: 2, isAdd: false, goodAsset: 'peach',
    options: <int>[2, 3, 4, 1],
  ),
  MathQuestion(
    prompt: '糖罐里 4 颗糖，小客带走 1 颗，还剩几颗？',
    a: 4, b: 1, isAdd: false, goodAsset: 'candy',
    options: <int>[2, 3, 4, 5],
  ),
  MathQuestion(
    prompt: '早上先摆了 3 个苹果，中午又添了 2 个，一共几个？',
    a: 3, b: 2, isAdd: true, goodAsset: 'apple',
    options: <int>[3, 4, 5, 6],
  ),
];