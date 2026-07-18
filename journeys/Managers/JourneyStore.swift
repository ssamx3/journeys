//
//  FileManager.swift
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
        
        save()

    }
    
    func deleteJourney(_ journey: Journey) {
        context.delete(journey)
        save()
    }
    
    func fetchAllJourneys() -> [Journey] {
        let descriptor = FetchDescriptor<Journey>(
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
    
    func createCompany(name: String, callsign: String) -> RailCompany {
        let company = RailCompany(name: name, callSign: callsign, totalMiles: 0, totalTimeTravelled: 0, level: .bronze)
        context.insert(company)
        save()
        return company
    }
    
    func fetchAllCompanies() -> [RailCompany] {
        let descriptor = FetchDescriptor<RailCompany>(
                    sortBy: [SortDescriptor(\.name)]
                )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func deleteCompany(_ company: RailCompany) {
        for journey in fetchJourneys(for: company) {
            context.delete(journey)
        }
        context.delete(company)
        save()
    }
    

    // MARK: Commuter Pass
    
    
    func fetchOrCreateCommuterPass() -> CommuterPass {
        let descriptor = FetchDescriptor<CommuterPass>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let pass = CommuterPass()
        context.insert(pass)
        save()
        return pass
    }
    
    func awardStamp() {
        let pass = fetchOrCreateCommuterPass()
        let stamp = Stamp(date: .now)
        stamp.pass = pass
        pass.stamps.append(stamp)
        context.insert(stamp)
        
        evaluateStreak(for: pass)
        
        save()
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
        save()
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
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Save failed. \(error)")
        }
    }
}
