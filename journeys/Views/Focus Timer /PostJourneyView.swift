//
//  PostJourneyView.swift
//  journeys
//
//  Created by sam on 22/07/2026.
//

import SwiftUI

// MARK: - Post Journey View

struct PostJourneyView: View {
    let result: JourneyResult
    let outcome: JourneyCompletionOutcome
    let onDone: () -> Void

    @State private var appearPhase: Double = 0
    @State private var showStampStep: Bool

    init(result: JourneyResult, outcome: JourneyCompletionOutcome, onDone: @escaping () -> Void) {
        self.result = result
        self.outcome = outcome
        self.onDone = onDone

        _showStampStep = State(initialValue: outcome.stampAwarded && outcome.isFirstStampToday)
    }

    var body: some View {
        ZStack {
            // MARK: Layer 0 — Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .opacity(appearPhase)
                .zIndex(0)

            // MARK: Layer 1 — Content
            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        CompletedTicketCard(result: result)
                            .padding(.top, 8)
                        if !showStampStep {
                            StatsRow(result: result)
                                .transition(.opacity.combined(with: .offset(y: 12)))
                        }


                        if outcome.stampAwarded {
                            if showStampStep {

                                StampCollectCard(
                                    isFirstToday: outcome.isFirstStampToday,
                                    dayStreak: outcome.dayStreak,
                                    streakWeeks: outcome.streakWeeks,
                                    milestone: outcome.milestone,
                                    onComplete: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            showStampStep = false
                                        }
                                    }
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            } else {

                                StampCollectCard(
                                    isFirstToday: false,
                                    dayStreak: outcome.dayStreak,
                                    streakWeeks: outcome.streakWeeks,
                                    milestone: outcome.milestone,
                                    onComplete: nil
                                )
                                .transition(.opacity)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }


                if !showStampStep {
                    doneButton
                        .transition(.opacity.combined(with: .offset(y: 20)))
                }
            }
            .opacity(appearPhase)
            .offset(y: 14 * (1 - appearPhase))
            .zIndex(1)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showStampStep)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                appearPhase = 1
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Journey complete")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(subheadline)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var subheadline: String {
        "\(result.startPlace) → \(result.endPlace)"
    }

    private var doneButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeOut(duration: 0.25)) {
                appearPhase = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                onDone()
            }
        } label: {
            Text("Done")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Completed Ticket Card

private struct CompletedTicketCard: View {
    let result: JourneyResult

    @State private var hasAppeared = false

    private var ticketSeed: String {
        "\(result.startPlace)\(result.endPlace)\(result.company.name)\(Int(result.endTime.timeIntervalSince(result.startTime)))"
    }

    private var opColor: Color { result.company.backgroundColor }

    var body: some View {
        ZStack {
            Color(.tertiarySystemGroupedBackground)

            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("ARRIVED")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                    }
                    .foregroundStyle(.green)

                    Spacer()
                    
                    
                    HStack(spacing: 4) {
                        Image(systemName: "train.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(result.company.name.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundStyle(opColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(opColor.opacity(0.12))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Spacer()

                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Text(codeFromName(result.startPlace))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(result.startPlace)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.6))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(codeFromName(result.endPlace))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(result.endPlace)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                HStack(spacing: 0) {
                    DetailColumn(title: "DATE", value: result.endTime.formatted(.dateTime.month(.abbreviated).day()))
                    DetailColumn(title: "TRAVELLED", value: formatDuration(result.endTime.timeIntervalSince(result.startTime)))
                    DetailColumn(title: "MILES", value: String(format: "%.1f", result.miles))

                    VStack(alignment: .trailing, spacing: 4) {
                        BarcodeShape(seed: ticketSeed)
                            .frame(width: 70, height: 24)
                            .foregroundStyle(.primary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .scaleEffect(hasAppeared ? 1 : 0.9)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 10)
        .shadow(color: .black.opacity(hasAppeared ? 0.18 : 0), radius: 22, x: 0, y: 16)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }

    private func codeFromName(_ name: String) -> String {
        let letters = name.uppercased().filter { $0.isLetter }
        return String(letters.prefix(3))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(max(1, m))m"
    }

    private struct DetailColumn: View {
        let title: String
        let value: String

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.primary.opacity(0.4))
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Stats Row

private struct StatsRow: View {
    let result: JourneyResult

    private var durationSeconds: TimeInterval {
        result.endTime.timeIntervalSince(result.startTime)
    }

    var body: some View {
        HStack(spacing: 12) {
            StatTile3(icon: "clock.fill", value: formatDuration(durationSeconds), label: "focused")
            StatTile3(icon: "point.topleft.down.curvedto.point.bottomright.up", value: String(format: "%.1f mi", result.miles), label: "travelled")
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(max(1, m))m"
    }
}

private struct StatTile3: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Stamp Collect Card

private struct StampCollectCard: View {
    let isFirstToday: Bool
    let dayStreak: Int
    let streakWeeks: Int
    let milestone: CommuterPassMilestone
    let onComplete: (() -> Void)?

    @State private var hasStamped: Bool
    @State private var stampScale: CGFloat
    @State private var stampOpacity: Double
    @State private var stampRotation: Double
    @State private var showDetail: Bool
    @State private var ringPulse: Bool = false

    init(isFirstToday: Bool, dayStreak: Int, streakWeeks: Int, milestone: CommuterPassMilestone, onComplete: (() -> Void)?) {
        self.isFirstToday = isFirstToday
        self.dayStreak = dayStreak
        self.streakWeeks = streakWeeks
        self.milestone = milestone
        self.onComplete = onComplete

        let preStamped = onComplete == nil
        _hasStamped = State(initialValue: preStamped)
        _stampScale = State(initialValue: preStamped ? 1.0 : 0.3)
        _stampOpacity = State(initialValue: preStamped ? 1.0 : 0.0)
        _stampRotation = State(initialValue: preStamped ? 0.0 : -20.0)
        _showDetail = State(initialValue: preStamped)
    }

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 14) {
                ZStack {
                    // Empty ring before stamp
                    Circle()
                        .stroke(.primary.opacity(0.15), lineWidth: 2)
                        .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
                        .frame(width: 80, height: 80)
                        .scaleEffect(ringPulse ? 1.06 : 1.0)
                        .opacity(hasStamped ? 0 : 1)

                    // Stamp
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)
                        .scaleEffect(stampScale)
                        .opacity(stampOpacity)
                        .rotationEffect(.degrees(stampRotation))
                }
                .padding(.top, 4)

                VStack(spacing: 4) {
                    Text(titleText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(streakSubtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showDetail ? 1 : 0)
                .offset(y: showDetail ? 0 : 8)

                if !hasStamped {
                    Text("Tap to stamp")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .opacity(0.7)
                } else if onComplete != nil {
                    Text("Tap to continue")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .opacity(showDetail ? 0.7 : 0)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(NoFlashButtonStyle())
        .onAppear {
            if onComplete != nil {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    ringPulse = true
                }
            }
        }
    }

    private var titleText: String {
        if !hasStamped {
            return isFirstToday ? "Commuter pass ready" : "Stamp ready"
        }
        return isFirstToday ? "Commuter pass stamped" : "Stamp collected"
    }

    private func handleTap() {
        guard !hasStamped else {
            if let onComplete = onComplete {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onComplete()
            }
            return
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeOut(duration: 0.15)) {
            hasStamped = true
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            stampScale = 1.0
            stampRotation = 0
            stampOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                showDetail = true
            }
        }
    }

    private var streakSubtitle: String {
        if dayStreak > 1 {
            return "\(dayStreak) day streak"
        } else if milestone != .none {
            return "\(milestone.streakDays)-day milestone reached"
        } else {
            return "Come back tomorrow to build a streak"
        }
    }
}

private struct NoFlashButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    PostJourneyView(
        result: JourneyResult(
            company: RailCompany(
                name: "Northline Rail",
                cardText: "NORTHLINE",
                totalMiles: 0,
                totalTimeTravelled: 0,
                backgroundColorHex: "007AFF",
                blockColorHex: "FF2D55",
                blockShapeRaw: "circle",
                blockPositionRaw: "bottom",
                fontColorHex: "FFFFFF"
            ),
            miles: 24.6,
            startTime: .now.addingTimeInterval(-1800),
            endTime: .now,
            startPlace: "Folsense",
            endPlace: "Harrow Vale"
        ),
        outcome: JourneyCompletionOutcome(
            stampAwarded: true,
            isFirstStampToday: true,
            streakWeeks: 2,
            dayStreak: 3,
            milestone: .week1
        ),
        onDone: {}
    )
}
