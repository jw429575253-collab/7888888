import Foundation

struct DayPlanDraft {
    var date: Date
    var rawText: String
    var shiftName: String
}

final class ShiftMappingService {
    private let shifts: [ShiftType]

    init(shifts: [ShiftType]) {
        self.shifts = shifts
    }

    func mapToDrafts(from result: OCRMonthResult) -> [DayPlanDraft] {
        var drafts: [DayPlanDraft] = []
        let calendar = Calendar.current
        for entry in result.entries {
            var comps = DateComponents()
            comps.year = result.year
            comps.month = result.month
            comps.day = entry.dateNumber
            guard let date = calendar.date(from: comps) else { continue }
            let shiftName = matchShiftName(for: entry.rawText)
            drafts.append(DayPlanDraft(date: date, rawText: entry.rawText, shiftName: shiftName))
        }
        return drafts
    }

    private func matchShiftName(for text: String) -> String {
        let trimmed = text.replacingOccurrences(of: " ", with: "")
        for shift in shifts {
            for rule in shift.keywordRules {
                if trimmed.contains(rule) {
                    return shift.name
                }
            }
        }
        return shifts.first?.name ?? ""
    }
}
