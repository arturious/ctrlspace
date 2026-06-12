import Foundation

enum AppSettings {
    static let menuBarIconHiddenKey = "ki.menuBarIconHidden"
    static let menuBarIconVisibilityDidChange = Notification.Name(
        "ki.menuBarIconVisibilityDidChange"
    )
}
