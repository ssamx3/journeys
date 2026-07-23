

import SwiftUI

struct StubDetailView: View {
    let journey: Journey
    @Binding var selectedJourney: Journey?

    @State private var appearPhase: Double = 0
    @State private var revealValues = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .opacity(appearPhase)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    HStack {
                        Spacer()
                        Button { closeView() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .opacity(appearPhase)
                        .offset(y: -4 * (1 - appearPhase))
                    }

                    heroSection
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 16) {
                        statsSection
                    }
                    .opacity(appearPhase)
                    .offset(y: 16 * (1 - appearPhase))
                }
                .padding(.horizontal)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                appearPhase = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    revealValues = true
                }
            }
        }
    }

    private func closeView() {
        withAnimation(.easeOut(duration: 0.22)) {
            appearPhase = 0
            revealValues = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            selectedJourney = nil
        }
    }

    // MARK: - Sections

    private var originCode: String {
        PlaceNames.byName[journey.startPlace]?.code ?? "UNK"
    }

    private var destinationCode: String {
        PlaceNames.byName[journey.endPlace]?.code ?? "UNK"
    }

    private var heroSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .opacity(0.06)

                Stub(
                    originCode: originCode,
                    destinationCode: destinationCode,
                    subtitle: formatDuration(journey.endTime.timeIntervalSince(journey.startTime)),
                    operatorName: journey.company.name
                )
                .scaleEffect(1.35)
            }
            .scaleEffect(0.88 + (0.12 * appearPhase))
            .opacity(appearPhase)
            .padding(.top, 12)
            .padding(.bottom, 4)

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Text(originCode)
                        .fontDesign(.rounded)
                    Image(systemName: "arrow.right")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(destinationCode)
                        .fontDesign(.rounded)
                }
                .font(.system(size: 26, weight: .bold, design: .rounded))

                Text(journey.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
            .opacity(appearPhase)
            .offset(y: 6 * (1 - appearPhase))
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("journey")
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatTile4(
                        value: revealValues ? formatDuration(journey.endTime.timeIntervalSince(journey.startTime)) : "0m",
                        label: "journey time",
                        icon: "clock"
                    )
                    StatTile4(
                        value: revealValues ? "\(originCode) → \(destinationCode)" : "— → —",
                        label: "origin & destination",
                        icon: "arrow.left.arrow.right"
                    )
                }
                HStack(spacing: 10) {
                    StatTile4(
                        value: revealValues ? "\(Int(journey.miles))" : "0",
                        label: "miles travelled",
                        icon: "point.topleft.down.curvedto.point.bottomright.up"
                    )
                    StatTile4(
                        value: revealValues ? journey.company.name : "—",
                        label: "operator",
                        icon: "train.side.front.car"
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}

// MARK: - Stat Tile 4

/// Same tile shape as StatTile2 but with a small leading icon, used for the
/// 2x2 grid on the stub detail screen. Monochrome only — no tint parameter.
struct StatTile4: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: value)

            Text(label)
                .font(.caption2)
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
