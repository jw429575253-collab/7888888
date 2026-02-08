import Foundation
import SwiftData

final class SchedulePlanner {
    private let modelContext: ModelContext
    private let alarmService = AlarmKitService()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func applyMonthPlans(drafts: [DayPlanDraft], shifts: [ShiftType]) {
        guard let sample = drafts.first else { return }
        let calendar = Calendar.current
        let month = calendar.component(.month, from: sample.date)
        let year = calendar.component(.year, from: sample.date)

        let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        let existingPlans = fetchDayPlans(from: monthStart, to: monthEnd)
        existingPlans.forEach(modelContext.delete)

        let existingAlarms = fetchAlarmInstances(from: monthStart, to: monthEnd)
        existingAlarms.forEach { alarm in
            alarmService.delete(alarm: alarm)
            modelContext.delete(alarm)
        }

        for draft in drafts {
            let dayPlan = DayPlan(date: draft.date, source: "OCR", shiftName: draft.shiftName)
            modelContext.insert(dayPlan)

            guard let shift = shifts.first(where: { $0.name == draft.shiftName }) else { continue }
            if shift.name == "休" {
                continue
            }

            let instances = buildAlarms(for: shift, on: draft.date)
            instances.forEach { instance in
                modelContext.insert(instance)
                alarmService.schedule(alarm: instance)
            }
        }
    }

    private func buildAlarms(for shift: ShiftType, on date: Date) -> [AlarmInstance] {
        var instances: [AlarmInstance] = []
        let calendar = Calendar.current
        guard let start = dateWithTime(date: date, time: shift.startTime) else { return [] }
        var end = dateWithTime(date: date, time: shift.endTime) ?? start
        if end <= start {
            end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        }

        for template in shift.alarmTemplates where template.enabled {
            let base = template.anchor == .start ? start : end
            let dateTime = calendar.date(byAdding: .minute, value: template.offsetMinutes, to: base) ?? base
            let alarm = AlarmInstance(dateTime: dateTime, label: template.label, enabled: true, alarmKitId: UUID().uuidString, shiftName: shift.name)
            instances.append(alarm)
        }
        return instances
    }

    private func dateWithTime(date: Date, time: String) -> Date? {
        let parts = time.split(separator: ":")
        guard parts.count == 2 else { return nil }
        let hour = Int(parts[0]) ?? 0
        let minute = Int(parts[1]) ?? 0
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        return calendar.date(from: comps)
    }

    private func fetchDayPlans(from start: Date, to end: Date) -> [DayPlan] {
        let predicate = #Predicate<DayPlan> { $0.date >= start && $0.date < end }
        return (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func fetchAlarmInstances(from start: Date, to end: Date) -> [AlarmInstance] {
        let predicate = #Predicate<AlarmInstance> { $0.dateTime >= start && $0.dateTime < end }
        return (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }
}
