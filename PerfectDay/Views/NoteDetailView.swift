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
                            CollapsibleSection(isExpanded: $isExpanded[index], title: "Text", content: {
                                TextEditor(text: Binding(
                                    get: { text },
                                    set: { newText in
                                        noteContents[index].text = newText
                                    }
                                ))
                                .frame(minHeight: 100)
                                .padding()
                            })
                        } else if let image = content.image {
                            CollapsibleSection(isExpanded: $isExpanded[index], title: "Images", content: {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding()
                            })
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
        .onDisappear {
            saveNote()
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
        .onAppear {
            isExpanded = Array(repeating: false, count: noteContents.count)
        }
    }

    private func addText() {
        let newContent = NoteContent(text: "New Text")
        noteContents.append(newContent)
        isExpanded.append(false)
    }

    private func addImage(image: UIImage) {
        let newContent = NoteContent(image: image)
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
}

struct CollapsibleSection<Content: View>: View {
    @Binding var isExpanded: Bool
    let title: String
    let content: Content

    init(isExpanded: Binding<Bool>, title: String, @ViewBuilder content: () -> Content) {
        self._isExpanded = isExpanded
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.headline)
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

struct NoteContent: Identifiable {
    let id = UUID()
    var text: String?
    var image: UIImage?

    init(text: String) {
        self.text = text
    }

    init(image: UIImage) {
        self.image = image
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
