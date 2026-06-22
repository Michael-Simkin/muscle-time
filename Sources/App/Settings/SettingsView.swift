import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: MuscleTimeTimerModel
    @State private var cycleHoursText: String
    @State private var cycleMinutesText: String
    @State private var selectedVoiceIdentifier: String

    init(model: MuscleTimeTimerModel) {
        self.model = model
        let (hours, minutes) = Self.parseHoursAndMinutes(from: model.savedCycleLengthText)
        _cycleHoursText = State(initialValue: Self.twoDigitString(hours))
        _cycleMinutesText = State(initialValue: Self.twoDigitString(minutes))
        _selectedVoiceIdentifier = State(initialValue: model.selectedVoiceIdentifier)
    }

    var body: some View {
        let cycleLengthText = normalizedCycleLengthText
        let validationMessage = if let cycleLengthText {
            model.validationMessage(for: cycleLengthText) ?? "Use HH:MM from 00:10 to 12:00"
        } else {
            "Use HH:MM from 00:10 to 12:00"
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Cycle Length")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("HH", text: $cycleHoursText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .multilineTextAlignment(.center)
                        .onChange(of: cycleHoursText) { _, newValue in
                            cycleHoursText = Self.sanitizedHoursInput(newValue)
                        }

                    Text(":")
                        .font(.title2)
                        .monospacedDigit()

                    TextField("MM", text: $cycleMinutesText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .multilineTextAlignment(.center)
                        .onChange(of: cycleMinutesText) { _, newValue in
                            cycleMinutesText = Self.sanitizedMinutesInput(newValue)
                        }
                }

                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(validationMessage == "Use HH:MM from 00:10 to 12:00" ? Color.secondary : Color.red)
            }

            Text("Voice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("Voice", selection: $selectedVoiceIdentifier) {
                ForEach(model.voiceOptions) { voice in
                    Text(voice.displayName).tag(voice.id)
                }
            }
            .pickerStyle(.radioGroup)
            .onChange(of: selectedVoiceIdentifier) { _, newValue in
                model.applyVoiceSelection(newValue)
            }

            HStack {
                Spacer()
                Button("Apply") {
                    guard let cycleLengthText else { return }
                    model.applySettings(
                        cycleLengthText: cycleLengthText,
                        selectedVoiceIdentifier: selectedVoiceIdentifier,
                    )
                }
                .disabled(!model.canApply(
                    cycleLengthText: cycleLengthText ?? "",
                    selectedVoiceIdentifier: selectedVoiceIdentifier,
                ))
                .keyboardShortcut(.defaultAction)
            }

            Button("Show Overlay") {
                model.showOverlayForTesting()
            }
        }
        .padding(12)
        .frame(width: 300, height: 240)
        .onAppear {
            let (hours, minutes) = Self.parseHoursAndMinutes(from: model.savedCycleLengthText)
            cycleHoursText = Self.twoDigitString(hours)
            cycleMinutesText = Self.twoDigitString(minutes)
            selectedVoiceIdentifier = model.selectedVoiceIdentifier
        }
    }

    private var normalizedCycleLengthText: String? {
        guard let hours = Int(cycleHoursText),
              let minutes = Int(cycleMinutesText),
              (0 ... 12).contains(hours),
              (0 ... 59).contains(minutes)
        else {
            return nil
        }

        return Self.cycleLengthText(hours: hours, minutes: minutes)
    }

    private static func parseHoursAndMinutes(from value: String) -> (hours: Int, minutes: Int) {
        let parts = value.split(separator: ":")

        guard parts.count == 2,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]),
              (0 ... 12).contains(hours),
              (0 ... 59).contains(minutes)
        else {
            return (0, 10)
        }

        return (hours, minutes)
    }

    private static func cycleLengthText(hours: Int, minutes: Int) -> String {
        String(format: "%02d:%02d", hours, minutes)
    }

    private static func sanitizedHoursInput(_ value: String) -> String {
        let digitsOnly = value.filter(\.isNumber)
        let truncated = String(digitsOnly.prefix(2))
        guard let number = Int(truncated), number > 12 else {
            return truncated
        }

        return "12"
    }

    private static func sanitizedMinutesInput(_ value: String) -> String {
        let digitsOnly = value.filter(\.isNumber)
        let truncated = String(digitsOnly.prefix(2))
        guard let number = Int(truncated), number > 59 else {
            return truncated
        }

        return "59"
    }

    private static func twoDigitString(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}
