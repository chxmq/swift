import SwiftUI

/// Alarm list — clean Apple Clock-inspired layout
struct AlarmListView: View {
    var store: AlarmStore
    var onTestAlarm: (Alarm) -> Void

    @State private var showingAddSheet = false
    @State private var editingAlarm: Alarm?
    @State private var alarmToDelete: Alarm?
    @State private var showDeleteConfirm = false
    @State private var currentTime = Date()

    let clockTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if store.alarms.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Next alarm header
                            nextAlarmHeader
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)

                            // Alarm rows
                            VStack(spacing: 1) {
                                ForEach(store.alarms) { alarm in
                                    alarmRow(alarm)
                                }
                            }
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.shared.lightTap()
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.primaryAccent)
                    }
                    .accessibilityLabel("Add new alarm")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AlarmEditView(
                    alarm: Alarm(
                        hour: 7, minute: 0,
                        challengeType: 0, intensity: 1,
                        isEnabled: true, label: "",
                        repeatDays: []
                    ),
                    isNew: true
                ) { newAlarm in
                    store.add(newAlarm)
                }
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmEditView(alarm: alarm, isNew: false) { updated in
                    store.update(updated)
                }
            }
            .alert("Delete Alarm?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let alarm = alarmToDelete,
                       let idx = store.alarms.firstIndex(where: { $0.id == alarm.id }) {
                        store.delete(at: IndexSet(integer: idx))
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This alarm will be permanently removed.")
            }
            .onReceive(clockTimer) { _ in
                currentTime = Date()
            }
        }
    }

    // MARK: - Next Alarm Header

    private var nextAlarmHeader: some View {
        let nextAlarm = store.alarms
            .filter(\.isEnabled)
            .compactMap { alarm -> (Alarm, Date)? in
                guard let next = alarm.nextFireDate else { return nil }
                return (alarm, next)
            }
            .sorted { $0.1 < $1.1 }
            .first

        return Group {
            if let (alarm, fireDate) = nextAlarm {
                VStack(spacing: 8) {
                    Text(alarm.timeString)
                        .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    HStack(spacing: 6) {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 11))
                        Text(timeUntilString(fireDate))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Theme.primaryAccent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Alarm Row (Apple Clock style)

    private func alarmRow(_ alarm: Alarm) -> some View {
        Button {
            editingAlarm = alarm
        } label: {
            HStack {
                // Left side: time + details
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.timeString)
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundStyle(alarm.isEnabled ? .white : Theme.textTertiary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 6) {
                        if !alarm.label.isEmpty {
                            Text(alarm.label)
                                .lineLimit(1)
                        }

                        if !alarm.label.isEmpty && !alarm.repeatDays.isEmpty {
                            Text("·")
                        }

                        if !alarm.repeatDays.isEmpty {
                            Text(alarm.repeatDescription)
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(alarm.isEnabled ? Theme.textSecondary : Theme.textTertiary)
                }

                Spacer()

                // Right side: test button + toggle
                HStack(spacing: 12) {
                    Button {
                        onTestAlarm(alarm)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.primaryAccent)
                            .frame(width: 26, height: 26)
                            .background(Theme.primaryAccent.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Test alarm")

                    Toggle("", isOn: Binding(
                        get: { alarm.isEnabled },
                        set: { _ in
                            HapticsManager.shared.lightTap()
                            store.toggle(alarm)
                        }
                    ))
                    .tint(Theme.primaryAccent)
                    .labelsHidden()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.surface)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                alarmToDelete = alarm
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alarm.label.isEmpty ? "Alarm" : alarm.label), \(alarm.timeString), \(alarm.repeatDescription), \(alarm.isEnabled ? "enabled" : "disabled")")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "alarm")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(Theme.textTertiary)

            Text("No Alarms")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)

            Text("Tap + to add one")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textTertiary)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func timeUntilString(_ date: Date) -> String {
        let interval = date.timeIntervalSince(currentTime)
        if interval < 0 { return "now" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }
}
