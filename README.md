# Halo

macOS 桌面像素风布偶猫宠物。纯 Swift + SpriteKit 实现，无第三方依赖。

## 功能

- **待机** — 猫咪坐在桌面，自然眨眼动画（9 帧，6fps）
- **走动** — 水平移动，碰壁自动转向（9 帧）
- **睡觉** — 蜷缩身体，漂浮 ZZZ 动画（4 帧）
- **想吃鱼** — 猫咪渴望吃鱼的可爱动画（11 帧）
- **跳跃** — 点击触发，带 "喵~" 文字气泡
- **拖拽移动** — 按住猫咪拖到桌面任意位置
- **右键菜单** — 手动切换状态或退出
- **桌面置顶** — 透明无边框窗口，浮动在所有窗口之上
- **跨桌面** — 所有桌面空间可见
- **不在 Dock 显示** — 以 accessory 模式运行

## 安装与启动

```bash
# 编译运行（一键）
./run.sh

# 或者分步执行
swift build
.build/debug/Halo

# Release 编译（优化）
swift build -c release
```

要求 macOS 13+，Xcode Command Line Tools。

## 基本操作

| 操作 | 效果 |
|------|------|
| 左键点击 | 猫咪跳跃 + "喵~" |
| 按住拖拽 | 移动猫咪位置 |
| 右键 | 打开菜单（待机/走动/睡觉/想吃鱼/退出） |

猫咪会在待机、走动、睡觉之间自动切换状态。点击会打断当前状态触发跳跃。

## 项目结构

```
Sources/Halo/
├── main.swift              # AppKit 入口，透明无边框窗口与事件处理
├── CatSpriteScene.swift    # SpriteKit 场景：状态机、动画、交互
├── SpriteData.swift        # Sprite 帧数据与颜色表（字符映射编码）
└── Resources/              # PNG 像素动画资源
    ├── idle/               # 待机动画（idle0-idle11，12 帧）
    ├── walk/               # 走动动画（walk0-walk8，9 帧）
    ├── sleep/              # 睡觉动画（sleep0-sleep3，4 帧）
    └── wantFish/           # 想吃鱼动画（wantFish0-wantFish10，11 帧）
```

## 技术实现

- **渲染** — SpriteKit，PNG 纹理以 `.nearest` 过滤保持像素锐利
- **窗口** — AppKit NSWindow，透明无边框，`.floating` 置顶
- **状态机** — idle / walk / sleep / wantFish / jump，带权重随机切换
- **动画系统** — 固定时间步长（1/60s），各状态独立帧率
- **交互** — 左键点击跳跃，拖拽移动，右键菜单切换状态
