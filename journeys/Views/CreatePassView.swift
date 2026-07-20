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
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var cardText = ""

    @State private var backgroundColor: Color = .blue
    @State private var blockColor: Color = .pink
    @State private var blockShape: CardBlockShape = .circle
    @State private var blockPosition: CardBlockPosition = .bottom
    @State private var fontColor: Color = .white

    var body: some View {
        NavigationStack {
            Form {
                
                
                Section("Preview") {
                    HStack {
                        Spacer()
                        PassCard(
                            title: name,
                            cardText: cardText,
                            subtitle: "Bronze",
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
            .navigationTitle(name.isEmpty ? "New RailPass" : name)
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

    private func savePass() {
        _ = store.createCompany(
            name: name,
            cardText: cardText,
            backgroundColorHex: backgroundColor.toHex(),
            blockColorHex: blockColor.toHex(),
            blockShapeRaw: blockShape.rawValue,
            blockPositionRaw: blockPosition.rawValue
        )
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
