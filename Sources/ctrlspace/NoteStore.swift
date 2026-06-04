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
