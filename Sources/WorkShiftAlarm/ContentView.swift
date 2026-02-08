import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    var body: some View {
        TabView {
            ShiftListView()
                .tabItem {
                    Label("班次", systemImage: "list.bullet")
                }

            ScheduleImportView()
                .tabItem {
                    Label("排班", systemImage: "calendar")
                }

            AlarmListView()
                .tabItem {
                    Label("闹钟", systemImage: "alarm")
                }
        }
        .task {
            await seedIfNeeded()
        }
    }

    private func seedIfNeeded() async {
        let hasSettings = !settings.isEmpty
        if hasSettings { return }

        let defaults = AppSettings(
            defaultWakeOffsetMinutes: -90,
            defaultStartOffsetMinutes: -10,
            defaultEndOffsetMinutes: 10
        )
        modelContext.insert(defaults)

        let a = ShiftType(name: "A", startTime: "09:00", endTime: "18:00", keywordRules: ["A班", "A"])
        let c = ShiftType(name: "C", startTime: "08:00", endTime: "20:00", keywordRules: ["C班", "C"])
        let d = ShiftType(name: "D", startTime: "20:00", endTime: "08:00", keywordRules: ["D班", "D"])
        let rest = ShiftType(name: "休", startTime: "00:00", endTime: "00:00", keywordRules: ["公休", "节假日", "休"])

        [a, c, d, rest].forEach { modelContext.insert($0) }

        let templates = defaultTemplates()
        templates.forEach { template in
            a.alarmTemplates.append(template.copy())
            c.alarmTemplates.append(template.copy())
            d.alarmTemplates.append(template.copy())
        }
    }

    private func defaultTemplates() -> [AlarmTemplate] {
        [
            AlarmTemplate(label: "起床", anchor: .start, offsetMinutes: -90, enabled: true),
            AlarmTemplate(label: "上班卡", anchor: .start, offsetMinutes: -10, enabled: true),
            AlarmTemplate(label: "下班卡", anchor: .end, offsetMinutes: 10, enabled: true)
        ]
    }
}

#Preview {
    ContentView()
}
