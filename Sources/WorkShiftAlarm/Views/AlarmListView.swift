import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Query(sort: \AlarmInstance.dateTime) private var alarms: [AlarmInstance]

    var body: some View {
        NavigationStack {
            List {
                ForEach(alarms) { alarm in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(alarm.label)
                                .font(.headline)
                            Text("\(alarm.shiftName) \u00b7 \(alarm.dateTime.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: alarm.enabled ? "alarm" : "alarm.slash")
                            .foregroundStyle(alarm.enabled ? .blue : .secondary)
                    }
                }
            }
            .navigationTitle("闹钟列表")
        }
    }
}
