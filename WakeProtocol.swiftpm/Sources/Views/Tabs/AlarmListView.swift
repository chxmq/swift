import SwiftUI

/// Alarm list — clean Apple Clock-inspired layout
struct AlarmListView: View {
    var store: AlarmStore

    @State private var showingAddSheet = false
    @State private var editingAlarm: Alarm?
    @State private var alarmToDelete: Alarm?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if store.alarms.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // Fixed top: date + next alarm (live-updating via TimelineView)
                        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                                dateAndClockHeader(currentTime: context.date)
                                    .padding(.horizontal, Theme.innerPadding)
                                nextAlarmHeader(currentTime: context.date)
                                    .padding(.horizontal, Theme.innerPadding)
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                            .background(Theme.background)
                        }

                        // Scrollable: only the alarm list (no pull-down bounce)
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("YOUR ALARMS")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.horizontal, 4)

                                VStack(spacing: 1) {
                                    ForEach(Array(store.alarms.enumerated()), id: \.element.id) { index, alarm in
                                        alarmRow(alarm)
                                            .transition(.opacity.combined(with: .move(edge: .leading)))
                                    }
                                }
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                        .stroke(Theme.primaryAccent.opacity(0.12), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, Theme.innerPadding)
                            .padding(.bottom, 100)
                        }
                        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                    }
                }
            }
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                AlarmEditView(
                    alarm: alarm,
                    isNew: false,
                    onSave: { updated in store.update(updated) },
                    onDelete: {
                        if let idx = store.alarms.firstIndex(where: { $0.id == alarm.id }) {
                            store.delete(at: IndexSet(integer: idx))
                        }
                    }
                )
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
        }
    }

    // MARK: - Date + Live Clock

    private func dateAndClockHeader(currentTime: Date) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(todayDateString(from: currentTime))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text(liveTimeString(from: currentTime))
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func liveTimeString(from date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func todayDateString(from date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    // MARK: - Next Alarm Header

    @ViewBuilder
    private func nextAlarmHeader(currentTime: Date) -> some View {
        let nextAlarm = store.alarms
            .filter(\.isEnabled)
            .compactMap { alarm -> (Alarm, Date)? in
                guard let next = alarm.nextFireDate else { return nil }
                return (alarm, next)
            }
            .sorted { $0.1 < $1.1 }
            .first

        if let (alarm, fireDate) = nextAlarm {
            NextAlarmHeaderView(alarm: alarm, fireDate: fireDate, currentTime: currentTime)
        } else if !store.alarms.isEmpty {
            Text("No upcoming alarm")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                        .fill(Theme.surface)
                )
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
                        .foregroundStyle(alarm.isEnabled ? Theme.textPrimary : Theme.textTertiary)
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
                    .font(.system(size: 14))
                    .foregroundStyle(alarm.isEnabled ? Theme.textSecondary : Theme.textTertiary)
                }

                Spacer()

                // Right side: toggle
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
            .padding(.horizontal, Theme.innerPadding)
            .padding(.vertical, 14)
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
        VStack(spacing: Theme.sectionSpacing) {
            Spacer()

            Image(systemName: "alarm.waves.left.and.right")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.primaryAccent.opacity(0.8))
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 8) {
                Text("No alarms yet")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text("Tap the + button above to add your first alarm and start your wake protocol.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

}

// MARK: - Next Alarm Header (animated)

private struct NextAlarmHeaderView: View {
    let alarm: Alarm
    let fireDate: Date
    let currentTime: Date

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

    var body: some View {
        VStack(spacing: 0) {
            // "Up next" label (centered)
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.waveform.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.primaryAccent)
                Text("UP NEXT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.primaryAccent)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
            .padding(.bottom, 4)

            // Time + details (centered)
            VStack(spacing: 14) {
                Text(alarm.timeString)
                    .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                VStack(spacing: 6) {
                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                    }
                    if !alarm.repeatDays.isEmpty {
                        Text(alarm.repeatDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .medium))
                        Text(timeUntilString(fireDate))
                            .font(.system(size: 13, weight: .semibold))
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(Theme.primaryAccent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, Theme.innerPadding)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                .fill(Theme.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                        .stroke(Theme.primaryAccent.opacity(0.25), lineWidth: 1.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.primaryAccent.opacity(0.06),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .allowsHitTesting(false)
                )
        )
    }
}
