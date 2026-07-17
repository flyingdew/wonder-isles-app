import 'character.dart';

/// 场景小诗里的一个 token：要么是普通文字，要么是等待填入的空槽。
class PoemToken {
  const PoemToken.text(this.text) : slotCharId = null;
  const PoemToken.slot(this.slotCharId) : text = '';

  final String text;
  final String? slotCharId;

  bool get isSlot => slotCharId != null;
}

class PoemLine {
  const PoemLine(this.tokens);
  final List<PoemToken> tokens;
}

/// 可以是场景诗（scene != null）或章末大诗（sceneKey == "boss"）。
class ScenePoem {
  const ScenePoem({
    required this.sceneKey,
    required this.title,
    required this.lines,
    this.scene,
  });

  final String sceneKey;
  final SceneId? scene;
  final String title;
  final List<PoemLine> lines;

  /// TTS 音频资源（相对 assets/ 根），文件名与 sceneKey 对齐。
  String get voiceAsset => 'voice/poem_$sceneKey.mp3';

  List<String> get slotCharIds => <String>[
        for (final PoemLine l in lines)
          for (final PoemToken t in l.tokens)
            if (t.isSlot) t.slotCharId!,
      ];
}

const List<ScenePoem> kScenePoems = <ScenePoem>[
  ScenePoem(
    sceneKey: 'river',
    scene: SceneId.river,
    title: '河岸小诗',
    lines: <PoemLine>[
      PoemLine(<PoemToken>[
        PoemToken.slot('ri'),
        PoemToken.text('出江上，'),
      ]),
      PoemLine(<PoemToken>[
        PoemToken.slot('yue'),
        PoemToken.text('映'),
        PoemToken.slot('shui'),
        PoemToken.text('中，'),
      ]),
      PoemLine(<PoemToken>[
        PoemToken.slot('yu'),
        PoemToken.text('跃'),
        PoemToken.slot('huo'),
        PoemToken.text('旁。'),
      ]),
    ],
  ),
  ScenePoem(
    sceneKey: 'forest',
    scene: SceneId.forest,
    title: '山林小诗',
    lines: <PoemLine>[
      PoemLine(<PoemToken>[
        PoemToken.slot('shan'),
        PoemToken.text('中'),
        PoemToken.slot('mu_tree'),
        PoemToken.text('深，'),
      ]),
      PoemLine(<PoemToken>[
        PoemToken.slot('niao'),
        PoemToken.text('鸣'),
        PoemToken.slot('yu_rain'),
        PoemToken.text('落，'),
      ]),
      PoemLine(<PoemToken>[
        PoemToken.text('抬'),
        PoemToken.slot('mu_eye'),
        PoemToken.text('望远。'),
      ]),
    ],
  ),
  ScenePoem(
    sceneKey: 'village',
    scene: SceneId.village,
    title: '村落小诗',
    lines: <PoemLine>[
      PoemLine(<PoemToken>[
        PoemToken.slot('ren'),
        PoemToken.text('在'),
        PoemToken.slot('men'),
        PoemToken.text('内，'),
      ]),
      PoemLine(<PoemToken>[
        PoemToken.text('开'),
        PoemToken.slot('kou'),
        PoemToken.text('问路，'),
      ]),
      PoemLine(<PoemToken>[
        PoemToken.slot('shou'),
        PoemToken.text('指'),
        PoemToken.slot('er'),
        PoemToken.text('听。'),
      ]),
    ],
  ),
  ScenePoem(
    sceneKey: 'field',
    scene: SceneId.field,
    title: '田野小诗',
    lines: <PoemLine>[
      PoemLine(<PoemToken>[
        PoemToken.slot('tian'),
        PoemToken.text('上'),
        PoemToken.slot('niu'),
        PoemToken.text('耕，'),
      ]),
      PoemLine(<PoemToken>[
        PoemToken.slot('yang'),
        PoemToken.slot('ma'),
        PoemToken.text('奔走，'),
      ]),
      PoemLine(<PoemToken>[
        PoemToken.text('抬'),
        PoemToken.slot('zu'),
        PoemToken.text('前行。'),
      ]),
    ],
  ),
];

/// 章末大诗：20 字每字一次。
const ScenePoem kBossPoem = ScenePoem(
  sceneKey: 'boss',
  title: '万物有形 · 长诗',
  lines: <PoemLine>[
    PoemLine(<PoemToken>[
      PoemToken.slot('ri'),
      PoemToken.text('出'),
      PoemToken.slot('shan'),
      PoemToken.text('间，'),
    ]),
    PoemLine(<PoemToken>[
      PoemToken.slot('yu_rain'),
      PoemToken.text('落'),
      PoemToken.slot('shui'),
      PoemToken.text('中；'),
    ]),
    PoemLine(<PoemToken>[
      PoemToken.slot('mu_tree'),
      PoemToken.text('下'),
      PoemToken.slot('huo'),
      PoemToken.text('明，'),
    ]),
    PoemLine(<PoemToken>[
      PoemToken.slot('yu'),
      PoemToken.text('跃'),
      PoemToken.slot('niao'),
      PoemToken.text('鸣。'),
    ]),
    PoemLine(<PoemToken>[
      PoemToken.slot('niu'),
      PoemToken.slot('yang'),
      PoemToken.text('入'),
      PoemToken.slot('tian'),
      PoemToken.text('，'),
    ]),
    PoemLine(<PoemToken>[
      PoemToken.slot('ma'),
      PoemToken.text('行'),
      PoemToken.slot('men'),
      PoemToken.text('东；'),
    ]),
    PoemLine(<PoemToken>[
      PoemToken.slot('ren'),
      PoemToken.text('开'),
      PoemToken.slot('kou'),
      PoemToken.text('语，'),
    ]),
    PoemLine(<PoemToken>[
      PoemToken.slot('mu_eye'),
      PoemToken.text('视'),
      PoemToken.slot('er'),
      PoemToken.text('听。'),
    ]),
    PoemLine(<PoemToken>[
      PoemToken.slot('shou'),
      PoemToken.text('举'),
      PoemToken.slot('zu'),
      PoemToken.text('行，'),
    ]),
    PoemLine(<PoemToken>[
      PoemToken.slot('yue'),
      PoemToken.text('照其中。'),
    ]),
  ],
);

ScenePoem poemFor(SceneId scene) =>
    kScenePoems.firstWhere((ScenePoem p) => p.scene == scene);
