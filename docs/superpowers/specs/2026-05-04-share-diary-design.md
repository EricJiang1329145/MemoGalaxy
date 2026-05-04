# 转发功能设计

## Overview

用户可以将日记一键生成图片，分享到社交媒体平台（微信、微博、小红书等）。

## 功能入口

DetailView 导航栏右侧，添加分享按钮（和编辑按钮并排）。

## 分享图片内容

```
┌─────────────────────────────────────┐
│     [emoji大号]                      │  ← 心情颜色渐变背景
│                                     │
│  日记标题                     日期  │
│                                     │
│  日记正文内容...                      │  ← 可多行
│                                     │
│  [图1] [图2] [图3] [图4]            │  ← 小缩略图横向排列（最多4张）
│                                     │
│                           MemoGalaxy│  ← 水印
└─────────────────────────────────────┘
```

### 布局细节

- **背景**：心情对应颜色的渐变（从主题色到透明）
- **Emoji**：60pt 大号，居中显示
- **标题**：system(.title, design: .rounded)，粗体
- **日期**：footnote 样式，副标题右对齐
- **正文**：根据用户设置的字体大小显示
- **缩略图**：60x60pt 圆角矩形，最多4张横向排列，无图则不显示
- **水印**：右下角，"MemoGalaxy" 文字，caption 样式，透明度50%

## 技术实现

### ImageRenderer

使用 SwiftUI `ImageRenderer` 将专用分享视图渲染为 `UIImage`。

```swift
struct DiaryShareView: View {
    let entry: EmotionEntry
    let fontSize: CGFloat

    // 上述布局的 View
}

func generateShareImage() -> UIImage? {
    let renderer = ImageRenderer(content: DiaryShareView(...))
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}
```

### UIActivityViewController

```swift
func shareDiary() {
    guard let image = generateShareImage() else { return }
    let activityVC = UIActivityViewController(
        activityItems: [image],
        applicationActivities: nil
    )
    // present
}
```

## 流程

1. 用户在 DetailView 点击导航栏分享按钮
2. 系统生成分享图片
3. 弹出 UIActivityViewController 系统分享面板
4. 用户选择分享目标（微信、微博等）

## 依赖

- SwiftUI ImageRenderer（iOS 16+）
- UIActivityViewController（系统原生）
- 心情颜色主题（已有 emojiToColorMap）

## 改动文件

- `DetailView.swift` - 添加分享按钮
- `DiaryShareView.swift`（新建） - 专门用于渲染分享图片的 View
