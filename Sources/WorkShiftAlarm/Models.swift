import Foundation
import SwiftData

@Model
final class AppSettings {
    var defaultWakeOffsetMinutes: Int
    var defaultStartOffsetMinutes: Int
    var defaultEndOffsetMinutes: Int

    init(defaultWakeOffsetMinutes: Int, defaultStartOffsetMinutes: Int, defaultEndOffsetMinutes: Int) {
        self.defaultWakeOffsetMinutes = defaultWakeOffsetMinutes
        self.defaultStartOffsetMinutes = defaultStartOffsetMinutes
        self.defaultEndOffsetMinutes = defaultEndOffsetMinutes
    }
}

@Model
final class ShiftType {
    var id: UUID
    var name: String
    var startTime: String
    var endTime: String
    @Attribute(.transformable) var keywordRules: [String]
    @Relationship(deleteRule: .cascade) var alarmTemplates: [AlarmTemplate]

    init(name: String, startTime: String, endTime: String, keywordRules: [String]) {
        self.id = UUID()
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.keywordRules = keywordRules
        self.alarmTemplates = []
    }
}

@Model
final class AlarmTemplate {
    var id: UUID
    var label: String
    var anchorRaw: String
    var offsetMinutes: Int
    var enabled: Bool

    init(label: String, anchor: AlarmAnchor, offsetMinutes: Int, enabled: Bool) {
        self.id = UUID()
        self.label = label
        self.anchorRaw = anchor.rawValue
        self.offsetMinutes = offsetMinutes
        self.enabled = enabled
    }

    var anchor: AlarmAnchor {
        get { AlarmAnchor(rawValue: anchorRaw) ?? .start }
        set { anchorRaw = newValue.rawValue }
    }

    func copy() -> AlarmTemplate {
        AlarmTemplate(label: label, anchor: anchor, offsetMinutes: offsetMinutes, enabled: enabled)
    }
}

@Model
final class DayPlan {
    var id: UUID
    var date: Date
    var source: String
    var shiftName: String

    init(date: Date, source: String, shiftName: String) {
        self.id = UUID()
        self.date = date
        self.source = source
        self.shiftName = shiftName
    }
}

@Model
final class AlarmInstance {
    var id: UUID
    var dateTime: Date
    var label: String
    var enabled: Bool
    var alarmKitId: String
    var shiftName: String

    init(dateTime: Date, label: String, enabled: Bool, alarmKitId: String, shiftName: String) {
        self.id = UUID()
        self.dateTime = dateTime
        self.label = label
        self.enabled = enabled
        self.alarmKitId = alarmKitId
        self.shiftName = shiftName
    }
}

enum AlarmAnchor: String, Codable, CaseIterable {
    case start
    case end
}
