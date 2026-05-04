import SwiftUI

struct EntryRow: View {
    let entry: EmotionEntry
    @AppStorage("fontSize") private var fontSize = 16.0
    @State private var isTapped = false

    var body: some View {
        HStack(alignment: .top) {
            Text(entry.emotion)
                .font(.system(size: 40, design: .default))
                .padding(5)
                .background(
                    entry.themeColor.opacity(entry.customOpacity)
                )
                .clipShape(Circle())
                .scaleEffect(isTapped ? 1.1 : 1)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isTapped)
                .onTapGesture {
                    isTapped.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isTapped = false
                    }
                }

            VStack(alignment: .leading) {
                Text(DateFormatter.chineseDate.string(from: entry.timestamp))
                    .font(.system(size: fontSize * 0.75))
                    .foregroundStyle(.secondary)

                Text(entry.title)
                    .font(.system(size: fontSize))
                    .lineLimit(2)
                    .padding(.top, 2)
            }

            if let firstData = entry.sortedImageData.first,
               let thumbnail = ImageCache.shared.thumbnail(for: firstData, size: CGSize(width: 60, height: 60)) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
            }
        }
    }
}
