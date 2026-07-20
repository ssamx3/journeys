//
//  JourneyStore.swift
//  journeys
//
//  Created by sam on 13/07/2026.
//

import Observation
import SwiftData
import Foundation

@Observable
final class JourneyStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Journeys
    func completeJourney(_ result: JourneyResult) {
        let journey = Journey(company: result.company, miles: result.miles, startTime: result.startTime, endTime: result.endTime, startPlace: result.startPlace, endPlace: result.endPlace)
        context.insert(journey)
        result.company.totalMiles += result.miles
        result.company.totalTimeTravelled += result.endTime.timeIntervalSince(result.startTime)
        result.company.level = level(forTotalMiles: result.company.totalMiles)

        let duration = result.endTime.timeIntervalSince(result.startTime)
        if duration >= 20 * 60 {
            awardStamp()
        }
    }

    func deleteJourney(_ journey: Journey) {
        journey.company.totalMiles -= journey.miles
        journey.company.totalTimeTravelled -= journey.endTime.timeIntervalSince(journey.startTime)
        journey.company.level = level(forTotalMiles: journey.company.totalMiles)
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
            level: .bronze,
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

    func currentStreakStatus() -> (stampsThisWeek: Int, streakWeeks: Int, milestone: CommuterPassMilestone) {
        let pass = fetchOrCreateCommuterPass()
        evaluateStreak(for: pass)
        return (pass.stampsLast7Days, pass.streakWeeks, pass.milestone)
    }

    private func level(forTotalMiles miles: Double) -> RailPassLevel {
        switch miles {
        case ..<50:      return .bronze
        case 50..<150:   return .silver
        case 150..<350:  return .gold
        case 350..<700:  return .platinum
        default:         return .titanium
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

       
        
        return store
    }
}
