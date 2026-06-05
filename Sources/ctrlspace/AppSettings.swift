import Foundation

enum AppSettings {
    static let menuBarIconHiddenKey = "ctrlspace.menuBarIconHidden"
    static let menuBarIconVisibilityDidChange = Notification.Name(
        "ctrlspace.menuBarIconVisibilityDidChange"
    )
}
