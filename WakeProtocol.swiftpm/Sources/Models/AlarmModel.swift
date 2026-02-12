import SwiftUI

/// Alarm data model with UserDefaults persistence
struct Alarm: Identifiable, Codable, Equatable {
    var id = UUID()
    var hour: Int
    var minute: Int
    var challengeType: Int // 0=sequence, 1=trace, 2=color
    var intensity: Int // 0=gentle, 1=moderate, 2=intense
    var isEnabled: Bool
    var label: String
    var repeatDays: Set<Int> // 0=Sun, 1=Mon, etc. Empty = one-time
    var soundType: Int = 0 // Maps to AlarmSoundManager.SoundType

    var soundName: String {
        AlarmSoundManager.SoundType(rawValue: soundType)?.name ?? "Radar"
    }

    var timeString: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, period)
    }

    var challengeName: String {
        switch challengeType {
        case 0: return "Sequence"
        case 1: return "Trace"
        case 2: return "Color Match"
        default: return "Random"
        }
    }

    var intensityName: String {
        switch intensity {
        case 0: return "Gentle"
        case 1: return "Moderate"
        case 2: return "Intense"
        default: return "Moderate"
        }
    }

    static let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var repeatDescription: String {
        if repeatDays.isEmpty { return "One-time" }
        if repeatDays.count == 7 { return "Every day" }
        if repeatDays == Set([1,2,3,4,5]) { return "Weekdays" }
        if repeatDays == Set([0,6]) { return "Weekends" }
        return repeatDays.sorted().map { Alarm.dayNames[$0] }.joined(separator: ", ")
    }

    /// Next date this alarm will fire
    var nextFireDate: Date? {
        guard isEnabled else { return nil }
        let cal = Calendar.current
        let now = Date()

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0

        if repeatDays.isEmpty {
            // One-time: find next occurrence of this time
            guard let candidate = cal.nextDate(
                after: now,
                matching: components,
                matchingPolicy: .nextTime
            ) else { return nil }
            return candidate
        } else {
            // Repeating: find the nearest matching weekday
            var nearest: Date?
            for day in repeatDays {
                components.weekday = day + 1
                if let candidate = cal.nextDate(
                    after: now,
                    matching: components,
                    matchingPolicy: .nextTime
                ) {
                    if nearest == nil || candidate < nearest! {
                        nearest = candidate
                    }
                }
            }
            return nearest
        }
    }
}

/// Observable alarm store with UserDefaults persistence
@Observable
final class AlarmStore {
    var alarms: [Alarm] = []

    private let key = "wake_protocol_alarms"

    init() {
        load()
        if alarms.isEmpty {
            // Start with one default alarm
            alarms = [
                Alarm(
                    hour: 7,
                    minute: 0,
                    challengeType: 0,
                    intensity: 1,
                    isEnabled: true,
                    label: "Morning Wake Up",
                    repeatDays: Set([1,2,3,4,5])
                )
            ]
            save()
        }
    }

    func add(_ alarm: Alarm) {
        alarms.append(alarm)
        save()
    }

    func update(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        alarms.remove(atOffsets: offsets)
        save()
    }

    func toggle(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: key)
        }
        NotificationManager.shared.rescheduleAll(alarms)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Alarm].self, from: data)
        else { return }
        alarms = decoded
    }
}
