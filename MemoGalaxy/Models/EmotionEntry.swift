import SwiftUI
import SwiftData

let emojiToColorMap: [String: Color] = [
    "😊": .yellow,
    "😢": .blue,
    "😠": .red,
    "🥰": .pink,
    "😌": .mint,
    "😲": .orange,
    "😴": .gray,
    "🎉": .purple,
    "🤔": .indigo,
    "🙏": .green
]

let presetColors: [(String, String)] = [
    ("法拉利红", "#FF2800"),
    ("迈凯轮橙", "#FF8700"),
    ("梅赛德斯银", "#00D2BE"),
    ("红牛蓝", "#0600EF"),
    ("EVA初号机紫", "#5F3D7A"),
    ("EVA零号机黄", "#FFD700"),
    ("EVA二号机红", "#C41E3A"),
    ("NERV标志橙", "#FF6600"),
    ("初音绿", "#39C5BB"),
    ("克莱因蓝", "#002FA7"),
    ("蒂芙尼蓝", "#81D8D0"),
    ("长春花蓝", "#6667AB"),
    ("马尔斯绿", "#008C8C"),
    ("勃艮第红", "#900020"),
    ("波尔多红", "#5D1F1C"),
    ("爱马仕橙", "#E8590C"),
    ("红色", "#FF0000"),
    ("绿色", "#00FF00"),
    ("蓝色", "#0000FF")
]

let commonEmojis = ["😊", "😢", "😠", "🥰", "😌", "😲", "😴", "🎉", "🤔", "🙏"]

@Model
final class EmotionEntry {
    var id: UUID
    var title: String
    var content: String
    var emotion: String
    var timestamp: Date
    var customColor: String?
    var customOpacity: Double = 0.8
    @Relationship(deleteRule: .cascade) var comments: [DiaryComment] = []
    @Relationship(deleteRule: .cascade) var storedImages: [StoredImage] = []

    var themeColor: Color {
        if let hex = customColor {
            return Color(hex: hex)
        }
        return emojiToColorMap[emotion] ?? .gray
    }

    var sortedImageData: [Data] {
        storedImages.sorted { $0.sortIndex < $1.sortIndex }.map(\.data)
    }

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        emotion: String,
        timestamp: Date = Date(),
        imageDataArray: [Data]? = nil,
        customColor: String? = nil,
        customOpacity: Double = 0.8
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.emotion = emotion
        self.timestamp = timestamp
        self.customColor = customColor
        self.customOpacity = customOpacity
        if let imageDataArray {
            self.storedImages = imageDataArray.enumerated().map { index, data in
                StoredImage(data: data, sortIndex: index)
            }
        }
    }
}
