import SwiftUI

struct StubBookView: View {
    let store: JourneyStore
    @Binding var isPresented: Bool

    @State private var appearPhase: Double = 0

    @State private var allJourneys: [Journey] = []
    @State private var selectedJourney: Journey?

    @State private var selectedOperator: String? = nil
    @State private var selectedRange: StubDateRange = .all

    @State private var showingOperatorPicker = false
    @State private var showingRangePicker = false

    @State private var pendingOperator: String? = nil
    @State private var pendingRange: StubDateRange = .all

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .opacity(appearPhase)

            VStack(spacing: 0) {
                header

                filterBar

                if filteredJourneys.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredJourneys.sorted(by: { $0.startTime > $1.startTime })) { journey in
                                StubBookRow(journey: journey)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            selectedJourney = journey
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .opacity(selectedJourney != nil ? 0 : appearPhase)
            .offset(y: 12 * (1 - appearPhase))
            .animation(.easeOut(duration: 0.2), value: selectedJourney != nil)

            if let journey = selectedJourney {
                StubDetailView(journey: journey, selectedJourney: $selectedJourney)
                    .zIndex(2)
                    .transition(.opacity)
            }
        }
        .onAppear {
            refresh()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                appearPhase = 1
            }
        }
        .onChange(of: selectedJourney) { _, newValue in
            if newValue == nil { refresh() }
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

            Text("Stub Book")
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
                    Text(selectedRange == .all ? "Time period" : selectedRange.label)
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
        } onCancel: {
            showingOperatorPicker = false
        }
    }

    private var rangePickerSheet: some View {
        NativePickerSheet(title: "Time Period") {
            Picker("Time period", selection: $pendingRange) {
                ForEach(StubDateRange.allCases, id: \.self) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.wheel)
        } onDone: {
            withAnimation(.snappy(duration: 0.25)) {
                selectedRange = pendingRange
            }
            showingRangePicker = false
        } onCancel: {
            showingRangePicker = false
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "ticket")
                .font(.system(size: 34))
                .foregroundStyle(.tertiary)
            Text(allJourneys.isEmpty ? "No stubs yet" : "No stubs match your filters")
                .font(.subheadline.weight(.medium))
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(appearPhase)
    }

    // MARK: - Filtering

    private var filteredJourneys: [Journey] {
        allJourneys.filter { journey in
            let matchesOperator = selectedOperator == nil || journey.company.name == selectedOperator
            let matchesRange = selectedRange.contains(journey.startTime)
            return matchesOperator && matchesRange
        }
    }

    // MARK: - Data

    private func refresh() {
        allJourneys = store.fetchAllJourneys()
    }
}

// MARK: - Native picker sheet wrapper

struct NativePickerSheet<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    let onDone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: onDone)
                            .fontWeight(.semibold)
                    }
                }
        }
        .presentationDetents([.height(280)])
    }
}

// MARK: - Date range filter

private enum StubDateRange: CaseIterable {
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

// MARK: - Stub Book Row (card-based, matches app design)

private struct StubBookRow: View {
    let journey: Journey

    private var originCode: String {
        PlaceNames.byName[journey.startPlace]?.code ?? "UNK"
    }

    private var destinationCode: String {
        PlaceNames.byName[journey.endPlace]?.code ?? "UNK"
    }

    private var seedString: String { originCode + destinationCode + journey.company.name }

    private var jitterDegrees: Double {
        let hash = seedString.hashValue
        let normalized = Double(abs(hash) % 1200) / 100.0
        return -5.0 + normalized
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                BarcodeShape(seed: seedString)
                    .frame(height: 18)
                    .foregroundStyle(.primary.opacity(0.65))

                HStack(spacing: 4) {
                    Text(originCode.uppercased())
                        .fontDesign(.rounded)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(destinationCode.uppercased())
                        .fontDesign(.rounded)
                }
                .font(.system(.subheadline).weight(.bold))
                .foregroundStyle(.primary)

                Text(formatDuration(journey.endTime.timeIntervalSince(journey.startTime)))
                    .fontDesign(.rounded)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(journey.company.name.uppercased())
                    .fontDesign(.rounded)
                    .font(.system(.caption2).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(width: 140, alignment: .leading)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(14)
            .rotationEffect(.degrees(jitterDegrees))

            // Journey details
            VStack(alignment: .leading, spacing: 4) {
                Text(journey.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)

                Text("\(Int(journey.miles)) miles")
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)

                Text(journey.company.name)
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
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

#Preview {
    StubBookView(store: .preview, isPresented: .constant(true))
}
