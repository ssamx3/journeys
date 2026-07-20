//
//  ContainerView.swift
//  journeys
//
//  Created by sam on 17/07/2026.
//

import SwiftUI

struct ContainerView: View {
    @State var showingStubBook = false
    @State private var statsRange: StatsRange = .week

  
    private let currentStation = "Folsense Station"
    private let milesThisWeek = 142

    var body: some View {
            NavigationStack {
                ZStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            heroCard
                            
                            passesCard

                            StubbookEntryCard()
                                .contentShape(RoundedRectangle(cornerRadius: 16))
                                .onTapGesture { showingStubBook = true }
                            
                            statsCard
                        }
                        .padding(.horizontal)
                       
                        .padding(.bottom, 80)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(.systemGroupedBackground))
                    
  
                
                }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showingStubBook) { StubBookView() }
            }
        }    // MARK: - Sections

    private var heroCard: some View {
        VStack {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("currently at")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(currentStation)
                        .font(.largeTitle.bold())
                }
                
                
                
                Button {
                    // get tickets action
                } label: {
                    HStack {
                        Text("Get tickets")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(Color(.blue).opacity(0.9))
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }.padding(.top)
    }
    

    private var passesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("passes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "plus")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CommuterPassCard(streak: 12, stampedDays: [true, true, true, false, false, false, false])
                    PassCard(title: "medicine", subtitle: "Bronze", iconName: "train.fill", backgroundColor: Color(.blue), blockColor: Color(.pink), blockShape: .diagonal, blockPosition: .bottom)
                    PassCard(title: "psychology", subtitle: "Bronze", iconName: "train.fill", backgroundColor: Color(.indigo), blockColor: Color(.purple), blockShape: .circle, blockPosition: .left)
                    PassCard(title: "biology", subtitle: "Bronze", iconName: "train.fill", backgroundColor: Color(.magenta), blockColor: Color(.cyan), blockShape: .square, blockPosition: .left)
                    
             
                   

                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
    
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                StatsRangeSwitch(selection: $statsRange)
            }

            
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatTile(value: "\(statsSnapshot.miles)", label: "miles travelled")
                    StatTile(value: statsSnapshot.timeLabel, label: "time travelling")
                }
                HStack(spacing: 10) {
                    StatTile(value: statsSnapshot.topOperator, label: "most used operator")
                    StatTile(value: "\(statsSnapshot.personalBestMiles) miles", label: "personal best journey")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: - Stats

    private var statsSnapshot: StatsSnapshot {
        switch statsRange {
        case .week:
            return StatsSnapshot(miles: 142, timeLabel: "6h 40m", topOperator: "EPQ", personalBestMiles: 38)
        case .month:
            return StatsSnapshot(miles: 612, timeLabel: "27h 15m", topOperator: "Maths", personalBestMiles: 54)
        case .year:
            return StatsSnapshot(miles: 7180, timeLabel: "312h 50m", topOperator: "Psychology", personalBestMiles: 96)
        }
    }
    private struct StatsSnapshot {
        let miles: Int
        let timeLabel: String
        let topOperator: String
        let personalBestMiles: Int
    }

    private enum StatsRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case year = "365D"
    }

    private struct StatsRangeSwitch: View {
        @Binding var selection: StatsRange
        @Namespace private var namespace

        var body: some View {
            HStack(spacing: 2) {
                ForEach(StatsRange.allCases, id: \.self) { range in
                    Text(range.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(selection == range ? Color.primary : Color.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            if selection == range {
                                Capsule()
                                    .fill(Color(.systemBackground))
                                    .matchedGeometryEffect(id: "statsRangePill", in: namespace)
                            }
                        }
                        .contentShape(Capsule())
                        .onTapGesture {
                            guard selection != range else { return }
                            withAnimation(.snappy(duration: 0.3)) {
                                selection = range
                            }
                        }
                }
            }
            .padding(3)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
        }
    }

    private struct StatTile: View {
        
        let value: String
        let label: String
       

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                
                Spacer()
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Recent journeys



// MARK: - Passes

private struct HolographicPassBackground: View {
    @State private var animateGradient = false
    
    private let holoColors: [Color] = [
        Color(red: 0.55, green: 0.85, blue: 1.00), // ice blue
        Color(red: 0.75, green: 0.60, blue: 1.00), // violet
        Color(red: 1.00, green: 0.55, blue: 0.80), // pink
        Color(red: 1.00, green: 0.80, blue: 0.55), // gold
        Color(red: 0.55, green: 1.00, blue: 0.85), // mint
    ]

    var body: some View {
        ZStack {
            Color.black

            

            GuillochePattern()
                .stroke(Color.white.opacity(0.045), lineWidth: 1)
            
            LinearGradient(
                colors: holoColors,
                // Shift the gradient points based on the animation state
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .opacity(0.15)
            .blendMode(.normal)

            .hueRotation(.degrees(animateGradient ? 360 : 0))

            LinearGradient(
                colors: [.white.opacity(0.10), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.plusLighter)

            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear, Color.black.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .drawingGroup()
        .onAppear {

            withAnimation(
                .easeInOut(duration:4)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }
}

private struct GuillochePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 12
        var y: CGFloat = -spacing
        while y < rect.height + spacing {
            var p = Path()
            p.move(to: CGPoint(x: 0, y: y))
            let amplitude: CGFloat = 6
            let wavelength: CGFloat = 40
            var x: CGFloat = 0
            while x <= rect.width {
                let dy = sin((x / wavelength) * .pi * 2) * amplitude
                p.addLine(to: CGPoint(x: x, y: y + dy))
                x += 8
            }
            path.addPath(p)
            y += spacing
        }
        return path
    }
}

struct CommuterPassCard: View {
    let streak: Int
    let stampedDays: [Bool]

    private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        ZStack(alignment: .topLeading) {
            HolographicPassBackground()

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("COMMUTER PASS ")
                            .font(.system(.caption2).weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(streak) day streak")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(">>>")
                        .font(.system(.caption2).weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer(minLength: 4)

                HStack(spacing: 7) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(stampedDays[index] ? Color.white : Color.white.opacity(0.22))
                                .frame(width: 18, height: 18)
                                .overlay {
                                    if stampedDays[index] {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color.black)
                                    }
                                }
                            Text(dayLetters[index])
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            .padding(14)
        }
        .frame(width: 240, height: 110, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.05), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

enum CardBlockShape {
    case circle
    case square
    case diagonal
}

enum CardBlockPosition {
    case top
    case bottom
    case left
    case right
}

struct PassCard: View {
    let title: String
    let subtitle: String
    

    let iconName: String
    let backgroundColor: Color
    let blockColor: Color
    let blockShape: CardBlockShape
    let blockPosition: CardBlockPosition

    var body: some View {
        ZStack(alignment: .topLeading) {

            backgroundColor.opacity(0.7)
            

            GeometryReader { geo in
   
                let size = max(geo.size.width, geo.size.height)
                
                Group {
                    switch blockShape {
                    case .circle:
                        Circle().fill(blockColor.opacity(0.7))
                    case .square:
                        Rectangle().fill(blockColor.opacity(0.7))
                    case .diagonal:
                        Rectangle()
                            .fill(blockColor.opacity(0.7))
                            
                            .rotationEffect(.degrees(0)
                        
                            )
                    }
                }
                .frame(width: size, height: size)
                .position(blockCoordinates(for: blockPosition, in: geo.size))
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))



            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                
                    Spacer()
                    

                    Image(systemName: "wave.3.forward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 22,))
                    .foregroundStyle(.white)

            }
            .padding(12)
        }
        .frame(width: 150, height: 110, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    // Helper to calculate where to drop the shape based on the enum
    private func blockCoordinates(for position: CardBlockPosition, in size: CGSize) -> CGPoint {
        switch position {
        case .top: return CGPoint(x: size.width / 2, y: 0)
        case .bottom: return CGPoint(x: size.width / 2, y: size.height)
        case .left: return CGPoint(x: 0, y: size.height / 2)
        case .right: return CGPoint(x: size.width, y: size.height / 2)
        }
    }
}
// MARK: - Stubbook

struct StubbookEntryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("stubs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Stub(originCode: "FLS", destinationCode: "SMT", subtitle: "59m", operatorName: "EPQ")
                    Stub(originCode: "SMT", destinationCode: "MHY", subtitle: "2h 15", operatorName: "Psychology")
                    Stub(originCode: "PSR", destinationCode: "DRS", subtitle: "1h 12", operatorName: "Maths")
                    
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

struct Stub: View {
    let originCode: String
    let destinationCode: String
    let subtitle: String
    let operatorName: String

    
    private var seedString: String { originCode + destinationCode + operatorName }
    
    private var jitterDegrees: Double {
      
        let hash = seedString.hashValue
        let normalized = Double(abs(hash) % 1200) / 100.0
        return -5.0 + normalized
    }

    

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                
                BarcodeShape(seed: seedString)
                    .frame(height: 18)
                    .foregroundStyle(.primary.opacity(0.65))
                
                HStack(spacing: 4) {
                    Text(originCode.uppercased())
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(destinationCode.uppercased())
                }
                .font(.system(.subheadline).weight(.bold))
                .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(operatorName.uppercased())
                    .font(.system(.caption2).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .frame(width: 132, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(14)
        .rotationEffect(.degrees(jitterDegrees))
    }
}


struct BarcodeShape: Shape {
    let seed: String
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var generator = SeededGenerator(seed: seed)
        let spacing: CGFloat = 2
        var currentX: CGFloat = 0
        
        
        while currentX < rect.width {
            let w: CGFloat = Bool.random(using: &generator) ? 2 : 1
            if currentX + w > rect.width { break }
            path.addRect(CGRect(x: currentX, y: 0, width: w, height: rect.height))
            currentX += w + spacing
        }
        return path
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: String) {
        state = seed.unicodeScalars.reduce(UInt64(1)) { $0 &+ UInt64($1.value) } &+ 1
    }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}


#Preview {
    ContainerView()
}
