# Mapping

<p align="center">
  <img src="Mapping/Assets.xcassets/AppIcon.appiconset/icon_1024.png" width="128" height="128" alt="Mapping Icon">
</p>

<p align="center">
  macOS 菜单栏快捷键管理工具 —— 轻量、快速、可视化配置
</p>

## 功能

- **全局快捷键** — 一键启动任意应用（Option+G 打开 Chrome 等）
- **应用内按键重映射** — 在特定应用中重新定义快捷键（如 Wave 终端的 Block 切换）
- **应用激活触发** — 切换到任意应用时自动执行动作（如自动切换输入法）
- **脚本执行** — 触发时运行任意 Shell 脚本
- **延迟控制** — 多步动作之间插入精确的毫秒级延迟
- **使用统计** — 跟踪每个快捷键的触发次数
- **可视化配置** — 菜单栏弹窗中直接添加/编辑/删除分组和映射，支持快捷键录制

## 截图

菜单栏 ⌘ 图标，点击展开管理面板：

- 分组管理：按颜色和图标区分，支持限定特定应用
- 映射列表：显示触发键、动作类型，hover 显示编辑/删除
- 快捷键录制：点击录制框，按下组合键即可捕获
- 使用统计：头部显示今日/总触发次数

## 安装

### 从源码构建

```bash
# 依赖：Xcode 16+, XcodeGen
brew install xcodegen

git clone https://github.com/o98k-ok/mapping.git
cd mapping

# 构建
./build.sh

# 构建并运行
./build.sh --run

# 构建并安装到 /Applications
./build.sh --install
```

> ⚠️ 首次启动需要在 **系统设置 → 隐私与安全 → 辅助功能** 中授权 Mapping

## 配置

配置文件位于 `~/.config/mapping/config.json`，也可以通过菜单栏 GUI 直接编辑。

### 配置结构

```json
{
  "groups": [
    {
      "name": "分组名称",
      "color": "#5B8DEF",
      "icon": "keyboard",
      "isEnabled": true,
      "bundleIdentifiers": ["com.example.app"],
      "mappings": [...]
    }
  ]
}
```

### 触发方式

| 类型 | 说明 | 示例 |
|------|------|------|
| `hotkey` | 按下快捷键触发 | `{"type": "hotkey", "key": "g", "modifiers": ["option"]}` |
| `appActivation` | 应用切换到前台时触发 | `{"type": "appActivation"}` |

### 动作类型

| 类型 | 说明 | 参数 |
|------|------|------|
| `openApp` | 打开/切换到应用 | `bundleId`, `appName` |
| `sendKeyCombo` | 模拟按键组合 | `key`, `modifiers` |
| `runShellScript` | 执行 Shell 脚本 | `script` |
| `delay` | 延迟等待 | `delayMs`（毫秒） |

### 修饰键

`command` `option` `control` `shift`

### 配置示例

```json
{
  "name": "Block切换1",
  "trigger": { "type": "hotkey", "key": "1", "modifiers": ["command"] },
  "actions": [
    { "type": "sendKeyCombo", "key": "1", "modifiers": ["control", "shift"] },
    { "type": "delay", "delayMs": 50 },
    { "type": "sendKeyCombo", "key": "m", "modifiers": ["command"] }
  ]
}
```

## 技术栈

- **Swift + SwiftUI** — 原生 macOS 开发
- **MenuBarExtra** — macOS 14+ 菜单栏 API
- **CGEventTap** — 系统级键盘事件拦截
- **CGEventPost** — 按键模拟
- **NSWorkspace** — 应用监控与启动

## License

MIT
