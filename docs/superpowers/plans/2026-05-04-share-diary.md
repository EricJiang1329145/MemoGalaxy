# Share Diary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用户在 DetailView 点击分享按钮，一键生成日记图片并弹出系统分享面板

**Architecture:** 创建 DiaryShareView 专用视图用于渲染分享图片，使用 ImageRenderer 生成 UIImage，通过 UIActivityViewController 分享

**Tech Stack:** SwiftUI ImageRenderer, UIActivityViewController, iOS 16+

---

## Task 1: Create DiaryShareView

**Files:**
- Create: `MemoGalaxy/Views/DiaryShareView.swift`

- [ ] **Step 1: Write DiaryShareView.swift**

```swift
import SwiftUI

struct DiaryShareView: View {
    let entry: EmotionEntry
    let fontSize: CGFloat
    private let themeColor: Color

    init(entry: EmotionEntry, fontSize: CGFloat) {
        self.entry = entry
        self.fontSize = fontSize
        self.themeColor = entry.themeColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Emoji 大号居中
            HStack {
                Spacer()
                Text(entry.emotion)
                    .font(.system(size: 60, weight: .bold))
                Spacer()
            }
            .padding(.top, 30)

            // 标题和日期
            HStack {
                Text(entry.title)
                    .font(.system(.title, design: .rounded))
                    .bold()
                Spacer()
                Text(entry.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)

            // 正文
            Text(entry.content)
                .font(.system(size: fontSize))
                .padding(.horizontal, 20)

            // 缩略图（最多4张）
            let imageDataArray = entry.sortedImageData
            if !imageDataArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(imageDataArray.prefix(4).indices, id: \.self) { index in
                            if let uiImage = UIImage(data: imageDataArray[index]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .clipped()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer()

            // 水印
            HStack {
                Spacer()
                Text("MemoGalaxy")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .padding(20)
        .frame(width: 400, height: 500)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor, themeColor.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
```

- [ ] **Step 2: Verify build compiles**

Run: `xcodebuild -scheme MemoGalaxy -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGN_IDENTITY="Apple Development: jmr_eric@outlook.com (S5J5N36TBL)" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add MemoGalaxy/Views/DiaryShareView.swift
git commit -m "feat: add DiaryShareView for rendering share image"
```

---

## Task 2: Add share functionality to DetailView

**Files:**
- Modify: `MemoGalaxy/Views/DetailView.swift`

- [ ] **Step 1: Add shareImage function to DetailView**

Add this function inside DetailView struct:

```swift
private func shareDiary() {
    let shareView = DiaryShareView(entry: entry, fontSize: fontSize)
    let renderer = ImageRenderer(content: shareView)
    renderer.scale = UIScreen.main.scale
    guard let image = renderer.uiImage else { return }

    let activityVC = UIActivityViewController(
        activityItems: [image],
        applicationActivities: nil
    )

    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first,
       let rootVC = window.rootViewController {
        rootVC.present(activityVC, animated: true)
    }
}
```

- [ ] **Step 2: Add share button to toolbar**

Modify the toolbar in DetailView:

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        HStack(spacing: 16) {
            Button {
                shareDiary()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }

            Button {
                showingEditSheet = true
            } label: {
                Image(systemName: "pencil")
            }
        }
    }
}
```

- [ ] **Step 3: Verify build compiles**

Run: `xcodebuild -scheme MemoGalaxy -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGN_IDENTITY="Apple Development: jmr_eric@outlook.com (S5J5N36TBL)" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add MemoGalaxy/Views/DetailView.swift
git commit -m "feat: add share button to DetailView"
```

---

## Self-Review Checklist

- [ ] Spec coverage: 所有布局细节都已实现（emoji、标题、日期、正文、缩略图、水印）
- [ ] No placeholders: 所有步骤都有完整代码
- [ ] Type consistency: DiaryShareView 使用正确的 entry.themeColor, fontSize 参数

---

## Execution Options

**Plan complete and saved to `docs/superpowers/plans/2026-05-04-share-diary.md`**

Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
