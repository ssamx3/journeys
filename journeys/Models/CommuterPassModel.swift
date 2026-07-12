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
    var companyName: RailCompany
    var pass: CommuterPass?
    init(date: Date, companyName: RailCompany) {
        self.date = date
        self.companyName = companyName
    }
}

@Model
final class CommuterPass {
    @Relationship(deleteRule: .cascade, inverse: \Stamp.pass)
    var stamps: [Stamp] = []
    var stampsEver: Int { stamps.count }
    var stampsLast7Days: Int {
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return stamps.filter { $0.date >= sevenDaysAgo }.count
        }
        
        init() {
            self.stamps = []
        }
    }


