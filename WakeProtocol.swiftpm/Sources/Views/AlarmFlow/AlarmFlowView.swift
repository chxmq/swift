import SwiftUI

/// Alarm flow — alarm screen → challenge → success
struct AlarmFlowView: View {
    let alarm: Alarm?
    let onDismiss: () -> Void
    let onCancel: (() -> Void)?

    @State private var phase: AlarmFlowPhase = .alarm

    enum AlarmFlowPhase {
        case alarm, challenge, success
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch phase {
            case .alarm:
                AlarmView(onTriggerChallenge: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        phase = .challenge
                    }
                }, soundType: alarm?.soundType ?? 0)
            case .challenge:
                ChallengeRouterView(challengeType: alarm?.challengeType ?? 0) {
                    WakeHistoryStore.shared.recordWake()
                    withAnimation(.easeInOut(duration: 0.5)) {
                        phase = .success
                    }
                }
            case .success:
                SuccessView(onDismiss: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        onDismiss()
                    }
                })
            }

            if let onCancel, phase != .success {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            HapticsManager.shared.lightTap()
                            AlarmSoundManager.shared.stop()
                            withAnimation { onCancel() }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(Theme.surface.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: phase)
    }
}
