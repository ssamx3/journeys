import SwiftUI
import UIKit


struct JourneyHomeView: View {
    @State private var layout: MapLayout = MapGenerator.generateNewMap()
    @State private var selectedNodeID: MapNode.ID?
    @State private var sheetDetent: PresentationDetent = .height(120)
    

    var body: some View {
        MapCanvasView(layout: layout, selectedNodeID: $selectedNodeID, onSelect: { id in selectedNodeID = id})
            .ignoresSafeArea()

            .sheet(isPresented: .constant(true)) {
                JourneySheetView(selectedNodeID: selectedNodeID)
                    .presentationDetents([.height(80), .height(120), .medium], selection: $sheetDetent)

                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
                    .presentationCornerRadius(24)
            }
    }
}

struct MapCanvasView: View {
    let layout: MapLayout
    @Binding var selectedNodeID: MapNode.ID?
    let onSelect: (MapNode.ID) -> Void

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            ZStack {
                Group {
                    ForEach(layout.paths) { path in
                        linePath(path, in: size)
                            .stroke(
                                color(for: path.lineColor),
                                style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                            )
                            .opacity(opacity(for: path))
                    }
                }
                .mask(topFadeGradient)
                .mask(bottomGrad)
                nodeView(for: layout.centreNode, in: size, isCentre: true)
                ForEach(layout.paths.filter(\.isSelectable)) { path in
                    nodeView(for: path.destination, in: size, isCentre: false)
                }
            }
        }
    }

    // MARK: - Top fade mask

    private var topFadeGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .black, location: 0.06),
                .init(color: .black, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var bottomGrad: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .black, location: 0.06),
                .init(color: .black, location: 1.0)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    // MARK: - Coordinate projection

    private func project(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let originX = size.width / 2
        let originY = size.height / 2
        let scale = min(size.width, size.height) / 2 * 0.85

        return CGPoint(
            x: originX + point.x * scale,
            y: originY + point.y * scale
        )
    }

    private func linePath(_ path: MapPath, in size: CGSize) -> Path {
        let projected = path.waypoints.map { project($0, in: size) }
            return roundedPath(through: projected, cornerRadius: 20)
    }
    
    private func roundedPath(through points: [CGPoint], cornerRadius: CGFloat) -> Path {
        Path { p in
            guard let first = points.first else {return}
            p.move(to: first)
            
            guard points.count > 2 else {
                if let last = points.last {
                    p.addLine(to: last)
                }
                return
            }
            
            for i in 1..<points.count - 1 {
                let previous = points[i - 1]
                let corner = points[i]
                let next = points[i + 1]
                
                let v1 = CGVector(dx: corner.x - previous.x, dy: corner.y - previous.y)
                let v2 = CGVector(dx: next.x - corner.x, dy: next.y - corner.y)
                
                let len1 = hypot(v1.dx, v1.dy)
                let len2 = hypot(v2.dx, v2.dy)
                let r = min(cornerRadius, len1 / 2, len2 / 2)
                
                let cutInPoint = CGPoint(x: corner.x - (v1.dx / len1) * r, y: corner.y - (v1.dy / len1) * r)
                //let cutOutPoint = CGPoint(x: corner.x + (v2.dx / len2) * r, y: corner.y + (v2.dy / len2) * r)
                
                p.addLine(to: cutInPoint)
               // p.addQuadCurve(to: cutOutPoint, control: corner)
            }
            p.addLine(to: points.last!)
        }
      
    }

    // MARK: - Nodes

    private func nodeView(for node: MapNode, in size: CGSize, isCentre: Bool) -> some View {
        let point = project(node.position, in: size)
        let diameter: CGFloat = isCentre ? 23 : 18
        let isRightSide = node.position.x >= 0
        let isVisible = isCentre || selectedNodeID == nil || node.id == selectedNodeID

        return Button(action: { onSelect(node.id) }) {
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke((Color.black), lineWidth: isCentre ? 4.2 : 2.5))
                .frame(width: diameter, height: diameter)
        }.overlay(alignment: isCentre ? .bottom : (isRightSide ? .trailing : .leading)) {
            if !node.name.isEmpty {
                outlinedLabel(isCentre ? "You" : node.name, weight: isCentre ? .semibold : .regular)
                    .multilineTextAlignment(isCentre ? .center : (isRightSide ? .leading : .trailing))
                    .fixedSize()
                    .offset(
                        x: isCentre ? 0 : (isRightSide ? 30 : -30),
                        y: isCentre ? 20 : 20
                    )
                    .opacity(isVisible ? 1 : 0)
                                    .animation(.easeOut(duration: 0.1), value: selectedNodeID)
                                    
            }
        }

        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .buttonStyle(buttonSpring())
        .disabled(isCentre)
        .position(point)
        
    }
    

    // MARK: - Visual state

    private func opacity(for path: MapPath) -> Double {
        guard let selectedNodeID else { return 1.0 }
        let isChosenRoute =  path.destination.id == selectedNodeID
        return isChosenRoute ? 1.0 : 0.3
    }

    private func color(for lineColor: MapLineColor) -> Color {
        switch lineColor {
        case .blue:  return Color(red: 0.00, green: 0.32, blue: 0.71)
        case .amber: return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .green: return Color(red: 0.00, green: 0.51, blue: 0.28)
        case .red:   return Color(red: 0.88, green: 0.10, blue: 0.16)
        case .teal:  return Color(red: 0.00, green: 0.60, blue: 0.60)
        case .grey:  return Color(red: 0.55, green: 0.56, blue: 0.58)
        }
    }
}


struct JourneySheetView: View {
    let selectedNodeID: MapNode.ID?

    var body: some View {
        VStack {
            Text(selectedNodeID == nil ? "No selection" : "Selected!")
        }
    }
}

struct buttonSpring: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.35), value: configuration.isPressed)
    }
}

private func outlinedLabel(_ text: String, weight: Font.Weight) -> some View {
    ZStack {
        ForEach(Array(stride(from: 0.0, to: 360.0, by: 30)), id: \.self) { angle in
            Text(text)
                .font(.system(size: 13, weight: weight))
                .foregroundColor(.white)
                .offset(x: cos(angle * .pi / 180) * 1.5,
                        y: sin(angle * .pi / 180) * 1.5)
        }
        Text(text)
            .font(.system(size: 13, weight: weight))
            .foregroundColor(.black)
    }
}


extension Font.Weight {
    var uiWeight: UIFont.Weight {
        switch self {
        case .bold: return .bold
        case .semibold: return .semibold
        case .medium: return .medium
        default: return .regular
        }
    }
}

#Preview {
    JourneyHomeView()
}
