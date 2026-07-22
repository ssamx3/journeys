//
//  TicketFlowView.swift
//  journeys
//
//  Created by sam on 20/07/2026.
//

import SwiftUI
import SwiftData

// MARK: - Main Flow Container

struct TicketFlowView: View {
    @Environment(\.dismiss) private var dismiss
    let store: JourneyStore

    @State private var path: [FlowStep] = []
    @State private var duration: Double = 15
    @State private var isIndefinite: Bool = false
    @State private var selectedCompany: RailCompany?
    @State private var destination: Place?
    @State private var estimatedMiles: Double = 0

    private let origin = PlaceNames.byName["Folsense"] ?? Place(name: "Folsense", code: "FOL")
    private let minDuration: Double = 15
    private let maxDuration: Double = 180

    /// Only the *pushed* screens live in the nav path — duration is the root.
    enum FlowStep: Int, Hashable {
        case operatorSelect
        case ticket
    }

    var body: some View {
        NavigationStack(path: $path) {
            DurationStepView(
                origin: origin,
                destination: destination,
                duration: $duration,
                isIndefinite: $isIndefinite,
                minDuration: minDuration,
                maxDuration: maxDuration
            )
            .navigationTitle("Plan Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { closeToolbarItem }
            .safeAreaInset(edge: .top, spacing: 0) {
                FlowStepHeader(current: 0, subtitle: subtitleForDuration)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                FlowActionBar(title: "Next") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    path.append(.operatorSelect)
                }
            }
            .navigationDestination(for: FlowStep.self) { step in
                switch step {
                case .operatorSelect:
                    OperatorStepView(store: store, selectedCompany: $selectedCompany)
                        .navigationTitle("Select Operator")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { closeToolbarItem }
                        .safeAreaInset(edge: .top, spacing: 0) {
                            FlowStepHeader(
                                current: 1,
                                subtitle: selectedCompany?.name ?? "Choose an operator"
                            )
                        }
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            FlowActionBar(title: "Review Ticket", isDisabled: selectedCompany == nil) {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                path.append(.ticket)
                            }
                        }

                case .ticket:
                    TicketStepView(
                        origin: origin,
                        destination: destination,
                        company: selectedCompany,
                        duration: duration,
                        isIndefinite: isIndefinite
                    )
                    .navigationTitle("Your Ticket")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { closeToolbarItem }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        FlowStepHeader(current: 2, subtitle: "Ready to depart")
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        FlowActionBar(title: "Begin Journey", showsArrow: false) {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            dismiss()
                        }
                    }
                }
            }
        }
        .onChange(of: duration) { _, newValue in
            updateJourneyEstimate(duration: newValue)
        }
        .onAppear {
            updateJourneyEstimate(duration: duration)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .presentationBackground(Color(.systemGroupedBackground))
    }

    @ToolbarContentBuilder
    private var closeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
        }
    }

    private var subtitleForDuration: String {
        isIndefinite ? "Indefinite mode" : formatDurationLabel(duration)
    }

    private func updateJourneyEstimate(duration: Double) {
        if duration < minDuration {
            isIndefinite = true
            destination = nil
            estimatedMiles = 0
            return
        }
        isIndefinite = false
        let bucket = Int(duration / 20)
        let available = PlaceNames.all.filter { $0.code != origin.code }
        let index = bucket % available.count
        destination = available[index]
        let baseSpeed = 0.6 + Double(index % 5) * 0.15
        estimatedMiles = duration * baseSpeed
    }

    private func formatDurationLabel(_ minutes: Double) -> String {
        let hrs = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hrs > 0 {
            return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
        }
        return "\(mins)m"
    }
}

// MARK: - Shared Flow Chrome

/// Progress dots + a short status line, pinned under the native nav bar.
private struct FlowStepHeader: View {
    let current: Int
    let subtitle: String
    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index == current ? Color.primary : Color(.tertiarySystemFill))
                        .frame(width: index == current ? 24 : 8, height: 8)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: subtitle)
        }
        .padding(.top, 8)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

/// A single, consistently-styled call to action pinned to the bottom of every step.
private struct FlowActionBar: View {
    let title: String
    var showsArrow: Bool = true
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                if showsArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(Color(.systemBackground))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.bar)
    }
}

// MARK: - Step 1: Duration Selection

private struct DurationStepView: View {
    let origin: Place
    let destination: Place?
    @Binding var duration: Double
    @Binding var isIndefinite: Bool
    let minDuration: Double
    let maxDuration: Double

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Spacer().frame(height: 20)

                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(origin.code)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(origin.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ZStack {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 60, height: 32)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 4) {
                        if isIndefinite {
                            Text("???")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        } else if let dest = destination {
                            Text(dest.code)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text(dest.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 90)

                MetricBadge(
                    value: isIndefinite ? "∞" : formatDuration(duration),
                    label: "duration",
                    icon: "clock.fill"
                )

                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                TactileDurationSlider(
                    value: $duration,
                    isIndefinite: $isIndefinite,
                    minDuration: minDuration,
                    maxDuration: maxDuration
                )
                .frame(height: 60)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 20)
        }
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hrs = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hrs > 0 { return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h" }
        return "\(mins)m"
    }
}

// MARK: - Step 2: Operator Selection

private struct OperatorStepView: View {
    let store: JourneyStore
    @Binding var selectedCompany: RailCompany?

    @State private var companies: [RailCompany] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Select your rail operator")
                .font(.title2.weight(.bold))
                .padding(.horizontal)
                .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(companies) { company in
                        OperatorRow(
                            company: company,
                            isSelected: selectedCompany?.persistentModelID == company.persistentModelID
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedCompany = company
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            companies = store.fetchAllCompanies()
        }
    }
}

// MARK: - Step 3: Ticket Reveal

private struct TicketStepView: View {
    let origin: Place
    let destination: Place?
    let company: RailCompany?
    let duration: Double
    let isIndefinite: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 10)

            Text("Your ticket is ready")
                .font(.title2.weight(.bold))

            TicketRevealCard(
                origin: origin,
                destination: destination,
                company: company,
                duration: duration,
                isIndefinite: isIndefinite
            )
            .frame(height: 220)

            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Tactile Scrubber Slider

private struct TactileDurationSlider: View {
    @Binding var value: Double
    @Binding var isIndefinite: Bool
    let minDuration: Double
    let maxDuration: Double

    private let barCount = 48
    private let barWidth: CGFloat = 1.5
    private let barGap: CGFloat = 5

    @State private var isDragging = false
    @State private var lastHapticIndex: Int = -1

    var body: some View {
        GeometryReader { geo in
            let totalContentWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barGap
            let startX = (geo.size.width - totalContentWidth) / 2

            ZStack(alignment: .leading) {
                // Static tick marks — all same height, no individual animations
                HStack(spacing: barGap) {
                    ForEach(0..<barCount, id: \.self) { index in
                        let barValue = Double(index) / Double(barCount - 1) * maxDuration
                        let isPassed = value >= barValue

                        Capsule()
                            .fill(isPassed ? Color.white.opacity(0.9) : Color.primary.opacity(0.1))
                            .frame(width: barWidth, height: 28)
                    }
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Thumb — a clean white line with shadow
                Capsule()
                    .fill(.white)
                    .frame(width: 3, height: 44)
                    .shadow(
                        color: .black.opacity(isDragging ? 0.35 : 0.2),
                        radius: isDragging ? 8 : 4,
                        x: 0,
                        y: 1
                    )
                    .position(
                        x: startX + thumbOffset(totalWidth: totalContentWidth),
                        y: geo.size.height / 2
                    )
                    .animation(.spring(response: 0.22, dampingFraction: 0.88), value: value)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        updateValue(from: gesture, totalWidth: totalContentWidth, startX: startX)
                    }
                    .onEnded { _ in
                        isDragging = false
                        snapIfNeeded()
                    }
            )
        }
    }

    private func thumbOffset(totalWidth: CGFloat) -> CGFloat {
        let ratio = value / maxDuration
        return CGFloat(ratio) * totalWidth + barWidth / 2
    }

    private func updateValue(from gesture: DragGesture.Value, totalWidth: CGFloat, startX: CGFloat) {
        let relativeX = gesture.location.x - startX
        let ratio = max(0, min(1, relativeX / totalWidth))
        let rawValue = Double(ratio) * maxDuration
        let snapped = round(rawValue / 5) * 5
        value = max(0, min(snapped, maxDuration))
        isIndefinite = value < minDuration

        let bucket = Int(value / 5)
        if bucket != lastHapticIndex {
            let style: UIImpactFeedbackGenerator.FeedbackStyle = (bucket == 0) ? .medium : .light
            UIImpactFeedbackGenerator(style: style).impactOccurred()
            lastHapticIndex = bucket
        }
    }

    private func snapIfNeeded() {
        if value < minDuration && value > 0 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                value = 0
                isIndefinite = true
            }
        }
    }
}

// MARK: - Operator Row

private struct OperatorRow: View {
    let company: RailCompany
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                PassCard(
                    title: company.name,
                    cardText: company.cardText,
                    subtitle: company.level.rawValue.capitalized,
                    iconName: "train.fill",
                    backgroundColor: company.backgroundColor,
                    blockColor: company.blockColor,
                    blockShape: company.blockShape,
                    blockPosition: company.blockPosition,
                    fontColor: company.fontColor
                )
                .frame(width: 80, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(company.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(company.level.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ticket Reveal Card

/// A premium, Wallet/Flighty-style entrance: the pass scales and fades in
/// with a soft spring, then a single light sweep glides across it once.
/// No printer metaphor — just a clean, confident materialisation.
private struct TicketRevealCard: View {
    let origin: Place
    let destination: Place?
    let company: RailCompany?
    let duration: Double
    let isIndefinite: Bool

    @State private var hasAppeared = false
    @State private var shimmerProgress: CGFloat = -0.5
    @State private var hasAnimated = false

    private var ticketSeed: String {
        "\(origin.code)\(destination?.code ?? "???")\(company?.name ?? "")\(Int(duration))"
    }

    var body: some View {
        ticketBody
            .frame(width: 320, height: 190)
            .scaleEffect(hasAppeared ? 1 : 0.9)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
            .shadow(color: .black.opacity(hasAppeared ? 0.18 : 0), radius: 22, x: 0, y: 16)
            .overlay(shimmerOverlay)
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    hasAppeared = true
                }
                withAnimation(.easeInOut(duration: 0.85).delay(0.2)) {
                    shimmerProgress = 1.5
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }

    private var shimmerOverlay: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.55), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: geo.size.width * 0.4)
            .rotationEffect(.degrees(18))
            .offset(x: shimmerProgress * geo.size.width)
            .blendMode(.plusLighter)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
    }

    private var ticketBody: some View {
        let opColor = company?.backgroundColor ?? .blue

        return ZStack {
            Color(.tertiarySystemGroupedBackground)

            GuillochePattern()
                .stroke(Color.primary.opacity(0.04), lineWidth: 0.8)
                .drawingGroup()

            VStack(spacing: 0) {
                // Header with operator badge
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "train.side.front.car")
                            .font(.system(size: 12, weight: .bold))
                        Text("BOARDING PASS")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                    }
                    .foregroundStyle(.secondary.opacity(0.7))

                    Spacer()

                    // Operator colour badge only here
                    HStack(spacing: 4) {
                        Image(systemName: "train.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(company?.name.uppercased() ?? "RAIL")
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

                // Route
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(origin.code)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(origin.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary.opacity(0.6))

                        Capsule()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 40, height: 4)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if isIndefinite {
                            Text("???")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(.primary)
                        } else {
                            Text(destination?.code ?? "???")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                        Text(isIndefinite ? "Unknown" : (destination?.name ?? "Unknown"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // Perforation line
                HStack(spacing: 0) {
                    ForEach(0..<24) { i in
                        Rectangle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: i % 2 == 0 ? 4 : 6, height: 1.5)
                    }
                }

                // Footer
                HStack(spacing: 0) {
                    DetailColumn(
                        title: "DATE",
                        value: Date().formatted(.dateTime.month(.abbreviated).day()),
                        fontColor: .primary
                    )

                    DetailColumn(
                        title: "DURATION",
                        value: isIndefinite ? "∞" : formatDuration(duration),
                        fontColor: .primary
                    )

                    DetailColumn(
                        title: "CLASS",
                        value: "Standard",
                        fontColor: .primary
                    )

                    VStack(alignment: .trailing, spacing: 4) {
                        BarcodeShape(seed: ticketSeed)
                            .frame(width: 50, height: 24)
                            .foregroundStyle(.primary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hrs = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hrs > 0 { return "\(hrs)h\(mins > 0 ? " \(mins)m" : "")" }
        return "\(mins)m"
    }
}

// MARK: - Supporting Views

private struct MetricBadge: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

private struct DetailColumn: View {
    let title: String
    let value: String
    let fontColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(fontColor.opacity(0.4))
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(fontColor.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    TicketFlowView(store: .preview)
}
