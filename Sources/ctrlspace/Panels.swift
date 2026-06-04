import AppKit

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
