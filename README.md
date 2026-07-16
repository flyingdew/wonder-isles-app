# 奇思岛 · Wonder Isles (Flutter 版)

一款面向 6-8 岁孩子的跨平台"边玩边学"应用。首章 **字之岛**，以"汉字考古"为核心玩法，
让孩子通过 **勘探 → 拼合 → 演变 → 应用** 四步循环，理解汉字的造字法与字源故事。

> 前作是用 Cocos Creator 3.8 做的原型，验证过内容与玩法（20 字 + 4 场景 + TTS 语音都在
> `E:\demo\game-demo\wonder-isles\`）。本仓库是**用 Flutter 重做的正式版**，独立 git
> 仓库，一套 Dart 代码同时导出 iOS / Android / Web。

## 目录

```
wonder-isles-app/
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart
│   ├── app_theme.dart           水墨 · 暖色主题
│   ├── data/                    字库模型 + 加载器
│   ├── services/                本地存档、TTS 语音
│   ├── pages/                   主菜单 / 岛屿地图 / 场景 / 单字四步
│   └── widgets/                 挖掘/拼合/演变/应用 四个阶段组件
├── assets/
│   ├── data/characters.json     20 字字库（scene、字源、填空题）
│   ├── glyph/<id>/{oracle,bronze,seal,kai}.png   四种字形 4×20 = 80 张
│   ├── voice/<id>.mp3           Edge TTS 20 段
│   └── scenes/{river,forest,village,field,palette}.png
└── docs/
    ├── design.md
    ├── chapter-01-字之岛.md
    └── roadmap.md
```

## 本地 Web dev server（H5 调试）

推荐前台跑，方便按 `r` 热重载 / `R` 热重启：

`powershell
cd E:\demo\wonder-isles\wonder-isles-app
flutter run -d web-server --web-port=8123 --web-hostname=localhost
`

浏览器打开 <http://localhost:8123>。首次编译要等 40-60 秒，之后差量编译秒级。
浏览器缓存较顽固，改动看不到时按 `Ctrl+Shift+R` 硬刷新一次。

如果需要**后台常驻**（关掉终端也不停），用下面这段：

`powershell
cd E:\demo\wonder-isles\wonder-isles-app
Start-Process -FilePath "flutter" `
  -ArgumentList "run","-d","web-server","--web-port=8123","--web-hostname=localhost" `
  -WorkingDirectory (Get-Location) `
  -RedirectStandardOutput ".\.web-server.log" `
  -RedirectStandardError  ".\.web-server.err.log" `
  -WindowStyle Hidden
`

日志实时看：`Get-Content .\.web-server.log -Wait`。

**停掉 dev server**（前台按 `Ctrl+C` 即可；后台版本用这句）：

`powershell
Get-Process dart, dartaotruntime -ErrorAction SilentlyContinue | Stop-Process -Force
`

**重启一次**：先执行上面的停掉命令，然后再跑一次启动命令。

> Debug + Web 环境下，首页会额外出现「DEBUG · 仅 Web 调试可见」的胶囊面板，
> 可以直达任意场景小诗 / Boss 长诗，方便测试。岛屿地图上的 Boss 入口也会
> 直接解锁。release 构建（`flutter build apk/web --release`）不会带这些。

## 快速开始（有 Flutter SDK）

目前 `lib/` 与 `assets/` 是手工写好的，平台目录还没建，第一次拉下来要跑一下：

```powershell
cd wonder-isles-app
flutter --version               # 需要 Flutter 3.22+ / Dart 3.4+
flutter create .                # 生成 android/ ios/ web/ 等平台目录
flutter pub get
flutter run                     # 默认设备；-d chrome / -d windows 也行
```

> 如果这台机器还没装 Flutter，可以从 <https://docs.flutter.dev/get-started/install/windows>
> 装 stable 通道 3.22+，把 `flutter\bin` 加进 PATH。

## 技术栈

- **Flutter 3.22+ / Dart 3.4+**，Material 3。
- `audioplayers`：TTS mp3 播放。
- `shared_preferences`：本地存档（点亮的字、回访次数）。
- `provider`：轻量状态注入。
- 挖掘阶段用 `CustomPainter + BlendMode.dstOut` 做泥土遮罩擦除；拼合用 `Draggable` +
  磁吸；演变用 `AnimatedSwitcher` 做 4 帧过渡。

## 与 Cocos 版的关系

- **复用**：字库 JSON、字形 PNG、TTS mp3、场景水墨图，直接搬过来。
- **替换**：引擎从 Cocos Creator 换到 Flutter，核心循环用原生 Widget 重写。
- **保留**：产品定位、四步循环、家长端极简策略、里程碑节奏都不变。

## 里程碑

- **W1**（本周）：单字闭环跑通，主菜单 / 岛屿地图 / 河岸 5 字全部可玩。✅ 骨架已完成，需装 SDK 后跑一次 `flutter run` 验证。
- **W2**：4 场景 × 20 字全部接入 + 场景小诗 + 家长视图。
- **W3**：Boss 关（20 字组诗）+ 音效 BGM + 屏幕适配。
- **W4**：Android APK / iOS TestFlight / Web H5 三端出包。

详见 [docs/roadmap.md](docs/roadmap.md)。
