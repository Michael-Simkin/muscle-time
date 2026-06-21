import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: StretchTimerModel
    @State private var cycleLengthText: String
    @State private var selectedVoiceIdentifier: String

    init(model: StretchTimerModel) {
        self.model = model
        _cycleLengthText = State(initialValue: model.savedCycleLengthText)
        _selectedVoiceIdentifier = State(initialValue: model.selectedVoiceIdentifier)
    }

    var body: some View {
        let validationMessage = model.validationMessage(for: cycleLengthText)

        Form {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cycle Length")
                        .font(.headline)
                    TextField("HH:MM", text: $cycleLengthText)
                        .monospacedDigit()
                        .textFieldStyle(.roundedBorder)
                    Text(validationMessage ?? "Use HH:MM from 00:10 to 12:00")
                        .font(.caption)
                        .foregroundStyle(validationMessage == nil ? Color.secondary : Color.red)
                }

                Picker("Voice", selection: $selectedVoiceIdentifier) {
                    ForEach(model.voiceOptions) { voice in
                        Text(voice.displayName).tag(voice.id)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Spacer()
                    Button("Apply") {
                        model.applySettings(
                            cycleLengthText: cycleLengthText,
                            selectedVoiceIdentifier: selectedVoiceIdentifier,
                        )
                    }
                    .disabled(!model.canApply(
                        cycleLengthText: cycleLengthText,
                        selectedVoiceIdentifier: selectedVoiceIdentifier,
                    ))
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding()
        .frame(width: 420, height: 240)
        .onAppear {
            cycleLengthText = model.savedCycleLengthText
            selectedVoiceIdentifier = model.selectedVoiceIdentifier
        }
    }
}
