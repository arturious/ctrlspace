import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var updatedAt: Date
}

@MainActor
final class NoteStore: ObservableObject {
    @Published private(set) var notes: [Note] = []

    private let storageKey = "ki.notes"
    private let legacyStorageKeys = ["ctrlspace.notes", "NotesSpotlight.notes"]

    init() {
        let defaults = UserDefaults.standard
        let currentDomainLegacyData = legacyStorageKeys.lazy.compactMap {
            defaults.data(forKey: $0)
        }.first
        let oldBundleDomain = defaults.persistentDomain(
            forName: AppSettings.legacyBundleIdentifier
        )
        let oldBundleLegacyData = legacyStorageKeys.lazy.compactMap {
            oldBundleDomain?[$0] as? Data
        }.first

        guard
            let data = defaults.data(forKey: storageKey)
                ?? currentDomainLegacyData
                ?? oldBundleLegacyData,
            let decoded = try? JSONDecoder().decode([Note].self, from: data)
        else {
            return
        }
        notes = decoded
        if defaults.data(forKey: storageKey) == nil {
            defaults.set(data, forKey: storageKey)
        }
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

    func updateTitle(_ title: String, for id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        notes[index].title = cleanTitle.isEmpty ? "Untitled" : cleanTitle
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
