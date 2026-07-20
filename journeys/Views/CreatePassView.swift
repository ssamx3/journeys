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
    @State private var callSign = ""
    @State private var backgroundColor: Color = .blue
    @State private var blockColor: Color = .pink
    @State private var blockShape: CardBlockShape = .circle
    @State private var blockPosition: CardBlockPosition = .bottom

    var body: some View {
        NavigationStack {
            Form {
                Section("Operator Details") {
                    TextField("Operator Name", text: $name)
                    TextField("Call Sign (e.g. TSR)", text: $callSign)
                        .textInputAutocapitalization(.characters)
                        .limitLength($callSign, 3)
                }

                Section("Card Appearance") {
                    ColorPicker("Background Color", selection: $backgroundColor)
                    ColorPicker("Accent Color", selection: $blockColor)

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

                Section("Preview") {
                    HStack {
                        Spacer()
                        PassCard(
                            title: name.isEmpty ? "Preview" : name,
                            subtitle: "Bronze",
                            iconName: "train.fill",
                            backgroundColor: backgroundColor,
                            blockColor: blockColor,
                            blockShape: blockShape,
                            blockPosition: blockPosition
                        )
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Pass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePass()
                    }
                    .disabled(name.isEmpty || callSign.isEmpty)
                }
            }
        }
    }

    private func savePass() {
        _ = store.createCompany(
            name: name,
            callsign: callSign.uppercased(),
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
    // Preview requires a model context; in practice inject from parent
    Text("Preview requires JourneyStore injection")
}