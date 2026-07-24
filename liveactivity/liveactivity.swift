//
//  JourneyLiveActivity.swift
//  journeysWidget (Widget Extension target)
//

import ActivityKit
import SwiftUI
import WidgetKit

struct JourneyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JourneyActivityAttributes.self) { context in
            LockScreenJourneyView(attributes: context.attributes, state: context.state)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .activityBackgroundTint(Color(.systemBackground))
                .activitySystemActionForegroundColor(Color.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    ExpandedJourneyView(attributes: context.attributes, state: context.state)
                        .padding(.vertical, 6)
                }
            } compactLeading: {
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 13, weight: .semibold))
            } compactTrailing: {
                CompactReadout(attributes: context.attributes, state: context.state)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .frame(width: 46)
            } minimal: {
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
    }
}

// MARK: - Lock Screen layout

private struct LockScreenJourneyView: View {
    let attributes: JourneyActivityAttributes
    let state: JourneyActivityAttributes.ContentState


    private var derivedProgress: Double {
        guard !attributes.isIndefinite, let targetDate = state.targetDate else {
            return 0
        }
        let total = targetDate.timeIntervalSince(attributes.startDate)
        let remaining = targetDate.timeIntervalSince(Date.now)
        guard total > 0 else { return 0 }
        return max(0, min(1, 1 - (remaining / total)))
    }

    var body: some View {
        VStack(spacing: 12) {

            if !attributes.isIndefinite {
                TrainArcView(
                    originCode: attributes.originCode,
                    destinationCode: attributes.destinationCode,
                    progress: derivedProgress
                )
                .frame(height: 80)
            } else {
                HStack(spacing: 8) {
                    Text(attributes.originCode)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    Text(attributes.destinationCode)
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .padding(.vertical, 4)
            }


            TimerReadout(state: state)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Expanded Dynamic Island layout


private struct ExpandedJourneyView: View {
    let attributes: JourneyActivityAttributes
    let state: JourneyActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(attributes.originCode)
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                Text(attributes.destinationCode)
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))

            TimerReadout(state: state)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared centered timer readout

private struct TimerReadout: View {
    let state: JourneyActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isPaused {
                Text(formattedClock(state.elapsedSeconds))
            } else if let targetDate = state.targetDate {
                Text(timerInterval: Date.now...targetDate, countsDown: true)
            } else {
                Text(timerInterval: state.elapsedApproximateStart...Date.distantFuture, countsDown: false)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func formattedClock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Compact Dynamic Island readout

private struct CompactReadout: View {
    let attributes: JourneyActivityAttributes
    let state: JourneyActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isPaused {
                Text("Paused")
            } else if let targetDate = state.targetDate {
                Text(timerInterval: Date.now...targetDate, countsDown: true)
            } else {
                Text(timerInterval: state.elapsedApproximateStart...Date.distantFuture, countsDown: false)
            }
        }
        .monospacedDigit()
    }
}

// MARK: - Train Arc

private struct TrainArcView: View {
    let originCode: String
    let destinationCode: String
    let progress: Double

    private let sidePadding: CGFloat = 16
    private let labelAreaHeight: CGFloat = 20
    private let arcToLabelGap: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            let baseline: CGFloat = height - labelAreaHeight - arcToLabelGap
            let depth: CGFloat = min(22, baseline - 12)
            let halfWidth = max(1, width / 2 - sidePadding)
            let radius = (halfWidth * halfWidth + depth * depth) / (2 * depth)
            let halfSweep = asin(min(1, halfWidth / radius))
            let center = CGPoint(x: width / 2, y: baseline + (radius - depth))

            ZStack {
                arcPath(center: center, radius: radius, halfSweep: halfSweep, clamp: 1)
                    .stroke(
                        Color(.tertiarySystemFill),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [1, 8])
                    )
                arcPath(center: center, radius: radius, halfSweep: halfSweep, clamp: max(0.02, progress))
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                trainIcon(center: center, radius: radius, halfSweep: halfSweep)

                codeLabel(originCode)
                    .position(x: sidePadding - 6, y: height - labelAreaHeight / 2)
                codeLabel(destinationCode)
                    .position(x: width - sidePadding + 6, y: height - labelAreaHeight / 2)
            }
        }
    }

    private func leftAngle(halfSweep: Double) -> Angle {
        Angle(radians: 3 * .pi / 2 - halfSweep)
    }

    private func arcPath(center: CGPoint, radius: CGFloat, halfSweep: Double, clamp: Double) -> Path {
        let start = leftAngle(halfSweep: halfSweep)
        let sweep = 2 * halfSweep
        return Path { path in
            let end = Angle(radians: start.radians + sweep * clamp)
            path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        }
    }

    private func trainIcon(center: CGPoint, radius: CGFloat, halfSweep: Double) -> some View {
        let start = leftAngle(halfSweep: halfSweep)
        let sweep = 2 * halfSweep
        let angle = Angle(radians: start.radians + sweep * progress)
        let x = center.x + radius * cos(angle.radians)
        let y = center.y + radius * sin(angle.radians)
        return Image(systemName: "train.side.front.car")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(.systemBackground))
            .frame(width: 24, height: 24)
            .background(Color.primary)
            .clipShape(Circle())
            .position(x: x, y: y)
    }

    private func codeLabel(_ code: String) -> some View {
        Text(code)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Helpers

private extension JourneyActivityAttributes.ContentState {
    var elapsedApproximateStart: Date {
        Date.now.addingTimeInterval(-elapsedSeconds)
    }
}
