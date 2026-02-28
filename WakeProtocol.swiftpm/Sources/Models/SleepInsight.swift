import Foundation

/// Shared insight model for both HealthKit and alarm-based sleep data
struct SleepInsight: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String?
}
