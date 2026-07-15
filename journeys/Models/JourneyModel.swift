import Foundation
import SwiftData

@Model
final class Journey {
    var company: RailCompany
    var miles: Double
    var startTime: Date
    var endTime: Date
    var startPlace: String
    var endPlace: String
    
    init(company: RailCompany, miles: Double, startTime: Date, endTime: Date, startPlace: String, endPlace: String) {
        self.company = company
        self.miles = miles
        self.startTime = startTime
        self.endTime = endTime
        self.startPlace = startPlace
        self.endPlace = endPlace
    }
    
}
