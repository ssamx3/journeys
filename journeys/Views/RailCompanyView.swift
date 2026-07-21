import SwiftUI
import SwiftData

struct RailCompanyView: View {
    let store: JourneyStore
    let company: RailCompany
    @Binding var selectedCompany: RailCompany?

    @State private var appearPhase: Double = 0
    @State private var revealValues = false
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    let journeys: [Journey]

    var body: some View {
        ZStack {
            // Background materializes
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .opacity(appearPhase)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Close button
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
                        journeysSection
                        actionsSection
                    }
                    .opacity(appearPhase)
                    .offset(y: 16 * (1 - appearPhase))
                }
                .padding(.horizontal)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            CreatePassView(store: store, company: company)
        }
        .alert("Delete \(company.name)?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                store.deleteCompany(company)
                closeView()
            }
        } message: {
            Text("This will permanently delete this RailPass and all associated journeys.")
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
            selectedCompany = nil
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 10) {
            ZStack {

                Circle()
                    .fill(company.backgroundColor)
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .opacity(0.35)

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
                .frame(width: 180, height: 130)
            }
            .scaleEffect(0.88 + (0.12 * appearPhase))
            .opacity(appearPhase)

            VStack(spacing: 2) {
                Text(company.name)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text(company.level.rawValue.capitalized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .opacity(appearPhase)
            .offset(y: 6 * (1 - appearPhase))
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatTile2(
                        value: revealValues ? "\(Int(company.totalMiles))" : "0",
                        label: "miles travelled"
                    )
                    StatTile2(
                        value: revealValues ? formatTime(company.totalTimeTravelled) : "0m",
                        label: "time spent"
                    )
                }
                HStack(spacing: 10) {
                    StatTile2(
                        value: revealValues ? "\(journeys.count)" : "0",
                        label: "journeys taken"
                    )

                    if let next = company.nextTier {
                        StatTile2(
                            value: revealValues ? "\(Int(company.milesToNextTier))" : "0",
                            label: "mi to \(next.rawValue.capitalized)",
                            progress: revealValues ? company.tierProgress : 0,
                            tint: next.themeColor
                        )
                    } else {
                        StatTile2(
                            value: "Max",
                            label: "tier reached",
                            tint: company.level.themeColor
                        )
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var journeysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("recent journeys")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(journeys.count) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if journeys.isEmpty {
                Text("No journeys yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(journeys.prefix(5)) { journey in
                        JourneyRow(journey: journey)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("actions")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                Button { showingEditSheet = true } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit RailPass")
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .foregroundStyle(.primary)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button { showingDeleteConfirmation = true } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete RailPass")
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .foregroundStyle(.red)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        if hours > 0 { return "\(hours)h \(minutes)m" } else { return "\(minutes)m" }
    }
}

// MARK: - Stat Tile
struct StatTile2: View {
    let value: String
    let label: String
    var progress: Double? = nil
    var tint: Color = .pink

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer()
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: value)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let progress {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))

                    GeometryReader { geo in
                        Capsule()
                            .fill(tint)
                            .frame(width: max(4, geo.size.width * progress))
                    }
                }
                .frame(height: 4)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Journey Row
private struct JourneyRow: View {
    let journey: Journey

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(PlaceNames.byName[journey.startPlace]?.code ?? "UNK")
                        .font(.system(.subheadline).weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(PlaceNames.byName[journey.endPlace]?.code ?? "UNK")
                        .font(.system(.subheadline).weight(.bold))
                }
                Text(formatDuration(journey.endTime.timeIntervalSince(journey.startTime)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(journey.miles)) mi")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes < 60 { return "\(minutes)m" } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}

// MARK: - Level Theme Color
extension RailPassLevel {
    var themeColor: Color {
        switch self {
        case .bronze:    return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver:    return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .gold:      return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum:  return Color(red: 0.9, green: 0.9, blue: 0.95)
        case .titanium:  return Color(red: 0.5, green: 0.5, blue: 0.55)
        }
    }
}
