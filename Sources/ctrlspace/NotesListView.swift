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
                        ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                            noteRow(note, number: index + 1)
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
        HStack(spacing: Layout.controlSpacing) {
            LetterKeyCap("?")

            Text("No notes yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
                .lineLimit(1)

            Spacer(minLength: Layout.controlSpacing)
        }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 9)
    }

    private func noteRow(_ note: Note, number: Int) -> some View {
        HStack(spacing: Layout.controlSpacing) {
            NumberKeyCap(number: number, isSelected: note.id == selectedNoteID)

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
            HStack(spacing: 7) {
                Text("Delete")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.red.opacity(0.5))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                HStack(spacing: 7) {
                    CommandKeyCap()

                    Text("+")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.36))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    DeleteKeyCap()
                }

                HStack(spacing: 4) {
                    Text(",")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.36))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

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

struct SettingsItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let kind: SettingsItemKind
}

enum SettingsItemKind: Equatable {
    case quit
}

struct SettingsListView: View {
    let items: [SettingsItem]
    let submitItem: (SettingsItem) -> Void

    var body: some View {
        VStack(spacing: 4) {
            if items.isEmpty {
                emptySettingsRow
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
                    settingsRow(item)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var emptySettingsRow: some View {
        HStack(spacing: Layout.controlSpacing) {
            LetterKeyCap("?")

            Text("No settings found")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
                .lineLimit(1)

            Spacer(minLength: Layout.controlSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
    }

    private func settingsRow(_ item: SettingsItem) -> some View {
        HStack(spacing: Layout.controlSpacing) {
            HashKeyCap()

            Text(item.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(settingsTitleColor(for: item))
                .lineLimit(1)

            Spacer(minLength: Layout.controlSpacing)

            HStack(spacing: 7) {
                Text("Submit")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.36))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                ReturnKeyCap()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.09))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            submitItem(item)
        }
    }

    private func settingsTitleColor(for item: SettingsItem) -> Color {
        switch item.kind {
        case .quit:
            return Color.red.opacity(0.5)
        }
    }
}

struct NavigationHintRow: View {
    let isShowingSettings: Bool
    let hasResults: Bool

    var body: some View {
        HStack(spacing: 14) {
            if hasResults {
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        ArrowKeyCap(direction: .up)
                        HintActionText(",")
                        ArrowKeyCap(direction: .down)
                    }

                    HintActionText("for navigation,")
                }

                if !isShowingSettings {
                    HStack(spacing: 8) {
                        HintActionText("Edit")

                        HStack(spacing: 4) {
                            ControlKeyCap()

                            HintActionText("+")

                            LetterKeyCap("L")
                        }
                    }
                }

                Spacer()
            } else {
                Spacer()
            }

            if !isShowingSettings {
                HStack(spacing: 8) {
                    HintActionText("Settings")

                    HStack(spacing: 4) {
                        ControlKeyCap()

                        HintActionText("+")

                        SlashKeyCap()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .frame(height: Layout.navigationHintRowHeight)
    }
}

struct HintActionText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.34))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}
