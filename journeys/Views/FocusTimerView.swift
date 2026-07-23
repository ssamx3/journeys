//
//  FocusTimerView.swift
//  journeys
//

import SwiftUI

// MARK: - Focus Timer View

struct FocusTimerView: View {
    let store: JourneyStore
    let stationStore: CurrentStationStore

    let company: RailCompany
    let origin: Place
    let destination: Place?
    let duration: Double?
    let isIndefinite: Bool

    @Binding var isPresented: Bool

    @State private var conductor = Conductor()
    @State private var appearPhase: Double = 0

    @State private var displayTick: Date = .now
    @State private var timerTask: Task<Void, Never>?

    @State private var didFinish = false

    @State private var showingPostJourney = false
    @State private var postJourneyResult: JourneyResult?
    @State private var postJourneyOutcome: JourneyCompletionOutcome?

    private let indefiniteVoidThreshold: TimeInterval = 15 * 60

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                topBar

                Spacer(minLength: 0)

                arcProgress
                    .padding(.horizontal, 28)

                Spacer(minLength: 28)

                readout

                Spacer(minLength: 28)

                Spacer(minLength: 0)

                controls

                debugFooter
            }
            .opacity(showingPostJourney ? 0 : appearPhase)
            .offset(y: 12 * (1 - appearPhase))
            .allowsHitTesting(!showingPostJourney)

            if showingPostJourney, let result = postJourneyResult, let outcome = postJourneyOutcome {
                PostJourneyView(result: result, outcome: outcome) {
                    close()
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 1.03)),
                    removal: .opacity
                ))
                .zIndex(1)
            }
        }
        .onAppear(perform: start)
        .onDisappear {
            timerTask?.cancel()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
            .opacity(appearPhase)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 11, weight: .bold))
                Text(company.name.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
            }
            .foregroundStyle(.secondary)

            Spacer()

            milesReadout

            Spacer()

            if isIndefinite {
                Label("INDEFINITE", systemImage: "infinity")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.secondary)
            } else {
                Text("ETA: \(etaString)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var milesReadout: some View {
        HStack(spacing: 5) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            Text(milesString)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())

            Text("mi")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.secondary)
        }
        .animation(.easeInOut(duration: 0.2), value: displayTick)
    }

    private var etaString: String {
        guard let duration else { return "--:--" }
        let finishDate = Date.now.addingTimeInterval(max(0, duration * 60 - conductor.elapsedSeconds))
        return finishDate.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Arc progress

    private var arcProgress: some View {
        Group {
            if isIndefinite {

                EmptyView()
            } else {
                TrainArcView(
                    originCode: origin.code,
                    destinationCode: destination?.code ?? "???",
                    progress: conductor.progress
                )
                .frame(height: 150)
                .padding(.top, 24)
            }
        }
    }

    // MARK: - Readout

    private var readout: some View {
        VStack(spacing: 6) {
            Text(isIndefinite ? "TIME TRAVELLING" : "TIME REMAINING")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(.secondary)

            Text(readoutString)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.25), value: displayTick)

            if conductor.isOverdriveActive {
                Label("Overdrive · 1.5×", systemImage: "bolt.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: conductor.isOverdriveActive)
    }

    private var readoutString: String {
        if isIndefinite {
            return formatClock(conductor.elapsedSeconds)
        } else {
            let remaining = max(0, (duration ?? 0) * 60 - conductor.elapsedSeconds)
            return formatClock(remaining)
        }
    }

    private func formatClock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Miles

    private var milesString: String {
        String(format: "%.1f", conductor.milesSoFar)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            if isIndefinite && conductor.elapsedSeconds >= 1800 && !conductor.isOverdriveActive {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    conductor.disembarkAtNextStop()
                } label: {
                    Text("Disembark at next stop")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            }

            GeometryReader { geo in
                let spacing: CGFloat = 10
                let pauseWidth = (geo.size.width - spacing) * 0.7
                let voidWidth = (geo.size.width - spacing) * 0.3

                HStack(spacing: spacing) {
                    PauseButton(isPaused: conductor.isPaused, action: togglePause)
                        .frame(width: pauseWidth)

                    HoldToDisembarkButton(
                        isEnabled: canDisembarkImmediately,
                        voidWarning: !canDisembarkImmediately,
                        action: handleDisembarkHeld
                    )
                    .frame(width: voidWidth)
                }
            }
            .frame(height: 56)



            
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isIndefinite && conductor.elapsedSeconds >= 1800)
    }


    private var debugFooter: some View {
        Group {
#if DEBUG
            Button {
                quickFinish()
            } label: {
                Text("Quick finish (debug)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.bottom, 10)
#endif
        }
    }

    private var canDisembarkImmediately: Bool {
        if isIndefinite {
            return conductor.elapsedSeconds >= indefiniteVoidThreshold
        } else {
            return conductor.shouldAutoDisembark
        }
    }

    // MARK: - Lifecycle

    private func start() {
        conductor.begin(
            company: company,
            startPlace: origin.name,
            targetPlace: isIndefinite ? nil : destination?.name,
            duration: isIndefinite ? nil : (duration.map { $0 * 60 }),
            endless: isIndefinite
        )

        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            appearPhase = 1
        }


        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                displayTick = .now
                checkAutoDisembark()
            }
        }
    }

    private func checkAutoDisembark() {
        guard !didFinish, !conductor.isPaused else { return }
        // Covers both modes: countdown journeys hit their target duration,
        // and indefinite journeys in overdrive hit their next 10-minute stop.
        // Conductor no longer disembarks itself (see Conductor.startTicking),
        // so this is the only place a finished journey actually gets closed out.
        if conductor.shouldAutoDisembark {
            finishSuccessfully()
        }
    }

    private func togglePause() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if conductor.isPaused {
            conductor.resume()
        } else {
            conductor.pause()
        }
    }

    // MARK: - Finishing

    private func handleDisembarkHeld() {
        if canDisembarkImmediately {
            finishSuccessfully()
        } else {
            voidJourney()
        }
    }

    private func finishSuccessfully() {
        guard !didFinish else { return }
        didFinish = true
        timerTask?.cancel()

        var result = conductor.disembark()
        if isIndefinite {

            let arrival = destination ?? resolvedIndefiniteDestination()
            result = JourneyResult(
                company: result.company,
                miles: result.miles,
                startTime: result.startTime,
                endTime: result.endTime,
                startPlace: result.startPlace,
                endPlace: arrival.name
            )
        }

        let outcome = store.completeJourney(result)
        stationStore.arrive(at: result.endPlace)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showPostJourney(result: result, outcome: outcome)
    }


    private func resolvedIndefiniteDestination() -> Place {
        let available = PlaceNames.all.filter { $0.code != origin.code }
        return available.randomElement() ?? PlaceNames.randomPlace()
    }

    private func voidJourney() {
        guard !didFinish else { return }
        didFinish = true
        timerTask?.cancel()
        conductor.cancel()

        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        close()
    }


    private func quickFinish() {
        guard !didFinish else { return }
        didFinish = true
        timerTask?.cancel()

        let simulatedDuration: TimeInterval = isIndefinite
            ? max(indefiniteVoidThreshold, conductor.elapsedSeconds)
            : (duration ?? 15) * 60

        let end = Date.now
        let start = end.addingTimeInterval(-simulatedDuration)
        let simulatedMiles = simulatedDuration * company.level.pace
        let endPlaceName = (destination ?? resolvedIndefiniteDestination()).name

        conductor.cancel()

        let result = JourneyResult(
            company: company,
            miles: simulatedMiles,
            startTime: start,
            endTime: end,
            startPlace: origin.name,
            endPlace: endPlaceName
        )
        let outcome = store.completeJourney(result)
        stationStore.arrive(at: result.endPlace)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showPostJourney(result: result, outcome: outcome)
    }

    // MARK: - Post-journey

    private func showPostJourney(result: JourneyResult, outcome: JourneyCompletionOutcome) {
        postJourneyResult = result
        postJourneyOutcome = outcome
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showingPostJourney = true
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.22)) {
            appearPhase = 0
            showingPostJourney = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

// MARK: - Arc Progress View

private struct TrainArcView: View {
    let originCode: String
    let destinationCode: String
    let progress: Double


    private let sidePadding: CGFloat = 28
    private let labelAreaHeight: CGFloat = 22
    private let arcToLabelGap: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            // Arc now sits above a reserved label strip, with an explicit gap
            let baseline: CGFloat = height - labelAreaHeight - arcToLabelGap
            let depth: CGFloat = min(30, baseline - 16)
            let halfWidth = max(1, width / 2 - sidePadding)
            let radius = (halfWidth * halfWidth + depth * depth) / (2 * depth)
            let halfSweep = asin(min(1, halfWidth / radius))
            let center = CGPoint(x: width / 2, y: baseline + (radius - depth))

            ZStack {
                arcPath(center: center, radius: radius, halfSweep: halfSweep, clamp: 1)
                    .stroke(
                        Color(.tertiarySystemFill),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [1, 9])
                    )
                arcPath(center: center, radius: radius, halfSweep: halfSweep, clamp: progress)
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .animation(.easeInOut(duration: 0.4), value: progress)
                trainIcon(center: center, radius: radius, halfSweep: halfSweep)

                codeLabel(originCode)
                    .position(x: sidePadding - 12, y: height - labelAreaHeight / 2)
                codeLabel(destinationCode)
                    .position(x: width - sidePadding + 12, y: height - labelAreaHeight / 2)
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
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color(.systemBackground))
            .frame(width: 32, height: 32)
            .background(Color.primary)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            .position(x: x, y: y)
            .animation(.easeInOut(duration: 0.4), value: progress)
    }

    private func codeLabel(_ code: String) -> some View {
        Text(code)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Pause Button


private struct PauseButton: View {
    let isPaused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(isPaused ? "Resume" : "Pause")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PauseButtonPressStyle())
        .animation(.easeInOut(duration: 0.2), value: isPaused)
    }
}

private struct PauseButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}


private struct HoldToDisembarkButton: View {
    let isEnabled: Bool
    let voidWarning: Bool
    let action: () -> Void

    @State private var holdProgress: Double = 0
    @State private var isHolding = false
    @State private var holdTask: Task<Void, Never>?

    private let holdDuration: Double = 1.1

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(.tertiarySystemGroupedBackground))

            GeometryReader { geo in
                Capsule()
                    .fill(fillColor.opacity(0.9))
                    .frame(width: geo.size.width * holdProgress)
            }
            .clipShape(Capsule())
        }
        .compositingGroup()
        .overlay {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(labelColor)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(height: 56)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .scaleEffect(isHolding ? 0.98 : 1)
        .animation(.easeOut(duration: 0.15), value: isHolding)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginHold() }
                .onEnded { _ in endHold() }
        )
        .accessibilityLabel(voidWarning ? "Hold to void journey" : "Hold to disembark")
    }

    private var iconName: String {
        if isHolding { return "checkmark" }
        return voidWarning ? "trash" : "flag.checkered"
    }

    private var fillColor: Color {
        voidWarning ? Color.red.opacity(0.5) : Color.green.opacity(0.55)
    }

    private var labelColor: Color {
        holdProgress > 0.5 ? Color(.systemBackground) : Color.primary
    }

    private func beginHold() {
        guard !isHolding else { return }
        isHolding = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1
        }

        holdTask = Task {
            try? await Task.sleep(for: .seconds(holdDuration))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard isHolding else { return }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                action()
            }
        }
    }

    private func endHold() {
        guard isHolding else { return }
        isHolding = false
        holdTask?.cancel()
        holdTask = nil
        withAnimation(.easeOut(duration: 0.25)) {
            holdProgress = 0
        }
    }
}
