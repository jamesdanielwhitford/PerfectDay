import SwiftUI
import CoreData

struct JournalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var selectedNote: Note?
    @State private var isCreatingNewNote = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.timestamp, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<Note>

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText)
                List {
                    ForEach(notes.filter { searchText.isEmpty ? true : $0.title?.contains(searchText) ?? false }) { note in
                        NavigationLink(destination: NoteDetailView(note: note)) {
                            NoteRow(note: note)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(note: note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                bookmark(note: note)
                            } label: {
                                Label("Bookmark", systemImage: "bookmark")
                            }.tint(.yellow)
                        }
                    }
                }
                .navigationTitle("Journal")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: addNote) {
                            Label("Add Note", systemImage: "plus")
                        }
                    }
                }
                .navigationDestination(isPresented: $isCreatingNewNote) {
                    if let note = selectedNote {
                        NoteDetailView(note: note)
                    }
                }
            }
        }
    }

    private func addNote() {
        withAnimation {
            let newNote = Note(context: viewContext)
            newNote.timestamp = Date()
            newNote.title = "New Note"
            selectedNote = newNote
            isCreatingNewNote = true

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func delete(note: Note) {
        withAnimation {
            viewContext.delete(note)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func bookmark(note: Note) {
        withAnimation {
            note.isBookmarked.toggle()
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct NoteRow: View {
    @ObservedObject var note: Note

    var body: some View {
        VStack(alignment: .leading) {
            Text(note.title ?? "Untitled")
                .font(.headline)
            Text(note.timestamp!, formatter: itemFormatter)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search Notes"
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
