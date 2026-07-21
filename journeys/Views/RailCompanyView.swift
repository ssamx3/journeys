//
//  RailCompanyView.swift
//  journeys
//

import SwiftUI
import SwiftData

struct RailCompanyView: View {
    let store: JourneyStore
    let company: RailCompany
    var namespace: Namespace.ID

    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    // Animated stat values
    @State private var animatedMiles: Double = 0
    @State private var animatedTime: TimeInterval = 0
    @State private var animatedJourneys: Int = 0
    @State private var hasAppeared = false

    private var journeys: [Journey] {
        store.fetchJourneys(for: company)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        heroSection
                        statsSection
                        journeysSection
                        actionsSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(company.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEditSheet, onDismiss: animateStatsIn) {
                CreatePassView(store: store, company: company)
            }
            .alert("Delete \(company.name)?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    store.deleteCompany(company)
                    dismiss()
                }
            } message: {
                Text("This will permanently delete this RailPass and all associated journeys.")
            }
            .onAppear(perform: animateStatsIn)
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PassCard(
                title: company.name,
                cardText: company.cardText,
                subtitle: company.level.rawValue.capitalized,
                iconName: "train.fill",
                backgroundColor: company.backgroundColor,
                blockColor: company.blockColor,
                blockShape: company.blockShape,
                blockPosition: company.blockPosition,
                fontColor: company.fontColor,
                width: UIScreen.main.bounds.width - 64,
                height: 140
            )
            .matchedGeometryEffect(id: company.persistentModelID, in: namespace)

            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(company.level.themeColor)
                Text("\(company.level.rawValue.capitalized) Tier")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .padding(.top)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatTile(
                        value: hasAppeared ? "\(Int(animatedMiles))" : "0",
                        label: "miles travelled"
                    )
                    StatTile(
                        value: hasAppeared ? formatTime(animatedTime) : "0m",
                        label: "time spent"
                    )
                }
                HStack(spacing: 10) {
                    StatTile(
                        value: hasAppeared ? "\(animatedJourneys)" : "0",
                        label: "journeys taken"
                    )
                    StatTile(
                        value: company.level.rawValue.capitalized,
                        label: "loyalty level"
                    )
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
                Button {
                    showingEditSheet = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit RailPass")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .foregroundStyle(.primary)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete RailPass")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

    // MARK: - Animation

    private func animateStatsIn() {
        let targetMiles = company.totalMiles
        let targetTime = company.totalTimeTravelled
        let targetJourneys = journeys.count

        animatedMiles = 0
        animatedTime = 0
        animatedJourneys = 0
        hasAppeared = false

        withAnimation(.easeOut(duration: 1.2)) {
            animatedMiles = targetMiles
            animatedTime = targetTime
            animatedJourneys = targetJourneys
            hasAppeared = true
        }
    }

    // MARK: - Helpers

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
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
        if minutes < 60 {
            return "\(minutes)m"
        } else {
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