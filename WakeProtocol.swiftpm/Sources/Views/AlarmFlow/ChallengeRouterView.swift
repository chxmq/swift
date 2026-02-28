import SwiftUI

/// Routes to the selected challenge type (sequence, trace, or color match)
struct ChallengeRouterView: View {
    let challengeType: Int
    let onComplete: () -> Void

    var body: some View {
        switch challengeType {
        case 1:
            PatternTraceChallengeView(onComplete: onComplete)
        case 2:
            ColorMatchChallengeView(onComplete: onComplete)
        default:
            SequenceChallengeView(onComplete: onComplete)
        }
    }
}
