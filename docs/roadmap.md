# 奇思岛 · 里程碑与排期（Flutter 版）

按业余时间投入估算，串行排期。若时间充裕可并行推进内容与代码。

## W-1 · Cocos 原型（已完成，仅记录）

- [x] 定名《奇思岛》，首章《字之岛》
- [x] 设计文档、首章内容清单落库
- [x] 20 字字库 JSON、四种字形 PNG、20 段 Edge TTS 语音、4 张水墨场景背景
- [x] Cocos Creator 3.8 单字闭环原型（"日"字勘探→拼合→演变→应用）
- [x] 内容与玩法验证通过 → 决定用 Flutter 重做正式版

资产整体搬迁到 `wonder-isles-app/assets/`，原 Cocos 工程留在
`E:\demo\game-demo\` 作参考。

## W0 · Flutter 工程与骨架（本周）

- [x] 独立 git 仓库 `wonder-isles-app/`
- [x] `pubspec.yaml`、`analysis_options.yaml`、`.gitignore`
- [x] `lib/` 骨架：主题、字库模型/加载、存档、TTS 服务、四步页面
- [x] 资产复用：字库 JSON / 字形 PNG / TTS mp3 / 场景背景
- [x] 装 Flutter SDK 后 `flutter create .` 生成平台目录，跑通 `flutter run`

## W1 · 单字闭环打磨

目标：河岸场景 5 字（日/月/水/鱼/火）在真机上完整闭环，主观感受"孩子愿意再玩一次"。

- [x] 挖掘阶段：刷子半径按 canvas 短边动态（24-44）、完成阈值降至 0.55、完成触发 mediumImpact
- [x] 拼合阶段：统一 2×2 四片，hover 阈值 0.90 / snap 阈值 0.65；落位/错位/完成分层 haptic
- [ ] 演变阶段：4 帧过渡 + 字幕逐句高亮 + 语速再确认
- [x] 应用阶段：干扰项来源改为同场景其它字，避免"离得太远"
- [x] 单字通关：场景中对应物件（河岸太阳/月亮…）从灰变亮的仪式感动画

## W2 · 20 字内容 + 场景小诗

- [x] 山林 / 村落 / 田野 三个场景全部接入 5 字
- [x] 每场景通关触发"小诗关"（5 字组诗，拖拽入位）
- [x] Boss 关：20 字组长诗
- [x] 音效（毛笔沙沙 / 水声 / 鸟鸣）与 BGM（古琴/箫氛围乐）

## W3 · 系统与家长端

- [x] 本地存档：点亮字 id + 每字回访次数（已在 `ProgressStore` 中实现）
- [x] 家长视图：点亮总数、最喜欢的字、共读小片段建议
- [x] 主菜单设置：音量、TTS 开关、BGM/SFX 通道、清空进度
- [x] 简单成就：首次点亮、集齐一岛、连续 3 天访问

## W4 · 多端出包

- [x] Android APK：`flutter build apk --release` 已跑通，产物 `build/app/outputs/flutter-apk/app-release.apk`，真机分发测试待安排
- [ ] iOS TestFlight：`flutter build ipa`，需苹果开发者账号
- [x] Web H5：`flutter build web --release` 已跑通，产物 `build/web`，部署到 Vercel/Netlify 或自有 CDN 待安排
- [x] 屏幕适配：全局锁竖屏，首页 LayoutBuilder 自适应窄屏；四步 stage 与列表页均已用 LayoutBuilder / GridView / ListView

## W5 · 内测与调优

- [ ] 找 3-5 个 6-8 岁孩子实际玩 20 分钟
- [ ] 家长访谈：能否独立操作、是否愿意再玩、家长焦虑点
- [ ] 根据反馈调难度曲线、磁吸阈值、TTS 语速
- [ ] 修 bug、优化冷启动与首屏

## 后续版本（不排入 v1）

- 会意 / 形声 / 指事三个子章节
- 云账号与多设备同步（Supabase / Firebase 择一）
- 真人配音替换 TTS
- 数之岛（第二章）玩法原型
- 微信小游戏合规化（若走企业主体路线）

## 依赖与外部准备

- 苹果开发者账号（99 美元/年）— W4 前购买即可
- ICP 备案（个人号，10-20 天）— Web 上线前完成
- 域名一枚（可选）— 用于 Web H5 分发
