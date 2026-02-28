import Foundation

/// Single wake event — when user completed the alarm challenge
struct WakeRecord: Codable, Identifiable {
    let id: UUID
    let dismissedAt: Date
    let weekday: Int

    init(dismissedAt: Date = Date()) {
        self.id = UUID()
        self.dismissedAt = dismissedAt
        self.weekday = Calendar.current.component(.weekday, from: dismissedAt) - 1
    }
}

/// Stores wake history and computes sleep insights
@Observable
final class WakeHistoryStore {
    static let shared = WakeHistoryStore()

    private(set) var records: [WakeRecord] = []
    private let key = "wake_protocol_wake_history"
    private let maxRecords = 90

    private init() {
        load()
    }

    func recordWake(dismissedAt: Date = Date()) {
        records.append(WakeRecord(dismissedAt: dismissedAt))
        if records.count > maxRecords {
            records.removeFirst(records.count - maxRecords)
        }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WakeRecord].self, from: data)
        else { return }
        records = decoded
    }

    func insights() -> [SleepInsight] {
        let recent = recentRecords(days: 14)
        guard !recent.isEmpty else { return [] }

        var result: [SleepInsight] = []

        if let avg = averageMinutesSinceMidnight(recent) {
            result.append(SleepInsight(
                title: "Average wake time",
                value: formatTime(minutes: avg),
                detail: "Last 14 days"
            ))
        }

        let weekdayRecords = recent.filter { (1...5).contains($0.weekday) }
        let weekendRecords = recent.filter { [0, 6].contains($0.weekday) }

        if let weekdayAvg = averageMinutesSinceMidnight(weekdayRecords),
           let weekendAvg = averageMinutesSinceMidnight(weekendRecords),
           !weekdayRecords.isEmpty, !weekendRecords.isEmpty {
            let diff = weekendAvg - weekdayAvg
            if abs(diff) >= 5 {
                let later = diff > 0 ? "Weekends" : "Weekdays"
                let mins = Int(abs(diff))
                result.append(SleepInsight(
                    title: "\(later) vs the other",
                    value: "\(mins) min later",
                    detail: nil
                ))
            }
        }

        if let stdDev = wakeTimeStdDev(recent), recent.count >= 3 {
            let mins = Int(stdDev)
            let consistency = mins <= 15 ? "Very consistent" : (mins <= 30 ? "Moderately consistent" : "Variable")
            result.append(SleepInsight(
                title: "Wake consistency",
                value: consistency,
                detail: "Within ~\(mins) min window"
            ))
        }

        result.append(SleepInsight(
            title: "Alarms completed",
            value: "\(recent.count) in last 14 days",
            detail: nil
        ))

        return result
    }

    var hasEnoughData: Bool {
        recentRecords(days: 14).count >= 2
    }

    private func recentRecords(days: Int) -> [WakeRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return records.filter { $0.dismissedAt >= cutoff }
    }

    private func averageMinutesSinceMidnight(_ records: [WakeRecord]) -> Double? {
        guard !records.isEmpty else { return nil }
        let cal = Calendar.current
        let total = records.reduce(0.0) { sum, r in
            let comps = cal.dateComponents([.hour, .minute], from: r.dismissedAt)
            return sum + Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
        }
        return total / Double(records.count)
    }

    private func formatTime(minutes: Double) -> String {
        let h = Int(minutes / 60) % 24
        let m = Int(minutes.truncatingRemainder(dividingBy: 60))
        let period = h < 12 ? "AM" : "PM"
        let hour12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hour12, m, period)
    }

    private func wakeTimeStdDev(_ records: [WakeRecord]) -> Double? {
        guard records.count >= 2, let mean = averageMinutesSinceMidnight(records) else { return nil }
        let cal = Calendar.current
        let variance = records.reduce(0.0) { sum, r in
            let comps = cal.dateComponents([.hour, .minute], from: r.dismissedAt)
            let mins = Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
            return sum + pow(mins - mean, 2)
        } / Double(records.count)
        return sqrt(variance)
    }
}
