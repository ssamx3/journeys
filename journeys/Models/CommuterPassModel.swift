//
//  CommuterPassModel.swift
//  journeys
//
//  Created by sam on 12/07/2026.
//
import Foundation
import SwiftData

@Model
final class Stamp {
    var date: Date
    var pass: CommuterPass?
    init(date: Date) {
        self.date = date
    }
}

@Model
final class CommuterPass {
    var streakWeeks: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \Stamp.pass)
    var stamps: [Stamp] = []
    var stampsEver: Int { stamps.count }
    var stampsLast7Days: Int {
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return stamps.filter { $0.date >= sevenDaysAgo }.count
        }
    var currentWeekQualifying: Bool {
        stampsLast7Days >= 5
    }
    var milestone: CommuterPassMilestone {
        CommuterPassMilestone.reached(forStreakWeeks: streakWeeks)
    }
    var lastEvaluatedWeekEnd: Date?
        
        init() {
            self.stamps = []
        }
    }

enum CommuterPassMilestone: Int, Codable, CaseIterable, Comparable {
    case none = 0
    case week1 = 7
    case month1 = 30
    case month2 = 60
    case month4 = 120
    case year1 = 365
    case year2 = 730
    
    var streakDays: Int { rawValue }
    
    static func < (lhs: CommuterPassMilestone, rhs: CommuterPassMilestone) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    static func reached(forStreakWeeks weeks: Int) -> CommuterPassMilestone {
        let days = weeks * 7
        return CommuterPassMilestone.allCases
            .filter { $0.streakDays <= days }
            .max() ?? .none
    }
}
