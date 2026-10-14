public struct License: Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let kind: String
    public let note: String?
    public let text: String

    public init(id: String, name: String, kind: String, note: String?, text: String) {
        self.id = id
        self.name = name
        self.kind = kind
        self.note = note
        self.text = text
    }
}
