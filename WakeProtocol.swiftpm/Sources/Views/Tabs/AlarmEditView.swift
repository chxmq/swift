import SwiftUI

/// Alarm editor — time picker, challenge type, intensity, repeat days, label
struct AlarmEditView: View {
    @State var alarm: Alarm
    let isNew: Bool
    let onSave: (Alarm) -> Void
    var onDelete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date
    @State private var showDeleteConfirm = false

    init(alarm: Alarm, isNew: Bool, onSave: @escaping (Alarm) -> Void, onDelete: (() -> Void)? = nil) {
        self._alarm = State(initialValue: alarm)
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete

        // Create a date from the alarm's hour/minute
        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute
        let date = Calendar.current.date(from: components) ?? Date()
        self._selectedDate = State(initialValue: date)
    }

    private let challengeTypes = [
        (icon: "hand.tap.fill", name: "Sequence", desc: "Tap nodes in order"),
        (icon: "scribble.variable", name: "Trace", desc: "Trace the path"),
        (icon: "paintpalette.fill", name: "Color", desc: "Match the colors")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Time picker
                        timePickerSection

                        // Label
                        labelSection

                        // Alarm sound
                        soundSection

                        // Challenge type
                        challengeSection

                        // Intensity
                        intensitySection

                        // Repeat days
                        repeatSection

                        // Delete (edit only)
                        if !isNew, onDelete != nil {
                            deleteSection
                        }
                    }
                    .padding(.horizontal, Theme.innerPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(isNew ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.primaryAccent)
                }
            }
        }
        .presentationDetents([.large])
        .alert("Delete this alarm?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
        } message: {
            Text("This alarm will be removed. You can add it again anytime.")
        }
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Button {
            HapticsManager.shared.lightTap()
            showDeleteConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                Text("Delete Alarm")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Theme.dangerAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .padding(.top, 8)
    }

    // MARK: - Time Picker

    private var timePickerSection: some View {
        VStack(spacing: 8) {
            DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 160)
                .accessibilityLabel("Select alarm time")
        }
        .padding(.vertical, 8)
        .background(Theme.surface.cornerRadius(16))
    }

    // MARK: - Label

    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("LABEL")

            TextField("Alarm name", text: $alarm.label)
                .font(.system(size: 16))
                .foregroundStyle(Theme.textPrimary)
                .padding(14)
                .background(Theme.surface)
                .cornerRadius(10)
                .accessibilityLabel("Alarm label")
        }
    }

    // MARK: - Challenge Type

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DISMISS CHALLENGE")

            HStack(spacing: 10) {
                ForEach(Array(challengeTypes.enumerated()), id: \.offset) { index, type in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            alarm.challengeType = index
                        }
                        HapticsManager.shared.lightTap()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.system(size: 22))

                            Text(type.name)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))

                            Text(type.desc)
                                .font(.system(size: 9))
                                .opacity(0.6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(
                            alarm.challengeType == index ? Theme.primaryAccent : Theme.textSecondary
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(alarm.challengeType == index
                                      ? Theme.primaryAccent.opacity(0.1)
                                      : Theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    alarm.challengeType == index
                                        ? Theme.primaryAccent.opacity(0.4)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .accessibilityLabel("\(type.name): \(type.desc)")
                    .accessibilityAddTraits(alarm.challengeType == index ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Intensity

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("INTENSITY")

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { level in
                    let labels = ["Gentle", "Moderate", "Intense"]
                    let colors: [Color] = [Theme.primaryAccent, Theme.warningAccent, Theme.dangerAccent]

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            alarm.intensity = level
                        }
                        HapticsManager.shared.lightTap()
                    } label: {
                        Text(labels[level])
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(
                                alarm.intensity == level ? colors[level] : Theme.textTertiary
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(alarm.intensity == level
                                          ? colors[level].opacity(0.1)
                                          : Theme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        alarm.intensity == level
                                            ? colors[level].opacity(0.4)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .accessibilityLabel("\(labels[level]) intensity")
                    .accessibilityAddTraits(alarm.intensity == level ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Repeat Days

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("REPEAT")

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { day in
                    let isSelected = alarm.repeatDays.contains(day)
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if isSelected {
                                alarm.repeatDays.remove(day)
                            } else {
                                alarm.repeatDays.insert(day)
                            }
                        }
                        HapticsManager.shared.lightTap()
                    } label: {
                        Text(Alarm.dayNames[day].prefix(1).uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .frame(width: 38, height: 38)
                            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textTertiary)
                            .background(
                                Circle()
                                    .fill(isSelected ? Theme.primaryAccent.opacity(0.3) : Theme.surface)
                            )
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Theme.primaryAccent.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                    }
                    .accessibilityLabel("\(Alarm.dayNames[day]), \(isSelected ? "selected" : "not selected")")
                }
            }
        }
    }

    // MARK: - Sound Picker

    private var soundSection: some View {
        let categories = ["Classic", "Musical", "Sci-Fi"]
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

        return VStack(alignment: .leading, spacing: 16) {
            sectionHeader("ALARM SOUND")

            ForEach(categories, id: \.self) { category in
                let sounds = AlarmSoundManager.SoundType.allCases.filter { $0.category == category }

                VStack(alignment: .leading, spacing: 8) {
                    Text(category)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.leading, 4)

                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(sounds, id: \.rawValue) { sound in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    alarm.soundType = sound.rawValue
                                }
                                HapticsManager.shared.lightTap()
                                AlarmSoundManager.shared.preview(sound)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: sound.icon)
                                        .font(.system(size: 16))
                                    Text(sound.name)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(
                                    alarm.soundType == sound.rawValue ? Theme.primaryAccent : Theme.textSecondary
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(alarm.soundType == sound.rawValue
                                              ? Theme.primaryAccent.opacity(0.1)
                                              : Theme.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            alarm.soundType == sound.rawValue
                                                ? Theme.primaryAccent.opacity(0.4)
                                                : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                            .accessibilityLabel("\(sound.name) alarm sound")
                            .accessibilityAddTraits(alarm.soundType == sound.rawValue ? .isSelected : [])
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(3)
            .foregroundStyle(Theme.textSecondary)
    }

    private func saveAlarm() {
        AlarmSoundManager.shared.stop()
        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
        alarm.hour = components.hour ?? 7
        alarm.minute = components.minute ?? 0
        if alarm.label.isEmpty {
            alarm.label = "Alarm"
        }
        HapticsManager.shared.success()
        onSave(alarm)
        dismiss()
    }
}
