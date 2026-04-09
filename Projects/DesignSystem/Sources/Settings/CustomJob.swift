import Foundation

// ═══════════════════════════════════════════════════════
// MARK: - Custom Job (사용자 정의 직업)
// ═══════════════════════════════════════════════════════

public struct CustomJob: Codable, Identifiable, Equatable {
    public var id: String = UUID().uuidString
    public var name: String
    public var icon: String = "person.fill"
    public var promptTemplate: String = ""
    public var statusMarker: String = ""

    public init(id: String = UUID().uuidString, name: String, icon: String = "person.fill", promptTemplate: String = "", statusMarker: String = "") {
        self.id = id; self.name = name; self.icon = icon; self.promptTemplate = promptTemplate; self.statusMarker = statusMarker
    }
}
