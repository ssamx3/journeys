//
//  TicketView.swift
//  journeys
//

import SwiftUI
import SwiftData

// MARK: - Root

struct TicketView: View {
    let store: JourneyStore
    let stationStore: CurrentStationStore
    @Binding var isPresented: Bool

    @State private var appearPhase: Double = 0
    @State private var step: FlowStep = .duration

    @State private var duration: Double = 15
    @State private var isIndefinite: Bool = false
    @State private var selectedCompany: RailCompany?
    @State private var destination: Place?
    @State private var estimatedMiles: Double = 0
    @State private var showingFocusTimer: Bool = false

    private var origin: Place { stationStore.currentPlace }
    private let minDuration: Double = 15
    private let maxDuration: Double = 180

    enum FlowStep: Int, CaseIterable {
        case duration
        case `operator`
        case ticket
    }

    var body: some View {
        ZStack {
            // MARK: Layer 0 — Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .opacity(appearPhase)
                .zIndex(0)

            // MARK: Layer 1 — Main Ticket Flow Content
            VStack(spacing: 0) {
                topBar

                ZStack {
                    switch step {
                    case .duration:
                        DurationStepView(
                            origin: origin,
                            destination: destination,
                            duration: $duration,
                            isIndefinite: $isIndefinite,
                            minDuration: minDuration,
                            maxDuration: maxDuration
                        )
                        .transition(stepTransition)

                    case .operator:
                        OperatorStepView(store: store, selectedCompany: $selectedCompany)
                            .transition(stepTransition)

                    case .ticket:
                        TicketStepView(
                            origin: origin,
                            destination: destination,
                            company: selectedCompany,
                            duration: duration,
                            isIndefinite: isIndefinite
                        )
                        .transition(stepTransition)
                    }
                }
                .frame(maxHeight: .infinity)
                .opacity(appearPhase)
                .offset(y: 16 * (1 - appearPhase))

                FlowActionBar(
                    title: actionTitle,
                    showsArrow: step != .ticket,
                    isDisabled: step == .operator && selectedCompany == nil
                ) {
                    advance()
                }
                .opacity(appearPhase)
            }
            .zIndex(1)
            .opacity(showingFocusTimer ? 0 : appearPhase)
            .allowsHitTesting(!showingFocusTimer)
            .animation(.easeOut(duration: 0.2), value: showingFocusTimer)

            // MARK: Layer 2 — Focus Timer Overlay
            if showingFocusTimer, let company = selectedCompany {
                FocusTimerView(
                    store: store,
                    stationStore: stationStore,
                    company: company,
                    origin: origin,
                    destination: isIndefinite ? nil : destination,
                    duration: isIndefinite ? nil : duration,
                    isIndefinite: isIndefinite,
                    isPresented: $showingFocusTimer
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .onChange(of: duration) { _, newValue in
            updateJourneyEstimate(duration: newValue)
        }
        .onChange(of: showingFocusTimer) { _, isShowing in
            if !isShowing {
                isPresented = false
                step = .duration
                duration = 15
                isIndefinite = false
                selectedCompany = nil
                destination = nil
                estimatedMiles = 0
            }
        }
        .onAppear {
            updateJourneyEstimate(duration: duration)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                appearPhase = 1
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            if step != .duration {
                Button { goBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            } else {
                Spacer().frame(width: 30, height: 30)
            }
            Spacer()
            FlowStepHeader(current: step.rawValue)
                .opacity(appearPhase)
                .offset(y: 8 * (1 - appearPhase))

            Spacer()

            Button { closeView() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .opacity(appearPhase)
        .offset(y: -4 * (1 - appearPhase))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .offset(x: 24).combined(with: .opacity),
            removal: .offset(x: -24).combined(with: .opacity)
        )
    }

    private var actionTitle: String {
        switch step {
        case .duration: return "Next"
        case .operator: return "Review Ticket"
        case .ticket: return "Begin Journey"
        }
    }

    // MARK: - Navigation

    private func advance() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        switch step {
        case .duration:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                step = .operator
            }
        case .operator:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                step = .ticket
            }
        case .ticket:
            guard selectedCompany != nil else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeInOut(duration: 0.25)) {
                showingFocusTimer = true
            }
        }
    }

    private func goBack() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            switch step {
            case .duration: break
            case .operator: step = .duration
            case .ticket: step = .operator
            }
        }
    }

    private func closeView() {
        withAnimation(.easeOut(duration: 0.22)) {
            appearPhase = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
            step = .duration
            duration = 15
            isIndefinite = false
            selectedCompany = nil
            destination = nil
            estimatedMiles = 0
            showingFocusTimer = false
        }
    }

    // MARK: - Estimation

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

private struct FlowStepHeader: View {
    let current: Int
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
        }
    }
}

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
                    .contentTransition(.opacity)

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
        .animation(.easeInOut(duration: 0.2), value: title)
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
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

    @State private var appearPhase: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 4) {
                Text("How long is your journey?")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if isIndefinite {
                        Text("Indefinite")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
                    } else {
                        Text("\(Int(duration))")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))

                        Text("min")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: duration)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isIndefinite)
                .onChange(of: duration) { _, newValue in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isIndefinite = newValue < minDuration
                    }
                }

                HStack(spacing: 8) {
                    Text(origin.code)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .contentTransition(.symbolEffect(.replace))

                    if isIndefinite {
                        Text("???")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    } else if let dest = destination {
                        Text(dest.code)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: destination?.code)
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isIndefinite)
            }

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Slider(
                    value: $duration,
                    in: 0...maxDuration
                )
                .tint(isIndefinite ? Color.secondary.opacity(0.4) : Color.secondary.opacity(1))
                .frame(height: 32)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .opacity(appearPhase)
        .offset(y: 10 * (1 - appearPhase))
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                appearPhase = 1
            }
        }
        .onChange(of: duration) { _, newValue in
            isIndefinite = newValue < minDuration
        }
    }
}

// MARK: - Step 2: Operator Selection

private struct OperatorStepView: View {
    let store: JourneyStore
    @Binding var selectedCompany: RailCompany?

    @State private var companies: [RailCompany] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Who are you travelling with?")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 16)

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

// MARK: - Operator Row

private struct OperatorRow: View {
    let company: RailCompany
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {

                PassCardPreview(
                    cardText: company.cardText,
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
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(NoFlashButtonStyle())
    }
}

// MARK: - Pass Card Preview (for Operator Row)

private struct PassCardPreview: View {
    let cardText: String
    let backgroundColor: Color
    let blockColor: Color
    let blockShape: CardBlockShape
    let blockPosition: CardBlockPosition
    let fontColor: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let size = max(w, h)

            let fontSize = min(w * 0.18, h * 0.28)

            ZStack(alignment: .topLeading) {
                backgroundColor

                Group {
                    switch blockShape {
                    case .circle:
                        Circle().fill(blockColor)
                    case .square:
                        Rectangle().fill(blockColor)
                    }
                }
                .frame(width: size, height: size)
                .position(previewBlockCoordinates(for: blockPosition, width: w, height: h))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Spacer()
                        Image(systemName: "wave.3.forward")
                            .font(.system(size: max(8, fontSize * 0.5), weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Spacer()

                    Text(cardText)
                        .font(.system(size: fontSize, design: .rounded))
                        .foregroundStyle(fontColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(8)
            }
        }
    }

    private func previewBlockCoordinates(for position: CardBlockPosition, width: CGFloat, height: CGFloat) -> CGPoint {
        switch position {
        case .top: return CGPoint(x: width / 2, y: 0)
        case .bottom: return CGPoint(x: width / 2, y: height)
        case .left: return CGPoint(x: 0, y: height / 2)
        case .right: return CGPoint(x: width, y: height / 2)
        }
    }
}

private struct NoFlashButtonStyle: ButtonStyle {
    func makeButtonLabel(configuration: Configuration) -> some View {
        configuration.label
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
    }
}

// MARK: - Ticket Reveal Card

private struct TicketRevealCard: View {
    let origin: Place
    let destination: Place?
    let company: RailCompany?
    let duration: Double
    let isIndefinite: Bool

    @State private var hasAppeared = false
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
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    hasAppeared = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }

    private var ticketBody: some View {
        let opColor = company?.backgroundColor ?? .blue

        return ZStack {
            Color(.tertiarySystemGroupedBackground)

            VStack(spacing: 0) {
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

                Spacer()

                HStack(spacing: 12) {
                    VStack(spacing: 2) {
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
                            .foregroundStyle(.primary.opacity(0.6))
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
                            .frame(width: 70, height: 24)
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
    TicketView(store: .preview, stationStore: CurrentStationStore(), isPresented: .constant(true))
}

#Preview("Ticket step only") {
    TicketStepView(
        origin: PlaceNames.byName["Folsense"] ?? Place(name: "Folsense", code: "FOL"),
        destination: PlaceNames.all.first,
        company: nil,
        duration: 45,
        isIndefinite: false
    )
}
