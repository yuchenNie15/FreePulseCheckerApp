internal struct License: Equatable, Identifiable, Sendable {
    internal let id: String
    internal let name: String
    internal let kind: String
    internal let note: String?
    internal let text: String

    internal init(id: String, name: String, kind: String, note: String?, text: String) {
        self.id = id
        self.name = name
        self.kind = kind
        self.note = note
        self.text = text
    }
}
