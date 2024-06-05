import SwiftUI
import CoreData
import PhotosUI

struct NoteDetailView: View {
    @ObservedObject var note: Note
    @Environment(\.managedObjectContext) private var viewContext
    @State private var noteContents: [NoteContent] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var isExpanded: [Bool] = []

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(noteContents.indices, id: \.self) { index in
                        let content = noteContents[index]
                        if let text = content.text {
                            CollapsibleSection(
                                isExpanded: $isExpanded[index],
                                title: "",
                                content: {
                                    TextEditor(text: Binding(
                                        get: { text },
                                        set: { newText in
                                            noteContents[index].text = newText
                                        }
                                    ))
                                    .frame(minHeight: 100)
                                    .padding()
                                },
                                preview: {
                                    Text(previewText(text))
                                        .padding()
                                }
                            )
                        } else if let images = content.images {
                            CollapsibleSection(
                                isExpanded: $isExpanded[index],
                                title: "",
                                content: {
                                    ImageGrid(images: images)
                                },
                                preview: {
                                    ImagePreviewGrid(images: images)
                                }
                            )
                        }
                    }
                }
            }
            .padding()

            HStack {
                Button(action: addText) {
                    Image(systemName: "textformat")
                        .padding()
                }
                Button(action: { showingImagePicker = true }) {
                    Image(systemName: "photo")
                        .padding()
                }
                Button(action: { showingCamera = true }) {
                    Image(systemName: "camera")
                        .padding()
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if noteContents.isEmpty {
                addText()
            }
            isExpanded = Array(repeating: false, count: noteContents.count)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, onImagePicked: { image in
                addImage(image: image)
            })
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $selectedImage, onImageCaptured: { image in
                addImage(image: image)
            })
        }
    }

    private func addText() {
        let newContent = NoteContent(text: "")
        noteContents.append(newContent)
        isExpanded.append(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isExpanded[noteContents.count - 1] = true
        }
    }

    private func addImage(image: UIImage) {
        let newContent = NoteContent(images: [image])
        noteContents.append(newContent)
        isExpanded.append(false)
    }

    private func saveNote() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func previewText(_ text: String) -> String {
        let previewLimit = 100
        return text.count > previewLimit ? String(text.prefix(previewLimit)) + "..." : text
    }
}

struct CollapsibleSection<Content: View, Preview: View>: View {
    @Binding var isExpanded: Bool
    let title: String
    let content: Content
    let preview: Preview

    init(isExpanded: Binding<Bool>, title: String, @ViewBuilder content: () -> Content, @ViewBuilder preview: () -> Preview) {
        self._isExpanded = isExpanded
        self.title = title
        self.content = content()
        self.preview = preview()
    }

    var body: some View {
        VStack {
            if !isExpanded {
                preview
            }
            HStack {
                Spacer()
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            .padding()

            if isExpanded {
                content
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding([.horizontal, .top])
    }
}

struct ImageGrid: View {
    let images: [UIImage]

    var body: some View {
        VStack {
            ForEach(images, id: \.self) { image in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            }
        }
    }
}

struct ImagePreviewGrid: View {
    let images: [UIImage]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
            ForEach(images.prefix(4), id: \.self) { image in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
            }
        }
        .padding()
    }
}

struct NoteContent: Identifiable {
    let id = UUID()
    var text: String?
    var images: [UIImage]?

    init(text: String) {
        self.text = text
    }

    init(images: [UIImage]) {
        self.images = images
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self.parent.onImagePicked(uiImage)
                    }
                }
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let uiImage = info[.originalImage] as? UIImage {
                self.parent.onImageCaptured(uiImage)
            }
        }
    }
}
