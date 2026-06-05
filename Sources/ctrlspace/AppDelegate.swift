import AppKit
import Carbon
import SwiftUI

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
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Layout.panelWidth,
                height: Layout.panelHeight
            ),
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
        hostingView.layer?.cornerRadius = Layout.panelCornerRadius
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true
        panel.contentView = hostingView
        positionSearchPanel(panel, height: Layout.panelHeight)
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

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = makeStatusBarIcon(text: "⌃", muted: true)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanelFromMenu)
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
        let horizontalPadding: CGFloat = 4
        let size = NSSize(
            width: max(horizontalPadding + ceil(textSize.width) + horizontalPadding, 22),
            height: 16
        )

        let image = NSImage(size: size, flipped: false) { bounds in
            let border = NSBezierPath(
                roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
                xRadius: 3,
                yRadius: 3
            )
            border.lineWidth = 1
            NSColor.black.withAlphaComponent(muted ? 0.58 : 1.0).setStroke()
            border.stroke()

            let textRect = NSRect(
                x: 3,
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

    @objc private func togglePanelFromMenu() {
        togglePanel()
    }

    @objc private func quitApplication() {
        NSApp.terminate(nil)
    }

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

    private func positionSearchPanel(_ panel: NSPanel, height: CGFloat) {
        guard let screen = NSScreen.main else {
            panel.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.midX - Layout.panelWidth / 2,
            y: visibleFrame.maxY - Layout.panelTopOffset - height
        )
        panel.setFrame(
            NSRect(origin: origin, size: NSSize(width: Layout.panelWidth, height: height)),
            display: true,
            animate: false
        )
    }

    private func openEditor(for noteID: UUID) {
        panel?.orderOut(nil)

        if let existingPanel = editorPanels[noteID] {
            existingPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let editorPanel = NoteEditorPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Layout.editorWidth,
                height: Layout.editorHeight
            ),
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
