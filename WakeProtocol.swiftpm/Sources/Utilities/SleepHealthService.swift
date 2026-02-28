import Foundation
import HealthKit

/// Fetches sleep data from HealthKit for personalized insights
@Observable
final class SleepHealthService {
    static let shared = SleepHealthService()

    private let healthStore = HKHealthStore()
    private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined
    private(set) var sleepSamples: [SleepSample] = []
    private(set) var isLoading = false
    private(set) var lastError: String?

    struct SleepSample: Identifiable {
        let id: UUID
        let startDate: Date
        let endDate: Date
        let durationHours: Double

        var startTimeString: String {
            formatTime(startDate)
        }

        var endTimeString: String {
            formatTime(endDate)
        }

        private func formatTime(_ date: Date) -> String {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: date)
        }
    }

    private init() {}

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isAvailable else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: [sleepType])
            await MainActor.run {
                authorizationStatus = healthStore.authorizationStatus(for: sleepType)
                lastError = nil
            }
            await fetchSleepData()
        } catch {
            await MainActor.run {
                lastError = Self.friendlyHealthError(error)
            }
        }
    }

    /// User-friendly message when Health request fails (e.g. missing capability)
    private static func friendlyHealthError(_ error: Error) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("missing") || text.contains("entitlement") || text.contains("healthkit") || text.contains("capability") {
            return "Health isn’t set up for this app. In Xcode: select the app target → Signing & Capabilities → + Capability → add HealthKit, then rebuild and try again."
        }
        if text.contains("denied") || text.contains("not authorized") {
            return "Health access was denied. You can turn it on in Settings → Privacy & Security → Health → Wake Protocol."
        }
        return error.localizedDescription
    }

    func fetchSleepData() async {
        guard isAvailable else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let status = healthStore.authorizationStatus(for: sleepType)
        guard status == .sharingAuthorized else {
            await MainActor.run {
                authorizationStatus = status
            }
            return
        }

        await MainActor.run { isLoading = true }

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let store = healthStore

        let (rawSamples, queryError): ([HKCategorySample]?, Error?) = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                continuation.resume(returning: (samples as? [HKCategorySample], error))
            }
            store.execute(query)
        }

        let processed = processSamples(rawSamples ?? [])
        await MainActor.run {
            if let queryError {
                lastError = queryError.localizedDescription
            } else {
                lastError = nil
            }
            sleepSamples = processed
            isLoading = false
        }
    }

    private func processSamples(_ samples: [HKCategorySample]) -> [SleepSample] {
        var sessions: [(start: Date, end: Date)] = []

        for sample in samples.sorted(by: { $0.startDate < $1.startDate }) {
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                 HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                 HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                sessions.append((sample.startDate, sample.endDate))
            default:
                continue
            }
        }

        var merged: [(start: Date, end: Date)] = []
        for session in sessions.sorted(by: { $0.start < $1.start }) {
            if let last = merged.last, session.start.timeIntervalSince(last.end) < 3600 {
                merged[merged.count - 1] = (last.start, session.end)
            } else {
                merged.append(session)
            }
        }

        return merged.map { start, end in
            SleepSample(
                id: UUID(),
                startDate: start,
                endDate: end,
                durationHours: end.timeIntervalSince(start) / 3600
            )
        }.sorted { $0.startDate > $1.startDate }
    }

    func insights() -> [SleepInsight] {
        let samples = sleepSamples
        guard samples.count >= 2 else { return [] }

        var result: [SleepInsight] = []

        let avgDuration = samples.map(\.durationHours).reduce(0, +) / Double(samples.count)
        let hours = Int(avgDuration)
        let mins = Int((avgDuration - Double(hours)) * 60)
        result.append(SleepInsight(
            title: "Average sleep",
            value: "\(hours)h \(mins)m",
            detail: "Last \(samples.count) nights"
        ))

        let calendar = Calendar.current
        let weekdays = samples.filter { (1...5).contains(calendar.component(.weekday, from: $0.startDate) - 1) }
        let weekends = samples.filter { [0, 6].contains(calendar.component(.weekday, from: $0.startDate) - 1) }

        if !weekdays.isEmpty, !weekends.isEmpty {
            let weekdayAvg = weekdays.map(\.durationHours).reduce(0, +) / Double(weekdays.count)
            let weekendAvg = weekends.map(\.durationHours).reduce(0, +) / Double(weekends.count)
            let diff = weekendAvg - weekdayAvg
            if abs(diff) >= 0.25 {
                let mins = Int(abs(diff) * 60)
                let more = diff > 0 ? "Weekends" : "Weekdays"
                result.append(SleepInsight(
                    title: "\(more) vs the other",
                    value: "\(mins) min more sleep",
                    detail: nil
                ))
            }
        }

        let bedtimes = samples.map { calendar.component(.hour, from: $0.startDate) * 60 + calendar.component(.minute, from: $0.startDate) }
        if bedtimes.count >= 3 {
            let mean = Double(bedtimes.reduce(0, +)) / Double(bedtimes.count)
            let variance = bedtimes.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(bedtimes.count)
            let stdDev = sqrt(variance)
            let mins = Int(stdDev)
            let consistency = mins <= 30 ? "Very consistent" : (mins <= 60 ? "Moderately consistent" : "Variable")
            result.append(SleepInsight(
                title: "Bedtime consistency",
                value: consistency,
                detail: "Within ~\(mins) min window"
            ))
        }

        if let latest = samples.first {
            let h = Int(latest.durationHours)
            let m = Int((latest.durationHours - Double(h)) * 60)
            result.append(SleepInsight(
                title: "Last night",
                value: "\(h)h \(m)m",
                detail: "\(latest.startTimeString) → \(latest.endTimeString)"
            ))
        }

        return result
    }

    var hasEnoughData: Bool {
        sleepSamples.count >= 2
    }
}
