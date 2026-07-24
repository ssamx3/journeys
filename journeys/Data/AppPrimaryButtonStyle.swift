//
//  AppPrimaryButtonStyle.swift
//  journeys
//
//  Created by sam on 24/07/2026.
//



//

import SwiftUI

// MARK: - Primary (filled, monochrome)

struct AppPrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(isDestructive ? Color.red : Color(.systemBackground))
            .background(isDestructive ? Color.red.opacity(0.15) : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary (tertiary background, row-style)

struct AppRowButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .padding()
            .foregroundStyle(isDestructive ? Color.red : Color.primary)
            .background(isDestructive ? Color.red.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Chip (filter pills, monochrome)

struct AppChipButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
            .background(isSelected ? Color.primary : Color(.tertiarySystemFill))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AppPrimaryButtonStyle {
    static var appPrimary: AppPrimaryButtonStyle { AppPrimaryButtonStyle() }
    static func appPrimary(destructive: Bool) -> AppPrimaryButtonStyle {
        AppPrimaryButtonStyle(isDestructive: destructive)
    }
}

extension ButtonStyle where Self == AppRowButtonStyle {
    static var appRow: AppRowButtonStyle { AppRowButtonStyle() }
    static func appRow(destructive: Bool) -> AppRowButtonStyle {
        AppRowButtonStyle(isDestructive: destructive)
    }
}

extension ButtonStyle where Self == AppChipButtonStyle {
    static func appChip(selected: Bool) -> AppChipButtonStyle {
        AppChipButtonStyle(isSelected: selected)
    }
}

// MARK: - Section header label

struct SectionLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Rounded font convenience


extension View {
    func appRounded() -> some View {
        self.fontDesign(.rounded)
    }
}
