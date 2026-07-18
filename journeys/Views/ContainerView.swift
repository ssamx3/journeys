//
//  ContainerView.swift
//  journeys
//
//  Created by sam on 17/07/2026.
//

import SwiftUI

struct ContainerView: View {
    @State var showingStubBook = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("currently at")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Folsense Station")
                                .font(.largeTitle.bold())
                        }

                       

                      /*  HStack {
                            Text("Travel to")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("St Mystere")
                                    .font(.subheadline.weight(.medium))
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                        }
                       */

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
                            .background(Color.accentColor)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    
                       

                    

                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("departures").font(.subheadline)
                                    .foregroundStyle(.secondary)
                         

                            VStack(spacing: 8) {
                                DepartureRow(destination: "St Mystere", time: "00:59", operator: "EPQ", isSuggested: false)
                                DepartureRow(destination: "Misthallery", time: "12:05", operator: "Psychology", isSuggested: false)
                                DepartureRow(destination: "Dropstone", time: "1hr 12", operator: "Maths", isSuggested: false)
                                DepartureRow(destination: "Monte d'Or", time: "Suggested", operator: "Biology", isSuggested: true)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }



                    VStack(alignment: .leading, spacing: 8) {
                        Text("passes").font(.subheadline)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CommuterPassCard(streak: 12, stampedDays: [true, true, true, false, false, false, false])
                                PassCard(title: "EPQ", subtitle: "Rail Pass", tier: "Platinum", accent: .black)
                                PassCard(title: "Psych", subtitle: "Rail Pass", tier: "Bronze", accent: .pink)
                            }
                            .padding(.vertical, 4)
                            
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    
                    
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
                
            }
            .background(Color(.systemGroupedBackground))
            .overlay(alignment: .top) {
                LinearGradient(colors: [Color(.systemGroupedBackground), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 60)
                    .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                    .allowsHitTesting(false)
                    .ignoresSafeArea(edges: .top)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showingStubBook) { StubBookView() }
        }
    }
}


extension Color {
    /// LED departures-board amber, for use on the per-row black background
    static let boardAmber = Color(red: 1.0, green: 0.72, blue: 0.18)
}

struct DepartureRow: View {
    let destination: String
    let time: String
    let `operator`: String
    let isSuggested: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(destination.uppercased())
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .tracking(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(isSuggested ? Color.boardAmber.opacity(0.55) : Color.boardAmber)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(`operator`.uppercased())
                .font(.system(.caption2, design: .monospaced))
                .tracking(0.5)
                .lineLimit(1)
                .foregroundStyle(Color.boardAmber.opacity(isSuggested ? 0.45 : 0.65))
                .frame(width: 92, alignment: .leading)

            Group {
                if isSuggested {
                    Text("Suggested")
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                } else {
                    Text(time.uppercased())
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(isSuggested ? Color.boardAmber.opacity(0.7) : Color.boardAmber)
            .frame(width: 84, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct CommuterPassCard: View {
    let streak: Int
    let stampedDays: [Bool] // 7 entries, Mon...Sun

    private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Base foil gradient — shifts hue across the card rather than a flat single-color fade
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.62, blue: 0.20),
                    Color(red: 0.95, green: 0.35, blue: 0.55),
                    Color(red: 0.55, green: 0.40, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Diagonal holographic sheen
            GeometryReader { geo in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.2), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geo.size.width * 0.55)
                .rotationEffect(.degrees(24))
                .offset(x: geo.size.width * 0.15, y: -geo.size.height * 0.15)
                .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("COMMUTER PASS")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.85))
                        Text("\(streak) day streak")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "bolt.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
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
                                            .foregroundStyle(Color(red: 0.7, green: 0.35, blue: 0.6))
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
        

    }
}

struct PassCard: View {
    let title: String
    let subtitle: String
    let tier: String?
    let accent: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [accent, accent.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Faint diagonal sheen, subtler than the commuter pass since this card isn't holographic
            GeometryReader { geo in
                LinearGradient(colors: [.clear, .white.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(width: geo.size.width * 0.5)
                    .rotationEffect(.degrees(24))
                    .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.1)
                    .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: "wave.3.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    if let tier {
                        Text(tier.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.22))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                Text(title.uppercased())
                    .font(.subheadline.weight(.bold))
                    .tracking(0.4)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(12)
        }
        .frame(width: 150, height: 110, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ContainerView()
}
