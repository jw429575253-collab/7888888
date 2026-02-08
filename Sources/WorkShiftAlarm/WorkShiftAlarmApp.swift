import SwiftUI
import SwiftData

@main
struct WorkShiftAlarmApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ShiftType.self, AlarmTemplate.self, DayPlan.self, AlarmInstance.self, AppSettings.self])
    }
}
