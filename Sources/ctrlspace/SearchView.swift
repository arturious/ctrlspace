import AppKit
import Carbon
import SwiftUI

struct SearchView: View {
    @ObservedObject var noteStore: NoteStore
    let openNote: (UUID) -> Void
    let setPanelHeight: (CGFloat) -> Void

    @State private var query = ""
    @State private var isCreating = false
    @State private var isExpanded = false
    @State private var selectedNoteID: UUID?
    @State private var editingTitleNoteID: UUID?
    @State private var deleteKeyMonitor: Any?
    @FocusState private var isFocused: Bool

    var body: some View {
        panelContent
            .contentShape(Rectangle())
            .onAppear {
                isFocused = true
                installDeleteKeyMonitor()
            }
            .onDisappear {
                removeDeleteKeyMonitor()
            }
            .onChange(of: query) {
                updateResultsForQuery()
            }
            .onKeyPress(.tab) {
                resetSearchPanel()
                isCreating.toggle()
                return .handled
            }
            .onKeyPress(.downArrow) {
                guard !isCreating else {
                    return .ignored
                }
                moveSelectionDown()
                return .handled
            }
            .onKeyPress(.upArrow) {
                guard isExpanded else {
                    return .ignored
                }
                moveSelectionUp()
                return .handled
            }
            .onKeyPress(.escape) {
                handleEscape()
            }
    }

    private var panelContent: some View {
        VStack(spacing: 0) {
            searchBar

            if isExpanded {
                Divider()
                    .overlay(Color.white.opacity(0.08))
                    .padding(.horizontal, Layout.panelHorizontalPadding)

                NotesListView(
                    notes: visibleNotes,
                    selectedNoteID: selectedNoteID,
                    selectNote: { selectedNoteID = $0 },
                    openNote: openSelectedNote,
                    deleteNote: deleteSelectedNote
                )

                Divider()
                    .overlay(Color.white.opacity(0.08))
                    .padding(.horizontal, Layout.panelHorizontalPadding)

                NavigationHintRow()
            }
        }
        .frame(width: Layout.panelWidth, height: currentPanelHeight, alignment: .top)
        .background {
            panelBackground
        }
    }

    private var searchBar: some View {
        HStack(spacing: Layout.controlSpacing) {
            FunctionKeyCap(
                systemName: isCreating ? "square.and.pencil" : "magnifyingglass"
            )

            TextField(
                "",
                text: $query,
                prompt: Text(searchPrompt)
                    .foregroundStyle(.white.opacity(0.38))
            )
            .textFieldStyle(.plain)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.white.opacity(0.94))
            .focused($isFocused)
            .onSubmit(submit)

            Spacer(minLength: Layout.controlSpacing)

            trailingActions
        }
        .padding(.horizontal, Layout.panelHorizontalPadding)
        .frame(height: Layout.panelHeight)
    }

    @ViewBuilder
    private var trailingActions: some View {
        if editingTitleNoteID != nil {
            HStack(spacing: 7) {
                HStack(spacing: 8) {
                    SearchActionText("Save")

                    HStack(spacing: 4) {
                        ReturnKeyCap()

                        SearchActionText(",")
                    }
                }

                HStack(spacing: 8) {
                    SearchActionText("Cancel")

                    EscapeKeyCap()
                }
            }
            .transition(.opacity)
        } else if query.isEmpty && !isCreating {
            HStack(spacing: 8) {
                Text("Create note")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.34))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                TabKeyCap()
            }
            .transition(.opacity)
        } else if isCreating {
            HStack(spacing: 14) {
                HStack(spacing: 8) {
                    Text("Search for notes")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.34))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    TabKeyCap()
                }

                HStack(spacing: 8) {
                    Text("Create")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.34))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    ReturnKeyCap()
                }
            }
            .transition(.opacity)
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: Layout.panelCornerRadius, style: .continuous)
            .fill(.clear)
            .background {
                VisualEffectView()
            }
            .clipShape(RoundedRectangle(cornerRadius: Layout.panelCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Layout.panelCornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.56))
            }
            .overlay {
                RoundedRectangle(cornerRadius: Layout.panelCornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.75)
            }
    }

    private var visibleNotes: [Note] {
        if editingTitleNoteID != nil {
            return noteStore.notes
        }

        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else {
            return noteStore.notes
        }
        return noteStore.notes.filter {
            $0.title.localizedCaseInsensitiveContains(cleanQuery)
        }
    }

    private var searchPrompt: String {
        if editingTitleNoteID != nil {
            return "Edit note title"
        }
        return isCreating ? "Create a note" : "Search for notes"
    }

    private var currentPanelHeight: CGFloat {
        guard isExpanded else {
            return Layout.panelHeight
        }

        let visibleRowCount = max(1, min(visibleNotes.count, Layout.maximumVisibleResults))
        let rowSpacing = CGFloat(max(0, visibleRowCount - 1)) * 4
        return Layout.panelHeight
            + 1
            + Layout.resultsVerticalPadding
            + CGFloat(visibleRowCount) * Layout.resultRowHeight
            + rowSpacing
            + 1
            + Layout.navigationHintRowHeight
    }

    private func installDeleteKeyMonitor() {
        deleteKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if
                event.keyCode == UInt16(kVK_ANSI_L),
                event.modifierFlags.contains(.control),
                !isCreating
            {
                startEditingSelectedTitle()
                return nil
            }

            guard
                event.keyCode == UInt16(kVK_Delete),
                event.modifierFlags.contains(.command),
                isExpanded,
                selectedNoteID != nil
            else {
                return event
            }

            if let selectedNoteID {
                deleteSelectedNote(selectedNoteID)
            }
            return nil
        }
    }

    private func removeDeleteKeyMonitor() {
        if let deleteKeyMonitor {
            NSEvent.removeMonitor(deleteKeyMonitor)
            self.deleteKeyMonitor = nil
        }
    }

    private func updateResultsForQuery() {
        guard !isCreating, editingTitleNoteID == nil else {
            return
        }

        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else {
            collapseResults()
            return
        }

        if !isExpanded {
            expandResults()
            return
        }

        selectedNoteID = visibleNotes.first?.id
        setPanelHeight(currentPanelHeight)
    }

    private func handleEscape() -> KeyPress.Result {
        if editingTitleNoteID != nil {
            cancelTitleEditing()
            return .handled
        }

        if isCreating {
            withAnimation(.easeOut(duration: 0.16)) {
                isCreating = false
                query = ""
            }
            return .handled
        }

        if isExpanded {
            collapseResults()
            return .handled
        }

        NSApp.keyWindow?.orderOut(nil)
        return .handled
    }

    private func submit() {
        if let editingTitleNoteID {
            noteStore.updateTitle(query, for: editingTitleNoteID)
            self.editingTitleNoteID = nil
            selectedNoteID = editingTitleNoteID
            query = ""
            setPanelHeight(currentPanelHeight)
        } else if isCreating {
            let noteID = noteStore.createNote(title: query)
            query = ""
            isCreating = false
            openNote(noteID)
        } else if let selectedNoteID {
            openSelectedNote(selectedNoteID)
        } else if let firstNote = visibleNotes.first {
            openSelectedNote(firstNote.id)
        }
    }

    private func expandResults() {
        selectedNoteID = visibleNotes.first?.id
        isExpanded = true
        setPanelHeight(currentPanelHeight)
    }

    private func collapseResults() {
        selectedNoteID = nil
        isExpanded = false
        setPanelHeight(Layout.panelHeight)
    }

    private func resetSearchPanel() {
        selectedNoteID = nil
        editingTitleNoteID = nil
        isExpanded = false
        query = ""
        setPanelHeight(Layout.panelHeight)
    }

    private func moveSelectionDown() {
        guard isExpanded else {
            expandResults()
            return
        }
        guard !visibleNotes.isEmpty else {
            return
        }

        guard
            let selectedNoteID,
            let currentIndex = visibleNotes.firstIndex(where: { $0.id == selectedNoteID })
        else {
            self.selectedNoteID = visibleNotes.first?.id
            return
        }

        let nextIndex = min(currentIndex + 1, visibleNotes.count - 1)
        self.selectedNoteID = visibleNotes[nextIndex].id
    }

    private func moveSelectionUp() {
        guard !visibleNotes.isEmpty else {
            return
        }

        guard
            let selectedNoteID,
            let currentIndex = visibleNotes.firstIndex(where: { $0.id == selectedNoteID })
        else {
            self.selectedNoteID = visibleNotes.first?.id
            return
        }

        let previousIndex = max(currentIndex - 1, 0)
        self.selectedNoteID = visibleNotes[previousIndex].id
    }

    private func openSelectedNote(_ noteID: UUID) {
        collapseResults()
        query = ""
        editingTitleNoteID = nil
        openNote(noteID)
    }

    private func deleteSelectedNote(_ noteID: UUID) {
        noteStore.deleteNote(withID: noteID)
        if editingTitleNoteID == noteID {
            editingTitleNoteID = nil
            query = ""
        }
        selectedNoteID = visibleNotes.first?.id
        setPanelHeight(currentPanelHeight)
    }

    private func startEditingSelectedTitle() {
        if !isExpanded {
            expandResults()
        }

        guard let noteID = selectedNoteID ?? visibleNotes.first?.id else {
            return
        }
        guard let note = noteStore.note(withID: noteID) else {
            return
        }

        selectedNoteID = noteID
        editingTitleNoteID = noteID
        query = note.title
        isFocused = true
        setPanelHeight(currentPanelHeight)
    }

    private func cancelTitleEditing() {
        editingTitleNoteID = nil
        query = ""
        setPanelHeight(currentPanelHeight)
    }
}

private struct SearchActionText: View {
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
