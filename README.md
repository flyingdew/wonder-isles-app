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

平台目录 `android/` `ios/` `web/` 已生成并入库，第一次拉下来只需装依赖：

```powershell
cd wonder-isles-app
flutter --version               # 需要 Flutter 3.22+ / Dart 3.4+
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

## 出包

Android release APK:

```powershell
$env:JAVA_HOME="C:\Program Files\Java\jdk-17"
$env:ANDROID_SDK_ROOT="D:\Android\android-sdk"
cd E:\demo\wonder-isles\wonder-isles-app
flutter build apk --release
```

产物：`build\app\outputs\flutter-apk\app-release.apk`（当前约 53 MB，含 CC0
音频与 80 张字形 PNG）。Gradle 会在 pub-cache 跨盘时抛 Kotlin 增量缓存红字，属
audioplayers_android 5.2.1 已知问题，不影响产物。

Web release:

```powershell
cd E:\demo\wonder-isles\wonder-isles-app
flutter build web --release
```

产物：`build\web\`（canvaskit 版，约 39 MB）。整个目录静态托管即可，
`index.html` 是入口。本地验证可以用 `python -m http.server` 或
`npx serve build/web`。

iOS TestFlight 需要苹果开发者账号 + macOS 打包，还没验证。

## 里程碑

- **W1**：单字闭环 ✅
- **W2**：4 场景 × 20 字 + 场景小诗 + Boss 长诗 ✅
- **W3**：家长视图 + 设置（TTS/BGM/SFX 三通道）+ 成就系统 + 音频接入 ✅
- **W4**：Android APK ✅ / Web H5 ✅ / iOS TestFlight ⏳

详见 [docs/roadmap.md](docs/roadmap.md).
## CI/CD：GitHub Actions → Vercel

Web 版通过 `.github/workflows/deploy-web.yml` 自动构建并发布到 Vercel：

- **触发**：`push` 到 `main` 且改动涉及 `lib/`、`web/`、`assets/`、`pubspec.*`、`vercel.json` 或工作流本身；也可在 Actions 页面手动 `workflow_dispatch`，选择 `preview` 或 `production`。
- **流程**：`subosito/flutter-action` 装 Flutter 3.22.3 → `flutter pub get` → `flutter analyze`（非阻断）→ `flutter build web --release --web-renderer canvaskit` → 把 `vercel.json` 拷进 `build/web/` → `vercel pull` + `vercel deploy`。
- **产物路径**：`build/web/`；SPA rewrite 与静态资源缓存策略见根目录 `vercel.json`。

### 需要在仓库 Settings → Secrets and variables → Actions 里配置：

| Secret | 说明 |
| --- | --- |
| `VERCEL_TOKEN` | Vercel 账号 Token（<https://vercel.com/account/tokens>） |
| `VERCEL_ORG_ID` | Vercel Team/Personal 的 org id |
| `VERCEL_PROJECT_ID` | 目标 Project id |

拿到 `ORG_ID` / `PROJECT_ID` 最快的方式：在本地项目根目录跑一次

```powershell
npm i -g vercel
vercel link          # 交互式选到目标 project
Get-Content .vercel\project.json
```

`.vercel/project.json` 里就是这两个 id（`orgId` / `projectId`）。`.vercel/` 目录已被 `.gitignore` 忽略，不会入库。

## CI/CD：Android APK Release

Android release APK 通过 `.github/workflows/release-android.yml` 自动构建并（可选）发到 GitHub Releases。

### 触发方式

1. **打 tag**（推荐）：本地 `git tag v0.1.1 && git push origin v0.1.1`，CI 自动构建并以该 tag 建 Release。
2. **手动**：Actions 页面 → *Build Android APK & Release* → **Run workflow**。
   - `version_tag` 留空 → 只构建 APK，作为 workflow artifact 保留 30 天，不发 Release；
   - 填入 `vX.Y.Z` → 构建完自动发 Release；
   - `prerelease` 选 `true` 会打 pre-release 标签。

### 产物命名

- `wonder-isles-<tag>-universal.apk` — 通用包
- `wonder-isles-<tag>-arm64-v8a.apk` — 主流真机（推荐）
- `wonder-isles-<tag>-armeabi-v7a.apk` — 老 ARM
- `wonder-isles-<tag>-x86_64.apk` — 模拟器 / 少数 x86 设备

### 正式签名（可选）

不配任何 secret 时，CI 会沿用 Flutter 脚手架的 debug keystore 签名（`android/app/build.gradle.kts` 里的默认行为），可以直接装但**不适合上应用商店**。要用正式 keystore：

1. 本地生成一次 keystore（只做一次，别丢）：

   ```powershell
   keytool -genkey -v -keystore wonder-isles-upload.jks `
     -keyalg RSA -keysize 2048 -validity 10000 `
     -alias wonder-isles
   ```

2. 生成 base64 内容（Windows PowerShell）：

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("wonder-isles-upload.jks")) `
     | Set-Clipboard
   ```

3. 到仓库 Settings → Secrets and variables → Actions 添加：

   | Secret | 说明 |
   | --- | --- |
   | `ANDROID_KEYSTORE_BASE64` | 上一步剪贴板里的 base64 字符串 |
   | `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
   | `ANDROID_KEY_ALIAS` | 上面 `-alias` 的值（示例：`wonder-isles`） |
   | `ANDROID_KEY_PASSWORD` | key 密码（一般与 keystore 密码相同） |

4. 让 `android/app/build.gradle.kts` 读取 `android/key.properties`（工作流会在 CI 里生成这个文件）：

   ```kotlin
   import java.util.Properties
   import java.io.FileInputStream

   val keystorePropertiesFile = rootProject.file("key.properties")
   val keystoreProperties = Properties().apply {
       if (keystorePropertiesFile.exists()) {
           load(FileInputStream(keystorePropertiesFile))
       }
   }

   android {
       // ...
       signingConfigs {
           create("release") {
               if (keystorePropertiesFile.exists()) {
                   keyAlias      = keystoreProperties["keyAlias"] as String
                   keyPassword   = keystoreProperties["keyPassword"] as String
                   storeFile     = file(keystoreProperties["storeFile"] as String)
                   storePassword = keystoreProperties["storePassword"] as String
               }
           }
       }
       buildTypes {
           release {
               signingConfig = if (keystorePropertiesFile.exists())
                   signingConfigs.getByName("release")
               else
                   signingConfigs.getByName("debug")
           }
       }
   }
   ```

   `android/key.properties` 已被忽略，不会入库。keystore 本体（`*.jks` / `*.keystore`）也在 `.gitignore` 里，务必单独备份，一旦丢失就无法向已发布的 APK 做增量升级。
