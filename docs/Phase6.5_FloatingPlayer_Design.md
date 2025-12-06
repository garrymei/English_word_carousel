# Phase 6.5: 桌面悬浮轮播助手 + 科技 UI

## 目标
- 独立浮窗（macOS/Windows），置顶显示、透明毛玻璃、无边框可拖动
- 科技感视觉：霓虹渐变、玻璃模糊、Orbitron 字体、波纹动画
- 快捷键：空格播放/暂停、方向键切换、ESC关闭、全局呼出
- 智能同步：主窗与浮窗词卡与播放状态实时一致
- 独立运行：可单独启动浮窗，不依赖主界面

## 架构
- UI 层：`lib/floating_player/widgets/player_card.dart`
- 入口：`lib/floating_player/main.dart`
- 控制：`lib/floating_player/services/floating_controller.dart`
- 通信：`lib/services/window_service.dart`

## 开发任务拆解
|任务|说明|工期|
|---|---|---|
|A1|整合桌面窗口插件（mac/win）|0.5 d|
|A2|浮窗主框架搭建（透明/置顶/拖动）|1 d|
|A3|科技感 UI 实现（背景+字体+动画）|2 d|
|A4|轮播控制与状态同步|1.5 d|
|A5|快捷键与音频联动|1 d|
|A6|跨平台适配与测试|1.5 d|
|A7|性能优化与回归测试|1 d|

## 验收标准
- 浮窗显示：主应用启动轮播后自动弹出
- 置顶稳定：窗口始终在最前
- UI 风格：科技感、动效流畅、无卡顿
- 快捷键：响应正确
- 状态同步：主窗与浮窗词卡一致
- 内存占用：< 350 MB
- 性能：动画 60 fps、响应 < 200 ms

## 产出物
- `/lib/floating_player/main.dart` 浮窗入口
- `/lib/floating_player/widgets/player_card.dart` UI 模块
- `/lib/floating_player/services/floating_controller.dart` 控制器
- `/lib/services/window_service.dart` 状态通道（后续接插件）
- `/assets/lottie/neon_wave.json` 背景动画
- `/assets/fonts/Orbitron.ttf` 科技字体
- `/assets/icons/floating_icon.png` 应用图标

## 视觉风格关键词
neon gradient / cyberpunk blue / glass blur / minimal card / orbitron font / wave particle animation