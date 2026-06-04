import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var noteStore: NoteStore
    let noteID: UUID

    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(note.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
                .lineLimit(1)
                .padding(.top, 22)
                .padding(.horizontal, 28)

            ZStack(alignment: .topLeading) {
                if note.body.isEmpty {
                    Text("Start writing...")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.34))
                        .padding(.top, 17)
                        .padding(.leading, 28)
                        .allowsHitTesting(false)
                }

                TextEditor(text: bodyBinding)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .focused($isEditorFocused)
            }
        }
        .frame(width: Layout.editorWidth, height: Layout.editorHeight)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.clear)
                .background {
                    VisualEffectView()
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.black.opacity(0.48))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.52), radius: 28, y: 14)
        }
        .onAppear {
            isEditorFocused = true
        }
    }

    private var note: Note {
        noteStore.note(withID: noteID)
            ?? Note(id: noteID, title: "Untitled", body: "", updatedAt: Date())
    }

    private var bodyBinding: Binding<String> {
        Binding(
            get: { note.body },
            set: { noteStore.updateBody($0, for: noteID) }
        )
    }
}
