import SwiftUI

/// Routes to the selected dismiss challenge type
struct ChallengeContainerView: View {
    let challengeType: Int // 0 = sequence, 1 = trace, 2 = color
    let onComplete: () -> Void

    var body: some View {
        switch challengeType {
        case 1:
            PatternTraceChallengeView(onComplete: onComplete)
        case 2:
            ColorMatchChallengeView(onComplete: onComplete)
        default:
            DismissChallengeView(onComplete: onComplete)
        }
    }
}
