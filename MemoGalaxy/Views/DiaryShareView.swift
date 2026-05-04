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
