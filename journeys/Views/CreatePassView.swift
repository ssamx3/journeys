//
//  CreatePassView.swift
//  journeys
//
//  Created by sam on 20/07/2026.
//

import SwiftUI
import SwiftData

struct CreatePassView: View {
    let store: JourneyStore
    var company: RailCompany?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var cardText: String

    @State private var backgroundColor: Color
    @State private var blockColor: Color
    @State private var blockShape: CardBlockShape
    @State private var blockPosition: CardBlockPosition
    @State private var fontColor: Color

    init(store: JourneyStore, company: RailCompany? = nil) {
        self.store = store
        self.company = company
        _name = State(initialValue: company?.name ?? "")
        _cardText = State(initialValue: company?.cardText ?? "")
        _backgroundColor = State(initialValue: company?.backgroundColor ?? .blue)
        _blockColor = State(initialValue: company?.blockColor ?? .pink)
        _blockShape = State(initialValue: company?.blockShape ?? .circle)
        _blockPosition = State(initialValue: company?.blockPosition ?? .bottom)
        _fontColor = State(initialValue: company?.fontColor ?? .white)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preview") {
                    HStack {
                        Spacer()
                        PassCard(
                            title: name,
                            cardText: cardText,
                            subtitle: company?.level.rawValue.capitalized ?? "Bronze",
                            iconName: "train.fill",
                            backgroundColor: backgroundColor,
                            blockColor: blockColor,
                            blockShape: blockShape,
                            blockPosition: blockPosition,
                            fontColor: fontColor
                        )
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                Section("Operator Details") {
                    TextField("Operator Name", text: $name)
                        .limitLength($name, 25)
                        .submitLabel(.done)
                }

                Section("RailPass Details") {
                    TextField("Text displayed on RailPass", text: $cardText)
                        .limitLength($cardText, 18)
                        .submitLabel(.done)

                    ColorPicker("Background Color", selection: $backgroundColor, supportsOpacity: false)
                    ColorPicker("Accent Color", selection: $blockColor, supportsOpacity: false)
                    ColorPicker("Font Color", selection: $fontColor, supportsOpacity: false)

                    Picker("Shape", selection: $blockShape) {
                        ForEach(CardBlockShape.allCases, id: \.self) { shape in
                            Text(shape.rawValue.capitalized).tag(shape)
                        }
                    }

                    Picker("Position", selection: $blockPosition) {
                        ForEach(CardBlockPosition.allCases, id: \.self) { position in
                            Text(position.rawValue.capitalized).tag(position)
                        }
                    }
                }

            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePass()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private var navigationTitle: String {
        if !name.isEmpty { return name }
        return company == nil ? "New RailPass" : "Edit RailPass"
    }

    private func savePass() {
        if let company = company {
            company.name = name
            company.cardText = cardText
            company.backgroundColorHex = backgroundColor.toHex()
            company.blockColorHex = blockColor.toHex()
            company.blockShapeRaw = blockShape.rawValue
            company.blockPositionRaw = blockPosition.rawValue
            company.fontColorHex = fontColor.toHex()
        } else {
            _ = store.createCompany(
                name: name,
                cardText: cardText,
                backgroundColorHex: backgroundColor.toHex(),
                blockColorHex: blockColor.toHex(),
                blockShapeRaw: blockShape.rawValue,
                blockPositionRaw: blockPosition.rawValue,
                fontColorHex: fontColor.toHex()
            )
        }
        dismiss()
    }
}

// MARK: - TextField length limit helper

private struct LimitLengthModifier: ViewModifier {
    @Binding var text: String
    let length: Int

    func body(content: Content) -> some View {
        content
            .onChange(of: text) { oldValue, newValue in
                if newValue.count > length {
                    text = String(newValue.prefix(length))
                }
            }
    }
}

extension View {
    func limitLength(_ text: Binding<String>, _ length: Int) -> some View {
        modifier(LimitLengthModifier(text: text, length: length))
    }
}

#Preview {
    NavigationStack {
        CreatePassView(store: .preview)
    }
}
