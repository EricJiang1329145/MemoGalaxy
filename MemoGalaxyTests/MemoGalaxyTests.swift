import Testing
import SwiftUI
import SwiftData
import Foundation
import UIKit
@testable import MemoGalaxy

@MainActor
struct MemoGalaxyTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: EmotionEntry.self, configurations: config)
        context = container.mainContext
    }

    // MARK: - EmotionEntry CRUD

    @Test func createEntry() {
        let entry = EmotionEntry(
            title: "测试日记",
            content: "这是一条测试内容",
            emotion: "😊"
        )
        context.insert(entry)
        try? context.save()

        let fetchDescriptor = FetchDescriptor<EmotionEntry>()
        let entries = (try? context.fetch(fetchDescriptor)) ?? []
        #expect(entries.count == 1)
        #expect(entries.first?.title == "测试日记")
        #expect(entries.first?.emotion == "😊")
    }

    @Test func deleteEntry() {
        let entry = EmotionEntry(title: "待删除", content: "内容", emotion: "😢")
        context.insert(entry)
        try? context.save()

        context.delete(entry)
        try? context.save()

        let fetchDescriptor = FetchDescriptor<EmotionEntry>()
        let entries = (try? context.fetch(fetchDescriptor)) ?? []
        #expect(entries.isEmpty)
    }

    @Test func updateEntry() {
        let entry = EmotionEntry(title: "原始标题", content: "原始内容", emotion: "😌")
        context.insert(entry)
        try? context.save()

        entry.title = "修改后标题"
        entry.content = "修改后内容"
        entry.emotion = "🎉"
        try? context.save()

        let fetchDescriptor = FetchDescriptor<EmotionEntry>()
        let entries = (try? context.fetch(fetchDescriptor)) ?? []
        #expect(entries.first?.title == "修改后标题")
        #expect(entries.first?.emotion == "🎉")
    }

    // MARK: - Comment associations

    @Test func addCommentToEntry() {
        let entry = EmotionEntry(title: "带评论日记", content: "正文", emotion: "🤔")
        context.insert(entry)

        let comment = DiaryComment(content: "这是一条评论")
        entry.comments.append(comment)
        try? context.save()

        #expect(entry.comments.count == 1)
        #expect(entry.comments.first?.content == "这是一条评论")
    }

    @Test func cascadeDeleteComments() {
        let entry = EmotionEntry(title: "测试级联删除", content: "内容", emotion: "😊")
        let comment = DiaryComment(content: "评论内容")
        entry.comments.append(comment)
        context.insert(entry)
        try? context.save()

        context.delete(entry)
        try? context.save()

        let fetchDescriptor = FetchDescriptor<DiaryComment>()
        let comments = (try? context.fetch(fetchDescriptor)) ?? []
        #expect(comments.isEmpty)
    }

    // MARK: - StoredImage associations

    @Test func storedImageSorting() {
        guard let imageData1 = "image1".data(using: .utf8),
              let imageData2 = "image2".data(using: .utf8) else {
            #expect(Bool(false))
            return
        }

        let entry = EmotionEntry(
            title: "图片测试",
            content: "多图",
            emotion: "🥰",
            imageDataArray: [imageData1, imageData2]
        )
        context.insert(entry)
        try? context.save()

        #expect(entry.storedImages.count == 2)
        let sorted = entry.sortedImageData
        #expect(sorted.count == 2)
        #expect(sorted[0] == imageData1)
        #expect(sorted[1] == imageData2)
    }

    // MARK: - Custom color and opacity

    @Test func customColorPersistence() {
        let entry = EmotionEntry(
            title: "颜色测试",
            content: "内容",
            emotion: "😊",
            customColor: "#FF6600",
            customOpacity: 0.5
        )
        context.insert(entry)
        try? context.save()

        let fetchDescriptor = FetchDescriptor<EmotionEntry>()
        let entries = (try? context.fetch(fetchDescriptor)) ?? []
        #expect(entries.first?.customColor == "#FF6600")
        #expect(entries.first?.customOpacity == 0.5)
    }

    @Test func defaultOpacity() {
        let entry = EmotionEntry(title: "默认透明度", content: "内容", emotion: "😌")
        #expect(entry.customOpacity == 0.8)
    }

    // MARK: - ImageCache

    @Test func imageCacheThumbnail() {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
        }
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            #expect(Bool(false))
            return
        }

        let thumbnail = ImageCache.shared.thumbnail(for: data, size: size)
        #expect(thumbnail != nil)
        #expect(thumbnail!.size.width <= size.width)
        #expect(thumbnail!.size.height <= size.height)

        // Second call returns cached result
        let cached = ImageCache.shared.thumbnail(for: data, size: size)
        #expect(cached != nil)
    }

    // MARK: - Theme color

    @Test func themeColorFromEmoji() {
        let entry = EmotionEntry(title: "开心", content: "测试", emotion: "😊")
        // 😊 maps to .yellow in emojiToColorMap
        #expect(entry.themeColor != Color.gray)
    }

    @Test func themeColorFromCustom() {
        let entry = EmotionEntry(
            title: "自定义色",
            content: "测试",
            emotion: "😊",
            customColor: "#FF0000"
        )
        #expect(entry.themeColor != Color.gray)
    }
}
