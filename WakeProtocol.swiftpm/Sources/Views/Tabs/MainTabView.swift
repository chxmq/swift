import SwiftUI

/// Main tab navigation — Alarms, Learn, About
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var alarmStore = AlarmStore()

    // Alarm test flow state
    @State private var isTestingAlarm = false
    @State private var testPhase: TestPhase = .countdown
    @State private var testingAlarm: Alarm?

    enum TestPhase {
        case countdown, alarm, challenge, success
    }

    var body: some View {
        ZStack {
            if isTestingAlarm {
                // Full-screen alarm experience
                alarmTestFlow
                    .transition(.opacity)
            } else {
                // Normal tab navigation
                TabView(selection: $selectedTab) {
                    AlarmListView(
                        store: alarmStore,
                        onTestAlarm: { alarm in startTest(alarm) }
                    )
                    .tag(0)
                    .tabItem {
                        Label("Alarms", systemImage: "alarm.fill")
                    }

                    LearnView()
                        .tag(1)
                        .tabItem {
                            Label("Learn", systemImage: "brain.head.profile")
                        }

                    AboutView()
                        .tag(2)
                        .tabItem {
                            Label("About", systemImage: "info.circle.fill")
                        }
                }
                .tint(Theme.primaryAccent)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Style the tab bar
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(Theme.surface)
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.primaryAccent)
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.primaryAccent)
            ]
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.textTertiary)
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.textTertiary)
            ]
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

            // Style the navigation bar
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = UIColor(Theme.background)
            navAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.white
            ]
            navAppearance.titleTextAttributes = [
                .foregroundColor: UIColor.white
            ]
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

            // Request notification permissions
            NotificationManager.shared.requestPermission()
        }
    }

    // MARK: - Alarm Test Flow

    @ViewBuilder
    private var alarmTestFlow: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch testPhase {
            case .countdown:
                CountdownView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        testPhase = .alarm
                    }
                }
            case .alarm:
                AlarmDemoView(soundType: testingAlarm?.soundType ?? 0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        testPhase = .challenge
                    }
                }
            case .challenge:
                ChallengeContainerView(
                    challengeType: testingAlarm?.challengeType ?? 0
                ) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        testPhase = .success
                    }
                }
            case .success:
                SuccessView(onDismiss: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isTestingAlarm = false
                        testPhase = .countdown
                    }
                }, onSnooze: {
                    // Snooze: go back to countdown after brief delay
                    withAnimation(.easeInOut(duration: 0.3)) {
                        testPhase = .countdown
                    }
                })
            }

            // Cancel button during test
            VStack {
                HStack {
                    Spacer()
                    if testPhase != .success {
                        Button {
                            HapticsManager.shared.lightTap()
                            AlarmSoundManager.shared.stop()
                            withAnimation {
                                isTestingAlarm = false
                                testPhase = .countdown
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                                .frame(width: 36, height: 36)
                                .background(Theme.surface.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                }
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: testPhase)
    }

    private func startTest(_ alarm: Alarm) {
        testingAlarm = alarm
        testPhase = .countdown
        withAnimation(.easeInOut(duration: 0.4)) {
            isTestingAlarm = true
        }
        HapticsManager.shared.mediumTap()
    }
}

// MARK: - Full-Screen Alarm View (shown when notification fires)

struct FullScreenAlarmView: View {
    let alarm: Alarm
    let onDismiss: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Background
            Theme.background.ignoresSafeArea()

            // Animated glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.dangerAccent.opacity(glowOpacity), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .scaleEffect(pulseScale)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: pulseScale
                )

            VStack(spacing: 32) {
                Spacer()

                // Alarm icon
                Image(systemName: "alarm.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.dangerAccent)
                    .scaleEffect(pulseScale)

                // Time
                Text(alarm.timeString)
                    .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                // Label
                if !alarm.label.isEmpty {
                    Text(alarm.label)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                // Dismiss button
                Button {
                    AlarmSoundManager.shared.stop()
                    HapticsManager.shared.heavyTap()
                    onDismiss()
                } label: {
                    Text("WAKE UP")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.dangerAccent.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.dangerAccent.opacity(0.6), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            pulseScale = 1.15
            glowOpacity = 0.6
            // Start alarm sound
            let sound = AlarmSoundManager.SoundType(rawValue: alarm.soundType) ?? .radar
            AlarmSoundManager.shared.startAlarm(sound, intensity: alarm.intensity)
        }
    }
}
