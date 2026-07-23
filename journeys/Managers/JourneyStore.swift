//
//  JourneyStore.swift
//  journeys
//
//  Created by sam on 13/07/2026.
//

import Observation
import SwiftData
import Foundation


struct JourneyCompletionOutcome {
    let stampAwarded: Bool
    let isFirstStampToday: Bool
    let streakWeeks: Int
    let dayStreak: Int
    let milestone: CommuterPassMilestone
}

@Observable
final class JourneyStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Journeys


    @discardableResult
    func completeJourney(_ result: JourneyResult) -> JourneyCompletionOutcome {
        let journey = Journey(company: result.company, miles: result.miles, startTime: result.startTime, endTime: result.endTime, startPlace: result.startPlace, endPlace: result.endPlace)
        context.insert(journey)
        result.company.totalMiles += result.miles
        result.company.totalTimeTravelled += result.endTime.timeIntervalSince(result.startTime)

        let duration = result.endTime.timeIntervalSince(result.startTime)
        guard duration >= 15 * 60 else {
            let status = currentStreakStatus()
            return JourneyCompletionOutcome(
                stampAwarded: false,
                isFirstStampToday: false,
                streakWeeks: status.streakWeeks,
                dayStreak: status.dayStreak,
                milestone: status.milestone
            )
        }

        let pass = fetchOrCreateCommuterPass()
        let wasFirstToday = !hasStampToday(pass)

        awardStamp()

        let status = currentStreakStatus()
        return JourneyCompletionOutcome(
            stampAwarded: true,
            isFirstStampToday: wasFirstToday,
            streakWeeks: status.streakWeeks,
            dayStreak: status.dayStreak,
            milestone: status.milestone
        )
    }

    private func hasStampToday(_ pass: CommuterPass) -> Bool {
        let calendar = Calendar.current
        return pass.stamps.contains { calendar.isDateInToday($0.date) }
    }

    func deleteJourney(_ journey: Journey) {
        journey.company.totalMiles -= journey.miles
        journey.company.totalTimeTravelled -= journey.endTime.timeIntervalSince(journey.startTime)

        context.delete(journey)
    }

    func fetchRecentJourneys(limit: Int = 10) -> [Journey] {
        var descriptor = FetchDescriptor<Journey>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchJourneys(from startDate: Date) -> [Journey] {
        let descriptor = FetchDescriptor<Journey>(
            predicate: #Predicate { $0.startTime >= startDate },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchJourneys(for company: RailCompany) -> [Journey] {
        let id = company.persistentModelID
        let descriptor = FetchDescriptor<Journey>(
            predicate: #Predicate { $0.company.persistentModelID == id },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: Rail Company

    func createCompany(
        name: String,
        cardText: String,
        backgroundColorHex: String = "007AFF",
        blockColorHex: String = "FF2D55",
        blockShapeRaw: String = "circle",
        blockPositionRaw: String = "bottom",
        fontColorHex: String = "FFFFFF"
    ) -> RailCompany {
        let company = RailCompany(
            name: name,
            cardText: cardText,
            totalMiles: 0,
            totalTimeTravelled: 0,
            backgroundColorHex: backgroundColorHex,
            blockColorHex: blockColorHex,
            blockShapeRaw: blockShapeRaw,
            blockPositionRaw: blockPositionRaw,
            fontColorHex: fontColorHex
        )
        context.insert(company)
        return company
    }

    func fetchAllCompanies() -> [RailCompany] {
        let descriptor = FetchDescriptor<RailCompany>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func deleteCompany(_ company: RailCompany) {
        context.delete(company)
    }

    // MARK: Commuter Pass

    func fetchOrCreateCommuterPass() -> CommuterPass {
        let descriptor = FetchDescriptor<CommuterPass>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let pass = CommuterPass()
        context.insert(pass)
        return pass
    }

    func awardStamp() {
        let pass = fetchOrCreateCommuterPass()
        let stamp = Stamp(date: .now)
        stamp.pass = pass
        pass.stamps.append(stamp)
        context.insert(stamp)

        evaluateStreak(for: pass)
    }

    private func evaluateStreak(for pass: CommuterPass) {
        let calendar = Calendar.current
        let now = Date.now
        guard let lastWeekEnd = pass.lastEvaluatedWeekEnd else {
            pass.lastEvaluatedWeekEnd = calendar.date(byAdding: .day, value: 7, to: now)
            pass.streakWeeks = pass.currentWeekQualifying ? 1 : 0
            return
        }
        var windowEnd = lastWeekEnd
        while windowEnd <= now {
            let windowStart = calendar.date(byAdding: .day, value: -7, to: windowEnd) ?? windowEnd
            let stampsInWindow = pass.stamps.filter { $0.date >= windowStart && $0.date < windowEnd }.count

            if stampsInWindow >= 5 {
                pass.streakWeeks += 1
            } else {
                pass.streakWeeks = 0
            }

            windowEnd = calendar.date(byAdding: .day, value: 7, to: windowEnd) ?? now.addingTimeInterval(1)
        }

        pass.lastEvaluatedWeekEnd = windowEnd
    }

    func currentStreakStatus() -> (stampsThisWeek: Int, streakWeeks: Int, dayStreak: Int, milestone: CommuterPassMilestone) {
        let pass = fetchOrCreateCommuterPass()
        evaluateStreak(for: pass)
        let dayStreak = computeDayStreak(for: pass)
        return (pass.stampsLast7Days, pass.streakWeeks, dayStreak, pass.milestone)
    }


    private func computeDayStreak(for pass: CommuterPass) -> Int {
        let calendar = Calendar.current
        let stamps = pass.stamps
        guard !stamps.isEmpty else { return 0 }

        var stampDates = Set<Date>()
        for stamp in stamps {
            let startOfDay = calendar.startOfDay(for: stamp.date)
            stampDates.insert(startOfDay)
        }

        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today

        while stampDates.contains(currentDate) {
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDate
        }

        return streak
    }

    func deleteAllJourneys() {
        let allJourneys = (try? context.fetch(FetchDescriptor<Journey>())) ?? []
        for journey in allJourneys {
            context.delete(journey)
        }
        for company in fetchAllCompanies() {
            company.totalMiles = 0
            company.totalTimeTravelled = 0
        }
    }
}

extension JourneyStore {
    @MainActor
    static var preview: JourneyStore {
        let schema = Schema([
            Journey.self,
            RailCompany.self,
            CommuterPass.self,
            Stamp.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])

        let store = JourneyStore(context: container.mainContext)


        _ = store.createCompany(
            name: "Northline Rail",
            cardText: "NORTHLINE",
            backgroundColorHex: "007AFF",
            blockColorHex: "FF2D55",
            blockShapeRaw: "circle",
            blockPositionRaw: "bottom",
            fontColorHex: "FFFFFF"
        )
        _ = store.createCompany(
            name: "Coastal Express",
            cardText: "COASTAL",
            backgroundColorHex: "34C759",
            blockColorHex: "FFCC00",
            blockShapeRaw: "square",
            blockPositionRaw: "top",
            fontColorHex: "FFFFFF"
        )
        _ = store.createCompany(
            name: "Midland Connect",
            cardText: "MIDLAND",
            backgroundColorHex: "AF52DE",
            blockColorHex: "FF9500",
            blockShapeRaw: "triangle",
            blockPositionRaw: "trailing",
            fontColorHex: "FFFFFF"
        )

        return store
    }
}
