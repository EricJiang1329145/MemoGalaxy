import SwiftUI
import SwiftData
import PhotosUI
import Vision

struct AddEntryView: View {
    var editEntry: EmotionEntry? = nil
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("disableOCR") private var disableOCR = false

    @State private var title = ""
    @State private var content = ""
    @State private var selectedEmoji = "😊"
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var selectedColor: String?
    @State private var selectedOpacity: Double = 0.8
    @State private var imageCompression: Double = 0.8
    @State private var ocrText: String = ""
    @State private var showOCRAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("你的心情") {
                    TextField("输入任意emoji", text: $selectedEmoji)
                        .textFieldStyle(.roundedBorder)
                        .font(.largeTitle)
                        .onChange(of: selectedEmoji) { _, newValue in
                            if newValue.count > 1 {
                                selectedEmoji = String(newValue.prefix(1))
                            }
                        }

                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(commonEmojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.title)
                                    .padding(8)
                                    .background(.thinMaterial)
                                    .cornerRadius(8)
                                    .onTapGesture { selectedEmoji = emoji }
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                Section("选择主题颜色") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ColorPicker("自定义颜色", selection: Binding(
                                get: { Color(hex: selectedColor ?? "#FFFFFF") },
                                set: { selectedColor = $0.toHex() }
                            ))
                            .frame(width: 44, height: 44)

                            ForEach(presetColors, id: \.1) { name, hex in
                                VStack(spacing: 4) {
                                    ColorCircle(
                                        color: hex,
                                        colorName: name,
                                        isSelected: selectedColor == hex
                                    )
                                    .scaleEffect(selectedColor == hex ? 1.05 : 1)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColor)
                                    .onTapGesture {
                                        withAnimation { selectedColor = hex }
                                    }

                                    Text(name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section("图片设置") {
                    HStack {
                        Text("图片质量")
                        Slider(value: $imageCompression, in: 0.1...1, step: 0.1)
                        Text(String(format: "%.1f", imageCompression))
                    }
                    Text("1.0为无损质量，0.1为高度压缩（文件更小）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("输入日记标题", text: $title)
                            .textFieldStyle(.roundedBorder)

                        Divider()

                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("请输入正文")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            TextEditor(text: $content)
                                .frame(minHeight: 150)
                        }
                    }
                }

                Section("添加图片") {
                    PhotosPicker(
                        "选择照片",
                        selection: $photoItems,
                        matching: .images,
                        photoLibrary: .shared()
                    )
                    .onChange(of: photoItems) { _, newItems in
                        Task {
                            var loadedImages: [UIImage] = []
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    loadedImages.append(image)
                                }
                            }
                            await MainActor.run {
                                selectedImages = loadedImages
                            }
                        }
                    }

                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }

                Section("OCR识别") {
                    if !disableOCR {
                        Button("识别选中图片文字") {
                            recognizeTextFromImages()
                        }
                        .disabled(selectedImages.isEmpty)

                        if !ocrText.isEmpty {
                            TextEditor(text: $ocrText)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }

                Section("选择透明度") {
                    HStack {
                        Text("不透明度")
                        Slider(value: $selectedOpacity, in: 0...1, step: 0.1)
                        Text(String(format: "%.1f", selectedOpacity))
                    }

                    HStack {
                        Text("预览：")
                        Circle()
                            .fill(
                                selectedColor != nil
                                    ? Color(hex: selectedColor!)
                                    : (emojiToColorMap[selectedEmoji] ?? .gray)
                            )
                            .frame(width: 44, height: 44)
                            .opacity(selectedOpacity)
                    }
                }
            }
            .navigationTitle(editEntry == nil ? "新日记" : "编辑日记")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("保存") { saveEntry() }
                        .disabled(title.isEmpty || content.isEmpty)
                }
            }
            .alert("识别提示", isPresented: $showOCRAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Group {
                    if ocrText.isEmpty {
                        Text("未识别到文字")
                    } else {
                        Text("已识别到\(ocrText.count)字")
                    }
                }
            }
            .onAppear(perform: prefillIfEditing)
        }
    }

    private func prefillIfEditing() {
        guard let entry = editEntry else { return }
        title = entry.title
        content = entry.content
        selectedEmoji = entry.emotion
        selectedColor = entry.customColor
        selectedOpacity = entry.customOpacity
        let imageDataArray = entry.sortedImageData
        if !imageDataArray.isEmpty {
            selectedImages = imageDataArray.compactMap { UIImage(data: $0) }
        }
    }

    private func recognizeTextFromImages() {
        var allResults: [String] = []
        let group = DispatchGroup()
        for image in selectedImages {
            group.enter()
            guard let cgImage = image.cgImage else {
                group.leave()
                continue
            }
            let request = VNRecognizeTextRequest { request, error in
                defer { group.leave() }
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                let strings = observations.compactMap { $0.topCandidates(1).first?.string }
                if !strings.isEmpty {
                    allResults.append(strings.joined(separator: "\n"))
                }
            }
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }

        group.notify(queue: .main) {
            ocrText = allResults.joined(separator: "\n---\n")
            if !ocrText.isEmpty {
                content += "\n[识别结果]\n\(ocrText)"
            }
            showOCRAlert = true
        }
    }

    private func saveEntry() {
        let imageDataArray = selectedImages.compactMap {
            $0.jpegData(compressionQuality: imageCompression)
        }

        if let entry = editEntry {
            entry.title = title
            entry.content = content
            entry.emotion = selectedEmoji
            entry.customColor = selectedColor
            entry.customOpacity = selectedOpacity
            entry.timestamp = Date()
            if !imageDataArray.isEmpty {
                entry.storedImages = imageDataArray.enumerated().map { index, data in
                    StoredImage(data: data, sortIndex: index)
                }
            }
        } else {
            let newEntry = EmotionEntry(
                title: title,
                content: content,
                emotion: selectedEmoji,
                imageDataArray: imageDataArray.isEmpty ? nil : imageDataArray,
                customColor: selectedColor,
                customOpacity: selectedOpacity
            )
            modelContext.insert(newEntry)
        }
        dismiss()
    }
}
