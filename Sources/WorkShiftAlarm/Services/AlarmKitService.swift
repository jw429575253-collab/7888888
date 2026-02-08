import Foundation
import SwiftUI

final class AlarmKitService {
    func schedule(alarm: AlarmInstance) {
        if #available(iOS 26.0, *), AlarmKitBridge.isAvailable {
            AlarmKitBridge.shared.schedule(alarm: alarm)
        }
    }

    func delete(alarm: AlarmInstance) {
        if #available(iOS 26.0, *), AlarmKitBridge.isAvailable {
            AlarmKitBridge.shared.delete(alarm: alarm)
        }
    }
}

#if canImport(AlarmKit)
import AlarmKit

@available(iOS 26.0, *)
final class AlarmKitBridge {
    static let shared = AlarmKitBridge()
    static let isAvailable = true

    private init() {}

    func schedule(alarm: AlarmInstance) {
        Task {
            await requestAuthorizationIfNeeded()
            let id = UUID(uuidString: alarm.alarmKitId) ?? UUID()

            let stopButton = AlarmButton(
                text: "停止",
                textColor: .white,
                systemImageName: "stop.circle")
            let repeatButton = AlarmButton(
                text: "稍后",
                textColor: .white,
                systemImageName: "repeat.circle")

            let alertPresentation = AlarmPresentation.Alert(
                title: alarm.label,
                stopButton: stopButton,
                secondaryButton: repeatButton,
                secondaryButtonBehavior: .countdown)

            let attributes = AlarmAttributes<ShiftAlarmMetadata>(
                presentation: AlarmPresentation(alert: alertPresentation),
                metadata: ShiftAlarmMetadata(label: alarm.label, shift: alarm.shiftName),
                tintColor: .blue)

            let duration = Alarm.CountdownDuration(preAlert: 0, postAlert: 5 * 60)
            let schedule = Alarm.Schedule.fixed(alarm.dateTime)

            let configuration = AlarmManager.AlarmConfiguration(
                countdownDuration: duration,
                schedule: schedule,
                attributes: attributes)

            try? await AlarmManager.shared.schedule(id: id, configuration: configuration)
        }
    }

    func delete(alarm: AlarmInstance) {
        Task {
            guard let id = UUID(uuidString: alarm.alarmKitId) else { return }
            try? await AlarmManager.shared.cancel(id: id)
        }
    }

    private func requestAuthorizationIfNeeded() async {
        switch AlarmManager.shared.authorizationState {
        case .notDetermined:
            _ = try? await AlarmManager.shared.requestAuthorization()
        default:
            break
        }
    }
}

@available(iOS 26.0, *)
struct ShiftAlarmMetadata: AlarmMetadata, Codable, Hashable {
    let label: String
    let shift: String
}
#else
final class AlarmKitBridge {
    static let shared = AlarmKitBridge()
    static let isAvailable = false

    func schedule(alarm: AlarmInstance) {}
    func delete(alarm: AlarmInstance) {}
}
#endif
