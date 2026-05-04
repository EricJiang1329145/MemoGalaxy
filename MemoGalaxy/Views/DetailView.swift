import SwiftUI
import SwiftData

struct DetailView: View {
    let entry: EmotionEntry
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appLocale) private var locale: Locale
    private let themeColor: Color
    @State private var newComment = ""
    @State private var previewImage: UIImage?
    @State private var currentCarouselIndex = 0
    @State private var showSendSuccess = false
    @State private var showingEditSheet = false

    @AppStorage("fontSize") private var fontSize = 16.0
    @AppStorage("isMultiImageLayout") private var isMultiImageLayout = true
    @AppStorage("isImageBeforeText") private var isImageBeforeText = true

    init(entry: EmotionEntry) {
        self.entry = entry
        self.themeColor = entry.themeColor
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    themeColor.opacity(0.1)
                        .ignoresSafeArea(.all)

                    VStack(alignment: .leading, spacing: 20) {
                        headerSection

                        if isImageBeforeText {
                            imageSection
                            contentSection
                        } else {
                            contentSection
                            imageSection
                        }

                        commentSection
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground).opacity(0.5))
                )
                .padding(.horizontal)
                .navigationTitle(entry.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .background(themeColor.opacity(0.1))
            .padding(.top, 40)
        }
        .sheet(isPresented: $showingEditSheet) {
            AddEntryView(editEntry: entry)
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            Text(entry.emotion)
                .font(.system(size: 60, weight: .bold))
                .padding(10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeColor,
                            themeColor.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(entry.customOpacity)
                )
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(entry.title)
                    .font(.system(.title, design: .rounded))
                    .bold()
                    .padding(.bottom, 4)

                Text(DateFormatter.chineseDateTime.string(from: entry.timestamp))
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
        .padding(.bottom)
    }

    @ViewBuilder
    private func thumbnailImage(from data: Data) -> some View {
        if let image = ImageCache.shared.thumbnail(for: data, size: CGSize(width: 300, height: 300)) {
            Image(uiImage: image)
                .resizable()
                .cornerRadius(12)
                .onTapGesture { previewImage = UIImage(data: data) }
        }
    }

    private var imageSection: some View {
        Group {
            let imageDataArray = entry.sortedImageData
            if !imageDataArray.isEmpty {
                if isMultiImageLayout && imageDataArray.count >= 3 {
                    TabView(selection: $currentCarouselIndex) {
                        ForEach(imageDataArray.indices, id: \.self) { index in
                            thumbnailImage(from: imageDataArray[index])
                                .scaledToFit()
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 250)
                } else {
                    let columns: [GridItem] = imageDataArray.count == 1
                        ? [GridItem(.flexible())]
                        : [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(imageDataArray.indices, id: \.self) { index in
                            thumbnailImage(from: imageDataArray[index])
                                .scaledToFill()
                                .frame(height: imageDataArray.count == 1 ? 250 : 150)
                                .clipped()
                        }
                    }
                }
            }
        }
    }

    private var contentSection: some View {
        Text(entry.content)
            .font(.system(size: fontSize))
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.7))
                    .shadow(color: .primary.opacity(0.1), radius: 6, x: 0, y: 2)
            )
            .padding(10)
    }

    private var commentSection: some View {
        VStack(alignment: .leading) {
            Text(l("评论"))
                .font(.headline)
                .padding(.top)

            HStack {
                TextField(l("写下你的评论..."), text: $newComment)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        Image(systemName: "text.bubble")
                            .foregroundColor(.gray)
                            .padding(.trailing, 8),
                        alignment: .trailing
                    )

                Button {
                    guard !newComment.isEmpty else { return }
                    let comment = DiaryComment(content: newComment)
                    entry.comments.append(comment)

                    withAnimation(.easeInOut(duration: 0.3)) {
                        newComment = ""
                        showSendSuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showSendSuccess = false
                        }
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .symbolEffect(.bounce, value: newComment.isEmpty)
                }
                .disabled(newComment.isEmpty)
            }

            ForEach(entry.comments) { comment in
                VStack(alignment: .leading) {
                    Text(comment.content)
                        .font(.system(size: fontSize * 0.85))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(DateFormatter.chineseDateTime.string(from: comment.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                        .shadow(color: .primary.opacity(0.1), radius: 3, x: 0, y: 2)
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            if showSendSuccess {
                Text(l("评论已发送"))
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .padding()
    }

    private func l(_ key: String) -> String {
        key.localized(locale: locale)
    }
}

#Preview {
    let entry = EmotionEntry(
        title: "测试日记",
        content: "这是一条测试日记内容。",
        emotion: "😊",
        timestamp: Date()
    )
    DetailView(entry: entry)
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}