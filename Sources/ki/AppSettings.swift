import Foundation

enum AppSettings {
    static let legacyBundleIdentifier = "dev.k.ctrlspace"
    static let menuBarIconHiddenKey = "ki.menuBarIconHidden"
    static let legacyMenuBarIconHiddenKey = "ctrlspace.menuBarIconHidden"
    static let menuBarIconVisibilityDidChange = Notification.Name(
        "ki.menuBarIconVisibilityDidChange"
    )

    static func migrateLegacyValues() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: menuBarIconHiddenKey) == nil else {
            return
        }

        if defaults.object(forKey: legacyMenuBarIconHiddenKey) != nil {
            defaults.set(
                defaults.bool(forKey: legacyMenuBarIconHiddenKey),
                forKey: menuBarIconHiddenKey
            )
            return
        }

        guard
            let legacyDomain = defaults.persistentDomain(forName: legacyBundleIdentifier),
            let legacyValue = legacyDomain[legacyMenuBarIconHiddenKey] as? Bool
        else {
            return
        }
        defaults.set(legacyValue, forKey: menuBarIconHiddenKey)
    }
}
