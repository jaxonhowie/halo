# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Halo 是一个 macOS 桌面像素风布偶猫宠物应用。纯 Swift + SpriteKit 实现，无第三方依赖。

## Build & Run

```bash
swift build              # 编译
.build/debug/Halo        # 运行
./run.sh                 # 编译并运行（一键启动）
swift build -c release   # Release 编译（优化）
```

## Architecture

- **Package.swift** — SPM 配置，链接 Cocoa 和 SpriteKit 框架
- **Sources/Halo/main.swift** — AppKit 应用入口，透明无边框置顶窗口 + 右键菜单
- **Sources/Halo/SpriteData.swift** — 布偶猫像素 sprite 数据（32x32 像素矩阵）和颜色表
- **Sources/Halo/CatSpriteScene.swift** — SpriteKit 场景：状态机、动画系统、交互逻辑

## Key Design Decisions

- 窗口 128x128 像素，透明背景，无边框，浮动置顶，支持跨桌面
- 像素 sprite 用 `[[Int]]` 二维数组定义，每个数字对应颜色表索引
- 状态机：idle → walk/sleep（随机切换），点击触发 jump
- 拖拽移动通过 `mouseDragged` 实现，与点击区分（3px 阈值）
- 应用以 `.accessory` 模式运行，不显示在 Dock 中

## Adding New Sprites

在 `SpriteData.swift` 中：
1. 定义新的 32x32 `[[Int]]` 帧数据
2. 添加到对应的 frames 数组（如 `idleFrames`）
3. 如果需要新状态，在 `CatState` 枚举中添加
