import AppKit
import Carbon
import SwiftUI

private let panelWidth: CGFloat = 800
private let panelHeight: CGFloat = 64
private let panelCornerRadius: CGFloat = 18
private let panelTopOffset: CGFloat = 190
private let resultRowHeight: CGFloat = 70
private let resultsVerticalPadding: CGFloat = 16
private let maximumVisibleResults = 6
private let panelHorizontalPadding: CGFloat = 16
private let leadingControlWidth: CGFloat = 52
private let controlSpacing: CGFloat = 10

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    private let noteStore = NoteStore()
    private var panel: SearchPanel?
    private var editorPanels: [UUID: NSPanel] = [:]
    private var hotKey: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?
    private var statusItem: NSStatusItem?
    private var hotKeyRegistrationStatus: OSStatus = noErr

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let panel = SearchWindowPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        let hostingView = NSHostingView(
            rootView: SearchView(
                noteStore: noteStore,
                openNote: { [weak self] noteID in
                    self?.openEditor(for: noteID)
                },
                setPanelHeight: { [weak self] height in
                    self?.setSearchPanelHeight(height)
                }
            )
        )
        hostingView.focusRingType = .none
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = panelCornerRadius
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true
        panel.contentView = hostingView
        positionSearchPanel(panel, height: panelHeight)
        self.panel = panel

        configureMainMenu()
        registerHotKey()
        configureStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
        }
        if let hotKeyHandler {
            RemoveEventHandler(hotKeyHandler)
        }
    }

    private func registerHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else {
                    return noErr
                }

                let delegate = Unmanaged<AppDelegate>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                Task { @MainActor in
                    delegate.togglePanel()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &hotKeyHandler
        )

        let hotKeyID = EventHotKeyID(
            signature: OSType(0x4E_4F_54_45),
            id: 1
        )

        hotKeyRegistrationStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
    }

    @MainActor
    private func configureMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Quit ctrlspace",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(
            withTitle: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        editMenuItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }

    @MainActor
    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = makeStatusBarIcon(text: "⌃", muted: true)

        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: "Open ctrlspace",
            action: #selector(togglePanelFromMenu),
            keyEquivalent: " "
        )
        toggleItem.keyEquivalentModifierMask = [.control]
        toggleItem.target = self
        menu.addItem(toggleItem)

        if hotKeyRegistrationStatus != noErr {
            let conflictItem = NSMenuItem(
                title: "Control-Space is used by macOS",
                action: nil,
                keyEquivalent: ""
            )
            conflictItem.isEnabled = false
            menu.addItem(conflictItem)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit ctrlspace",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        self.statusItem = statusItem
    }

    private func makeStatusBarIcon(text: String, muted: Bool = false) -> NSImage {
        let fontSize: CGFloat = 11.5
        let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black.withAlphaComponent(muted ? 0.58 : 1.0)
        ]
        let textSize = text.size(withAttributes: attributes)
        let keyWidth: CGFloat = 22
        let spacing: CGFloat = 4
        let size = NSSize(
            width: ceil(textSize.width) + spacing + keyWidth,
            height: 16
        )

        let image = NSImage(size: size, flipped: false) { bounds in
            let keyBounds = NSRect(
                x: bounds.maxX - keyWidth,
                y: bounds.minY,
                width: keyWidth,
                height: bounds.height
            )
            let border = NSBezierPath(
                roundedRect: keyBounds.insetBy(dx: 0.5, dy: 0.5),
                xRadius: 3,
                yRadius: 3
            )
            border.lineWidth = 1
            NSColor.black.withAlphaComponent(muted ? 0.58 : 1.0).setStroke()
            border.stroke()

            let textRect = NSRect(
                x: 0,
                y: floor((bounds.height - textSize.height) / 2) - 1,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "ctrlspace"
        return image
    }

    @objc @MainActor
    private func togglePanelFromMenu() {
        togglePanel()
    }

    @objc @MainActor
    private func quitApplication() {
        NSApp.terminate(nil)
    }

    @MainActor
    private func togglePanel() {
        guard let panel else {
            return
        }

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            positionSearchPanel(panel, height: panel.frame.height)
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @MainActor
    private func setSearchPanelHeight(_ newHeight: CGFloat) {
        guard let panel else {
            return
        }

        var frame = panel.frame
        let top = frame.maxY
        frame.size.height = newHeight
        frame.origin.y = top - newHeight
        panel.setFrame(frame, display: true, animate: false)
    }

    @MainActor
    private func positionSearchPanel(_ panel: NSPanel, height: CGFloat) {
        guard let screen = NSScreen.main else {
            panel.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.midX - panelWidth / 2,
            y: visibleFrame.maxY - panelTopOffset - height
        )
        panel.setFrame(
            NSRect(origin: origin, size: NSSize(width: panelWidth, height: height)),
            display: true,
            animate: false
        )
    }

    @MainActor
    private func openEditor(for noteID: UUID) {
        panel?.orderOut(nil)

        if let existingPanel = editorPanels[noteID] {
            existingPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let editorPanel = NoteEditorPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        editorPanel.contentView = NSHostingView(
            rootView: NoteEditorView(noteStore: noteStore, noteID: noteID)
        )
        editorPanel.positionNearTopRight()
        editorPanel.makeKeyAndOrderFront(nil)
        editorPanels[noteID] = editorPanel
        NSApp.activate(ignoringOtherApps: true)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class SearchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
    }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }
}

final class SearchWindowPanel: SearchPanel {
    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }
}

final class NoteEditorPanel: SearchPanel {
    func positionNearTopRight() {
        guard let screen = NSScreen.main else {
            center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.maxX - frame.width - 40,
            y: visibleFrame.maxY - frame.height - 40
        )
        setFrameOrigin(origin)
    }
}

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var updatedAt: Date
}

@MainActor
final class NoteStore: ObservableObject {
    @Published private(set) var notes: [Note] = []

    private let storageKey = "ctrlspace.notes"
    private let legacyStorageKey = "NotesSpotlight.notes"

    init() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey)
                ?? UserDefaults.standard.data(forKey: legacyStorageKey),
            let decoded = try? JSONDecoder().decode([Note].self, from: data)
        else {
            return
        }
        notes = decoded
    }

    func createNote(title: String) -> UUID {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = Note(
            id: UUID(),
            title: cleanTitle.isEmpty ? "Untitled" : cleanTitle,
            body: "",
            updatedAt: Date()
        )
        notes.insert(note, at: 0)
        save()
        return note.id
    }

    func note(withID id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    func updateBody(_ body: String, for id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            return
        }
        notes[index].body = body
        notes[index].updatedAt = Date()
        notes.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func deleteNote(withID id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(notes) else {
            return
        }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

struct SearchView: View {
    @ObservedObject var noteStore: NoteStore
    let openNote: (UUID) -> Void
    let setPanelHeight: (CGFloat) -> Void

    @State private var query = ""
    @State private var isCreating = false
    @State private var isExpanded = false
    @State private var selectedNoteID: UUID?
    @State private var deleteKeyMonitor: Any?
    @FocusState private var isFocused: Bool

    var body: some View {
        panelContent
        .contentShape(Rectangle())
        .onAppear {
            isFocused = true
            deleteKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
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
        .onDisappear {
            if let deleteKeyMonitor {
                NSEvent.removeMonitor(deleteKeyMonitor)
                self.deleteKeyMonitor = nil
            }
        }
        .onChange(of: query) {
            guard !isCreating else {
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
    }

    private var panelContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: controlSpacing) {
                FunctionKeyCap(
                    systemName: isCreating ? "square.and.pencil" : "magnifyingglass"
                )

                TextField(
                    "",
                    text: $query,
                    prompt: Text(isCreating ? "Create a note" : "Search for notes")
                        .foregroundStyle(.white.opacity(0.38))
                )
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.94))
                .focused($isFocused)
                .onSubmit(submit)

                Spacer(minLength: controlSpacing)

                if query.isEmpty && !isCreating {
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
            .padding(.horizontal, panelHorizontalPadding)
            .frame(height: panelHeight)

            if isExpanded {
                Divider()
                    .overlay(Color.white.opacity(0.08))
                    .padding(.horizontal, panelHorizontalPadding)

                NotesListView(
                    notes: visibleNotes,
                    selectedNoteID: selectedNoteID,
                    selectNote: { selectedNoteID = $0 },
                    openNote: openSelectedNote,
                    deleteNote: deleteSelectedNote
                )
            }
        }
        .frame(width: panelWidth, height: currentPanelHeight, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                .fill(.clear)
                .background {
                    VisualEffectView()
                }
                .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.56))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.75)
                }
        }
    }

    private var visibleNotes: [Note] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else {
            return noteStore.notes
        }
        return noteStore.notes.filter {
            $0.title.localizedCaseInsensitiveContains(cleanQuery)
        }
    }

    private var currentPanelHeight: CGFloat {
        guard isExpanded else {
            return panelHeight
        }

        let visibleRowCount = max(1, min(visibleNotes.count, maximumVisibleResults))
        let rowSpacing = CGFloat(max(0, visibleRowCount - 1)) * 4
        return panelHeight
            + 1
            + resultsVerticalPadding
            + CGFloat(visibleRowCount) * resultRowHeight
            + rowSpacing
    }

    private func submit() {
        if isCreating {
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
        setPanelHeight(panelHeight)
    }

    private func resetSearchPanel() {
        selectedNoteID = nil
        isExpanded = false
        query = ""
        setPanelHeight(panelHeight)
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
        openNote(noteID)
    }

    private func deleteSelectedNote(_ noteID: UUID) {
        noteStore.deleteNote(withID: noteID)
        selectedNoteID = visibleNotes.first?.id
        setPanelHeight(currentPanelHeight)
    }
}

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
                    Text("No notes yet")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, panelHorizontalPadding + leadingControlWidth + controlSpacing)
                        .padding(.top, 18)
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
            .scrollIndicators(notes.count > maximumVisibleResults ? .automatic : .hidden)
            .onChange(of: selectedNoteID) {
                guard let selectedNoteID else {
                    return
                }
                proxy.scrollTo(selectedNoteID, anchor: .center)
            }
        }
    }

    private func noteRow(_ note: Note) -> some View {
        HStack(spacing: controlSpacing) {
            Image(systemName: "note.text")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(note.id == selectedNoteID ? 0.7 : 0.32))
                .frame(width: leadingControlWidth, height: leadingControlWidth)

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

            Spacer(minLength: controlSpacing)

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
}

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
        .frame(width: 420, height: 560)
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

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct TabKeyCap: View {
    var body: some View {
        MacBookKeyCap(title: "tab")
    }
}

struct ReturnKeyCap: View {
    var body: some View {
        MacBookKeyCap(title: "return")
    }
}

struct DeleteKeyCap: View {
    var body: some View {
        MacBookKeyCap(title: "delete")
    }
}

struct CommandKeyCap: View {
    var body: some View {
        MacBookModifierKeyCap(symbol: "⌘", title: "command")
    }
}

struct MacBookModifierKeyCap: View {
    let symbol: String
    let title: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(symbol)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 7)

            Spacer(minLength: 0)

            Text(title)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.leading, 10)
        .padding(.trailing, 3)
        .padding(.top, 7)
        .padding(.bottom, 8)
        .frame(width: 69, height: 52)
        .background {
            KeyboardKeyBackground()
        }
    }
}

struct FunctionKeyCap: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.58))
            .frame(width: 52, height: 52)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.18, blue: 0.19),
                                Color(red: 0.11, green: 0.11, blue: 0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.78), lineWidth: 1.5)
                    }
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(red: 0.06, green: 0.06, blue: 0.065))
                            .frame(height: 3)
                            .padding(.horizontal, 1.5)
                            .padding(.bottom, 1.5)
                    }
                    .shadow(color: .black.opacity(0.48), radius: 1.5, y: 2)
            }
    }
}

struct MacBookKeyCap: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .frame(width: 82, height: 52)
        .background {
            KeyboardKeyBackground()
        }
    }
}

struct KeyboardKeyBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.18, blue: 0.19),
                        Color(red: 0.11, green: 0.11, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.78), lineWidth: 1.5)
            }
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(red: 0.06, green: 0.06, blue: 0.065))
                    .frame(height: 3)
                    .padding(.horizontal, 1.5)
                    .padding(.bottom, 1.5)
            }
            .shadow(color: .black.opacity(0.48), radius: 1.5, y: 2)
    }
}

struct ShortcutKeyCap: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.52))
            .frame(width: 26, height: 26)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.white.opacity(0.035))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    }
            }
    }
}
