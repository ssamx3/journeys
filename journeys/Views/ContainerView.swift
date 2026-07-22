//
//  ContainerView.swift
//  journeys
//
//  Created by sam on 17/07/2026.
//

import SwiftUI
import SwiftData

struct ContainerView: View {
    let store: JourneyStore

    @State private var showingStubBook = false
    @State private var showingCreatePass = false
    @State private var statsRange: StatsRange = .week
    @State private var showingTicketFlow = false

    @State private var companies: [RailCompany] = []
    @State private var recentJourneys: [Journey] = []
    @State private var commuterPass: CommuterPass?


    @State private var statsSnapshot = StatsSnapshot(miles: 0, timeLabel: "0m", topOperator: "-", personalBestMiles: 0)

    @Namespace private var heroNamespace
    @State private var selectedCompany: RailCompany?
    @State private var selectedCompanyJourneys: [Journey] = []

    private let currentStation = "Folsense Station"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        heroCard
                        passesCard
                        
                        stubsCard
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                            .onTapGesture { showingStubBook = true }

                        statsCard
                        debugCard
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if let company = selectedCompany {
                    RailCompanyView(store: store, company: company, selectedCompany: $selectedCompany, journeys: selectedCompanyJourneys)
                        .zIndex(2)
                    
                
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showingStubBook) { StubBookView() }
            .sheet(isPresented: $showingCreatePass) {
                CreatePassView(store: store)
            }
            
            .sheet(isPresented: $showingTicketFlow) {
                TicketFlowView(store: store)
            }
            
            
            .onChange(of: showingCreatePass) { _, isShowing in
                if !isShowing {
                    selectedCompany = nil
                    selectedCompanyJourneys = []
                    refreshData()
                }
            }

            .onAppear(perform: refreshData)
            .onChange(of: statsRange) { _, _ in
                updateStats()
            }
            .onChange(of: selectedCompany) { _, newValue in

                if newValue == nil {
                    refreshData()
                }
            }
        }
    }

    // MARK: - Data Refresh

    private func refreshData() {
        companies = store.fetchAllCompanies()
        recentJourneys = store.fetchRecentJourneys(limit: 10)
        commuterPass = store.fetchOrCreateCommuterPass()
        updateStats()
    }

    private func updateStats() {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch statsRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .day, value: -365, to: now) ?? now
        }

        let journeys = store.fetchJourneys(from: startDate)

        let totalMiles = journeys.reduce(0) { $0 + $1.miles }
        let totalTime = journeys.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }

        let operatorMiles = Dictionary(grouping: journeys, by: { $0.company.name })
            .mapValues { $0.reduce(0) { $0 + $1.miles } }
        let topOperator = operatorMiles.max(by: { $0.value < $1.value })?.key ?? "-"

        let personalBest = journeys.map(\.miles).max() ?? 0

        withAnimation(.easeOut(duration: 0.8)) {
            statsSnapshot = StatsSnapshot(
                miles: Int(totalMiles),
                timeLabel: formatTime(totalTime),
                topOperator: topOperator,
                personalBestMiles: Int(personalBest)
            )
        }
    }

    // MARK: - Sections

    private var heroCard: some View {
        VStack {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("currently at")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(currentStation)
                        .font(.largeTitle.bold())
                }

                Button {
                    showingTicketFlow = true
                } label: {
                    HStack {
                        Text("Get tickets")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(Color(.blue).opacity(0.9))
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }.padding(.top)
    }

    private var passesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("passes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showingCreatePass = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                // Swapped HStack for LazyHStack
                HStack(spacing: 12) {
                    if let pass = commuterPass {
                        CommuterPassCard(
                            streak: pass.streakWeeks,
                            stampedDays: stampedDays(for: pass)
                        )
                    }
                    
                    ForEach(companies) { company in
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
                        .matchedGeometryEffect(id: company.persistentModelID, in: heroNamespace)
                        .onTapGesture {
                            let journeys = store.fetchJourneys(for: company)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedCompany = company
                            }
                            selectedCompanyJourneys = journeys
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground)))
    }

    private var stubsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("stubs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                // Swapped HStack for LazyHStack to prevent mass main-thread relationship faults
                LazyHStack(spacing: 16) {
                    if recentJourneys.isEmpty {
                        Text("No journeys yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(recentJourneys.prefix(5)) { journey in
                            Stub(
                                originCode: PlaceNames.byName[journey.startPlace]?.code ?? "UNK",
                                destinationCode: PlaceNames.byName[journey.endPlace]?.code ?? "UNK",
                                subtitle: formatDuration(journey.endTime.timeIntervalSince(journey.startTime)),
                                operatorName: journey.company.name
                            )
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                StatsRangeSwitch(selection: $statsRange)
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatTile(value: "\(statsSnapshot.miles)", label: "miles travelled")
                    StatTile(value: statsSnapshot.timeLabel, label: "time travelling")
                }
                HStack(spacing: 10) {
                    StatTile(value: statsSnapshot.topOperator, label: "most used operator")
                    StatTile(value: "\(statsSnapshot.personalBestMiles) miles", label: "personal best journey")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("debug")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button {
                    addDummyJourney()
                } label: {
                    Label("Add Journey", systemImage: "plus.circle")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }

                Button {
                    removeLastJourney()
                } label: {
                    Label("Remove Last", systemImage: "minus.circle")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }

                Button {
                    resetAllJourneys()
                } label: {
                    Label("Reset All", systemImage: "trash.slash")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.25))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: - Stats

    private struct StatsSnapshot {
        let miles: Int
        let timeLabel: String
        let topOperator: String
        let personalBestMiles: Int
    }

    private enum StatsRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case year = "365D"
    }

    private struct StatsRangeSwitch: View {
        @Binding var selection: StatsRange
        @Namespace private var namespace

        var body: some View {
            HStack(spacing: 2) {
                ForEach(StatsRange.allCases, id: \.self) { range in
                    Text(range.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(selection == range ? Color.primary : Color.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            if selection == range {
                                Capsule()
                                    .fill(Color(.systemBackground))
                                    .matchedGeometryEffect(id: "statsRangePill", in: namespace)
                            }
                        }
                        .contentShape(Capsule())
                        .onTapGesture {
                            guard selection != range else { return }
                            withAnimation(.snappy(duration: 0.3)) {
                                selection = range
                            }
                        }
                }
            }
            .padding(3)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
        }
    }

    // MARK: - Helpers

    private func stampedDays(for pass: CommuterPass) -> [Bool] {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: now) else {
            return Array(repeating: false, count: 7)
        }

        return (0..<7).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else { return false }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return pass.stamps.contains { $0.date >= startOfDay && $0.date < endOfDay }
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
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

    private func addDummyJourney() {
        let allCompanies = store.fetchAllCompanies()
        let company: RailCompany
        if let existing = allCompanies.randomElement() {
            company = existing
        } else {
            company = store.createCompany(name: "Debug Rail", cardText: "._.")
        }

        let startPlace = PlaceNames.randomPlace()
        let endPlace = PlaceNames.randomPlace()
        let miles = Double.random(in: 5...100)
        let startTime = Date().addingTimeInterval(-Double.random(in: 0...86400 * 7))
        let duration = Double.random(in: 600...7200)
        let endTime = startTime.addingTimeInterval(duration)

        let result = JourneyResult(
            company: company,
            miles: miles,
            startTime: startTime,
            endTime: endTime,
            startPlace: startPlace.name,
            endPlace: endPlace.name
        )
        store.completeJourney(result)
        refreshData()
    }

    private func removeLastJourney() {
        if let last = recentJourneys.first {
            store.deleteJourney(last)
            refreshData()
        }
    }

    private func resetAllJourneys() {
        store.deleteAllJourneys()
        refreshData()
    }
    
   
}

// MARK: - Passes UI

struct HolographicPassBackground: View {
    @State private var animateGradient = false

    private let holoColors: [Color] = [
        Color(red: 0.55, green: 0.85, blue: 1.00),
        Color(red: 0.75, green: 0.60, blue: 1.00),
        Color(red: 1.00, green: 0.55, blue: 0.80),
        Color(red: 1.00, green: 0.80, blue: 0.55),
        Color(red: 0.55, green: 1.00, blue: 0.85),
    ]

    var body: some View {
        ZStack {
            Color.black

            GuillochePattern()
                .stroke(Color.white.opacity(0.045), lineWidth: 1)
                .drawingGroup()

            LinearGradient(
                colors: holoColors,
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .opacity(0.15)
            .blendMode(.normal)
            .hueRotation(.degrees(animateGradient ? 360 : 0))

            LinearGradient(
                colors: [.white.opacity(0.10), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.plusLighter)

            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear, Color.black.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateGradient)
                .onAppear {

                    animateGradient = true

        }
    }
}

struct GuillochePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 12
        var y: CGFloat = -spacing
        while y < rect.height + spacing {
            var p = Path()
            p.move(to: CGPoint(x: 0, y: y))
            let amplitude: CGFloat = 6
            let wavelength: CGFloat = 40
            var x: CGFloat = 0
            while x <= rect.width {
                let dy = sin((x / wavelength) * .pi * 2) * amplitude
                p.addLine(to: CGPoint(x: x, y: y + dy))
                x += 8
            }
            path.addPath(p)
            y += spacing
        }
        return path
    }
}

struct CommuterPassCard: View {
    let streak: Int
    let stampedDays: [Bool]

    private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        ZStack(alignment: .topLeading) {
            HolographicPassBackground()

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("COMMUTER PASS ")
                            .font(.system(.caption2).weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(streak) day streak")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(">>>")
                        .font(.system(.caption2).weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer(minLength: 4)

                HStack(spacing: 7) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(stampedDays[index] ? Color.white : Color.white.opacity(0.22))
                                .frame(width: 18, height: 18)
                                .overlay {
                                    if stampedDays[index] {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color.black)
                                    }
                                }
                            Text(dayLetters[index])
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            .padding(14)
        }
        .frame(width: 240, height: 110, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.05), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct PassCard: View {
    let title: String
    let cardText: String
    let subtitle: String
    let iconName: String
    let backgroundColor: Color
    let blockColor: Color
    let blockShape: CardBlockShape
    let blockPosition: CardBlockPosition
    let fontColor: Color

    var width: CGFloat = 150
    var height: CGFloat = 110

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundColor

            let size = max(width, height)

            Group {
                switch blockShape {
                case .circle:
                    Circle().fill(blockColor)
                case .square:
                    Rectangle().fill(blockColor)

                }
            }
            .frame(width: size, height: size)
            .position(blockCoordinates(for: blockPosition))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Spacer()
                    Image(systemName: "wave.3.forward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                Text(cardText)
                    .font(.system(size: 22))
                    .foregroundStyle(fontColor)
            }
            .padding(12)
        }
        .frame(width: width, height: height, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
      //  .compositingGroup()
        //   .drawingGroup()
    }

    private func blockCoordinates(for position: CardBlockPosition) -> CGPoint {
        switch position {
        case .top: return CGPoint(x: width / 2, y: 0)
        case .bottom: return CGPoint(x: width / 2, y: height)
        case .left: return CGPoint(x: 0, y: height / 2)
        case .right: return CGPoint(x: width, y: height / 2)
        }
    }
}

// MARK: - Stubs

struct Stub: View {
    let originCode: String
    let destinationCode: String
    let subtitle: String
    let operatorName: String

    private var seedString: String { originCode + destinationCode + operatorName }

    private var jitterDegrees: Double {
        let hash = seedString.hashValue
        let normalized = Double(abs(hash) % 1200) / 100.0
        return -5.0 + normalized
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                BarcodeShape(seed: seedString)
                    .frame(height: 18)
                    .foregroundStyle(.primary.opacity(0.65))

                HStack(spacing: 4) {
                    Text(originCode.uppercased())
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(destinationCode.uppercased())
                }
                .font(.system(.subheadline).weight(.bold))
                .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(operatorName.uppercased())
                    .font(.system(.caption2).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .frame(width: 132, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(14)
        .rotationEffect(.degrees(jitterDegrees))
    }
}

struct BarcodeShape: Shape {
    let seed: String

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var generator = SeededGenerator(seed: seed)
        let spacing: CGFloat = 2
        var currentX: CGFloat = 0

        while currentX < rect.width {
            let w: CGFloat = Bool.random(using: &generator) ? 2 : 1
            if currentX + w > rect.width { break }
            path.addRect(CGRect(x: currentX, y: 0, width: w, height: rect.height))
            currentX += w + spacing
        }
        return path
    }
}



struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: String) {
        state = seed.unicodeScalars.reduce(UInt64(1)) { $0 &+ UInt64($1.value) } &+ 1
    }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer()
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
