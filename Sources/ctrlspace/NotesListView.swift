import SwiftUI

struct NotesListView: View {
    let notes: [Note]
    let selectedNoteID: UUID?
    let selectNote: (UUID) -> Void
    let openNote: (UUID) -> Void
    let deleteNote: (UUID) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    if notes.isEmpty {
                        emptyState
                    } else {
                        ForEach(notes) { note in
                            noteRow(note)
                                .id(note.id)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .scrollIndicators(notes.count > Layout.maximumVisibleResults ? .automatic : .hidden)
            .onChange(of: selectedNoteID) {
                guard let selectedNoteID else {
                    return
                }
                proxy.scrollTo(selectedNoteID, anchor: .center)
            }
        }
    }

    private var emptyState: some View {
        Text("No notes yet")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.3))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(
                .leading,
                Layout.panelHorizontalPadding + Layout.leadingControlWidth + Layout.controlSpacing
            )
            .padding(.top, 18)
    }

    private func noteRow(_ note: Note) -> some View {
        HStack(spacing: Layout.controlSpacing) {
            Image(systemName: "note.text")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(note.id == selectedNoteID ? 0.7 : 0.32))
                .frame(width: Layout.leadingControlWidth, height: Layout.leadingControlWidth)

            noteText(note)

            Spacer(minLength: Layout.controlSpacing)

            rowActions(for: note)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    note.id == selectedNoteID
                        ? Color.white.opacity(0.09)
                        : Color.clear
                )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openNote(note.id)
        }
        .onHover { isHovering in
            if isHovering {
                selectNote(note.id)
            }
        }
    }

    private func noteText(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(note.id == selectedNoteID ? 0.92 : 0.7))
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)

            if !note.body.isEmpty {
                Text(note.body.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func rowActions(for note: Note) -> some View {
        HStack(spacing: 7) {
            Button {
                deleteNote(note.id)
            } label: {
                HStack(spacing: 7) {
                    Text("Delete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.red.opacity(0.5))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    CommandKeyCap()
                    DeleteKeyCap()
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 7) {
                Text("Open")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.36))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                ReturnKeyCap()
            }
        }
        .frame(width: 382, alignment: .trailing)
        .opacity(note.id == selectedNoteID ? 1 : 0)
    }
}
