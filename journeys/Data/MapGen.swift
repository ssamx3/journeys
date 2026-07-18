import Foundation
import CoreGraphics


struct MapNode: Identifiable {
    let id = UUID()
    let name: String
    let position: CGPoint
}

struct MapPath: Identifiable {
    let id = UUID()
    let destination: MapNode
    let waypoints: [CGPoint]
    let isSelectable: Bool

    let lineColor: MapLineColor
}

enum MapLineColor: CaseIterable {
    case blue, amber, green, red, teal, grey
}

struct MapLayout {
    let centreNode: MapNode
    let paths: [MapPath]
}

enum Direction {
    case north, south, east, west

    var vector: (Double, Double) {
        switch self {
        case .north: return (0, -1)
        case .south: return (0, 1)
        case .east:  return (1, 0)
        case .west:  return (-1, 0)
        }
    }
}

class MapGenerator {

    private static let guaranteedOffscreenMagnitude: Double = 2.6

    private struct ArmPlan {
        let name: String
        let destX: Double
        let destY: Double
        let lineColor: MapLineColor
        let isStraight: Bool
        var cornerIsHorizontalFirst: Bool
    }

    static func generateNewMap() -> MapLayout {
        var shuffledNames = PlaceNames.all.shuffled()
        let centreName = shuffledNames.removeFirst()
        let centreNode = MapNode(name: centreName, position: CGPoint(x: 0, y: 0))

        let angles: [Double] = [
            Double.random(in: 30 ... 60),   //TR
            Double.random(in: 120 ... 150), //TL
            Double.random(in: 210 ... 240), //BL
            Double.random(in: 300 ... 330)  //BR
        ]

        // MARK:
        var linesColours = MapLineColor.allCases
        var plans: [ArmPlan] = []
        for i in 0..<4 {
            let name = shuffledNames.removeFirst()
            let angleInRad = angles[i] * .pi / 180.0
            let distance = Double.random(in: 0.5 ... 1.2)
            let destX = distance * cos(angleInRad)
            let destY = distance * sin(angleInRad)
            let lineColor = linesColours.first ?? .blue
            linesColours.removeFirst()
            let straightPathChance = 0.55
            let isStraight = Double.random(in: 0...1) < straightPathChance

            plans.append(ArmPlan(
                name: name,
                destX: destX,
                destY: destY,
                lineColor: lineColor,
                isStraight: isStraight,
                cornerIsHorizontalFirst: Bool.random()
            ))
        }

        // MARK: De symbol
        breakRotationalSymmetry(&plans)

        // MARK: 
        var paths: [MapPath] = []
        for plan in plans {
            let destNode = MapNode(name: plan.name, position: CGPoint(x: plan.destX, y: plan.destY))

            let waypoints: [CGPoint]
            let finalDirection: Direction

            if plan.isStraight {
                waypoints = [
                    CGPoint(x: 0.0, y: 0.0),
                    CGPoint(x: plan.destX, y: plan.destY)
                ]
                finalDirection = abs(plan.destX) > abs(plan.destY)
                    ? (plan.destX > 0 ? .east : .west)
                    : (plan.destY > 0 ? .south : .north)
            } else {
                let cornerX = plan.cornerIsHorizontalFirst ? plan.destX * 0.5 : 0.0
                let cornerY = plan.cornerIsHorizontalFirst ? 0.0 : plan.destY * 0.5
                let cornerPoint = CGPoint(x: cornerX, y: cornerY)

                waypoints = [
                    CGPoint(x: 0.0, y: 0.0),
                    cornerPoint,
                    CGPoint(x: plan.destX, y: plan.destY)
                ]
                finalDirection = plan.cornerIsHorizontalFirst
                    ? (plan.destY > cornerY ? .south : .north)
                    : (plan.destX > cornerX ? .east : .west)
            }

            paths.append(MapPath(destination: destNode, waypoints: waypoints, isSelectable: true, lineColor: plan.lineColor))
            paths.append(makeContinuation(from: destNode.position, direction: finalDirection, lineColor: plan.lineColor))
        }

        return MapLayout(centreNode: centreNode, paths: paths)
    }


    private static func turnSign(for plan: ArmPlan) -> Int {
        guard !plan.isStraight else { return 0 }
        let cornerX = plan.cornerIsHorizontalFirst ? plan.destX * 0.5 : 0.0
        let cornerY = plan.cornerIsHorizontalFirst ? 0.0 : plan.destY * 0.5
        let cross = cornerX * (plan.destY - cornerY) - cornerY * (plan.destX - cornerX)
        return cross > 0 ? 1 : (cross < 0 ? -1 : 0)
    }

    private static func breakRotationalSymmetry(_ plans: inout [ArmPlan]) {
        func signCounts() -> (clockwise: [Int], counter: [Int]) {
            var cw: [Int] = []
            var ccw: [Int] = []
            for (index, plan) in plans.enumerated() {
                switch turnSign(for: plan) {
                case 1: cw.append(index)
                case -1: ccw.append(index)
                default: break
                }
            }
            return (cw, ccw)
        }

        var (cw, ccw) = signCounts()
        while cw.count >= 3 || ccw.count >= 3 {
            let dominant = cw.count >= ccw.count ? cw : ccw
            guard let indexToFlip = dominant.randomElement() else { break }
            plans[indexToFlip].cornerIsHorizontalFirst.toggle()
            (cw, ccw) = signCounts()
        }
    }

    private static func makeContinuation(from destination: CGPoint, direction: Direction, lineColor: MapLineColor) -> MapPath {
        let endpoint: CGPoint
        switch direction {
        case .east:  endpoint = CGPoint(x: guaranteedOffscreenMagnitude, y: destination.y)
        case .west:  endpoint = CGPoint(x: -guaranteedOffscreenMagnitude, y: destination.y)
        case .south: endpoint = CGPoint(x: destination.x, y: guaranteedOffscreenMagnitude)
        case .north: endpoint = CGPoint(x: destination.x, y: -guaranteedOffscreenMagnitude)
        }

        let phantomNode = MapNode(name: "", position: endpoint)
        return MapPath(destination: phantomNode, waypoints: [destination, endpoint], isSelectable: false, lineColor: lineColor)
    }
}
