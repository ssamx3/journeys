import SwiftUI

struct StatsDetailView: View {
    let store: JourneyStore
    @Binding var isPresented: Bool

    @State private var appearPhase: Double = 0

    @State private var allJourneys: [Journey] = []

    @State private var selectedOperator: String? = nil
    @State private var selectedRange: StatsDateRange = .week

    @State private var showingOperatorPicker = false
    @State private var showingRangePicker = false

    @State private var pendingOperator: String? = nil
    @State private var pendingRange: StatsDateRange = .week

    @State private var statsSnapshot = StatsSnapshot(miles: 0, timeLabel: "0m", topOperator: "-", personalBestMiles: 0, journeysCount: 0)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .opacity(appearPhase)

            VStack(spacing: 0) {
                header

                filterBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            FixedStatTile(value: "\(statsSnapshot.miles)", label: "miles travelled")
                            FixedStatTile(value: statsSnapshot.timeLabel, label: "time travelling")
                        }
                        HStack(spacing: 10) {
                            if selectedOperator == nil {
                                FixedStatTile(value: statsSnapshot.topOperator, label: "most used operator")
                            } else {
                                FixedStatTile(value: "\(statsSnapshot.journeysCount)", label: "journeys taken")
                            }
                            FixedStatTile(value: "\(statsSnapshot.personalBestMiles) miles", label: "personal best journey")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
            .opacity(appearPhase)
            .offset(y: 12 * (1 - appearPhase))
        }
        .onAppear {
            refresh()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                appearPhase = 1
            }
        }
        .sheet(isPresented: $showingOperatorPicker) {
            operatorPickerSheet
        }
        .sheet(isPresented: $showingRangePicker) {
            rangePickerSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer().frame(width: 30, height: 30)

            Spacer()

            Text("Stats")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
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
    }

    private func closeView() {
        withAnimation(.easeOut(duration: 0.22)) {
            appearPhase = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            Button {
                pendingOperator = selectedOperator
                showingOperatorPicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(selectedOperator ?? "Operator")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                }
            }
            .buttonStyle(.appChip(selected: selectedOperator != nil))

            Button {
                pendingRange = selectedRange
                showingRangePicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(selectedRange.label)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                }
            }
            .buttonStyle(.appChip(selected: selectedRange != .all))

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .opacity(appearPhase)
    }

    private var operatorNames: [String] {
        let names = Set(allJourneys.map { $0.company.name })
        return names.sorted()
    }

    // MARK: - Native picker sheets

    private var operatorPickerSheet: some View {
        NativePickerSheet(title: "Operator") {
            Picker("Operator", selection: $pendingOperator) {
                Text("All operators").tag(String?.none)
                ForEach(operatorNames, id: \.self) { name in
                    Text(name).tag(String?.some(name))
                }
            }
            .pickerStyle(.wheel)
        } onDone: {
            withAnimation(.snappy(duration: 0.25)) {
                selectedOperator = pendingOperator
            }
            showingOperatorPicker = false
            updateStats()
        } onCancel: {
            showingOperatorPicker = false
        }
    }

    private var rangePickerSheet: some View {
        NativePickerSheet(title: "Time Period") {
            Picker("Time period", selection: $pendingRange) {
                ForEach(StatsDateRange.allCases, id: \.self) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.wheel)
        } onDone: {
            withAnimation(.snappy(duration: 0.25)) {
                selectedRange = pendingRange
            }
            showingRangePicker = false
            updateStats()
        } onCancel: {
            showingRangePicker = false
        }
    }

    // MARK: - Data

    private func refresh() {
        allJourneys = store.fetchAllJourneys()
        updateStats()
    }

    private func updateStats() {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch selectedRange {
        case .all:
            startDate = .distantPast
        case .day:
            startDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .day, value: -365, to: now) ?? now
        }
        
        var journeys = store.fetchJourneys(from: startDate)

        if let operatorName = selectedOperator {
            journeys = journeys.filter { $0.company.name == operatorName }
        }

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
                personalBestMiles: Int(personalBest),
                journeysCount: journeys.count
            )
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

    // MARK: - Stats Snapshot

    private struct StatsSnapshot {
        let miles: Int
        let timeLabel: String
        let topOperator: String
        let personalBestMiles: Int
        let journeysCount: Int
    }
}

// MARK: - Fixed Stat Tile

private struct FixedStatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .fontDesign(.rounded)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)

            Text(label)
                .fontDesign(.rounded)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Date range filter (stats-specific)

private enum StatsDateRange: CaseIterable {
    case all, day, week, month, year

    var label: String {
        switch self {
        case .all: return "All time"
        case .day: return "Past 24 hours"
        case .week: return "Past week"
        case .month: return "Past month"
        case .year: return "Past year"
        }
    }

    func contains(_ date: Date) -> Bool {
        switch self {
        case .all:
            return true
        case .day:
            return date >= Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .distantPast
        case .week:
            return date >= Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        case .month:
            return date >= Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        case .year:
            return date >= Calendar.current.date(byAdding: .day, value: -365, to: .now) ?? .distantPast
        }
    }
}

#Preview {
    StatsDetailView(store: .preview, isPresented: .constant(true))
}


