import MuscleCore
import SwiftUI

/// A roulette-style wheel that spins automatically and lands on a random
/// exercise.
///
/// The wheel draws one wedge per `Exercise` in case order. Wedge `i` is
/// centered at angle `i * segmentAngle`, measured from due east and increasing
/// clockwise (SwiftUI's screen convention, where the y-axis points down). The
/// pointer is fixed at the top of the wheel (due north, 270°). To land wedge
/// `i` under the pointer the wheel must rotate so that `i * segmentAngle`
/// reaches 270°, i.e. by `270 - i * segmentAngle` degrees (plus whole turns for
/// the spinning effect).
///
/// Rotation is driven manually through `TimelineView(.animation)` rather than
/// `withAnimation` so the visible angle and the tick sound share one easing
/// curve: ticks fire on every peg the wheel crosses, so they race at the start
/// and space out as the wheel slows, matching its real speed.
struct SpinWheelView: View {
    /// Called with the chosen exercise once the wheel finishes spinning.
    let onResult: @MainActor (Exercise) -> Void
    /// Whether this wheel should play the tick sound (only the main screen does,
    /// so multiple displays don't stack the audio).
    let playsSound: Bool

    @State private var rotation = 0.0
    @State private var spinStart: Date?
    @State private var spinFrom = 0.0
    @State private var spinDelta = 0.0
    @State private var chosen: Exercise?
    @State private var lastPeg = 0
    @State private var didStart = false
    @State private var ratchet = RatchetPlayer(resource: "SoundTick", fileExtension: "wav")

    private let exercises = Exercise.allCases
    private let spinDuration = 4.0
    private let fullSpins = 5.0
    private let pegDegrees = 30.0
    private let diameter = 460.0

    private var segmentAngle: Double {
        360 / Double(exercises.count)
    }

    private static let wedgeColors: [Color] = [
        Color(red: 0.62, green: 0.40, blue: 0.95),
        Color(red: 0.95, green: 0.45, blue: 0.70),
        Color(red: 0.40, green: 0.70, blue: 0.95),
        Color(red: 0.50, green: 0.82, blue: 0.55),
    ]

    var body: some View {
        ZStack {
            if let spinStart {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(spinStart)
                    let angle = angle(forElapsed: elapsed)

                    wheel
                        .rotationEffect(.degrees(angle))
                        .onChange(of: peg(for: angle)) { _, newPeg in
                            advanceTicks(to: newPeg)
                        }
                        .onChange(of: elapsed >= spinDuration) { _, finished in
                            if finished { finishSpin() }
                        }
                }
            } else {
                wheel
                    .rotationEffect(.degrees(rotation))
            }

            Circle()
                .fill(Color.white)
                .frame(width: 34, height: 34)
                .shadow(color: .black.opacity(0.4), radius: 4)

            pointer
                .offset(y: -(diameter / 2) - 2)
        }
        .frame(width: diameter, height: diameter)
        .onAppear(perform: startIfNeeded)
    }

    private var wheel: some View {
        ZStack {
            ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                let center = Double(index) * segmentAngle

                Wedge(
                    startAngle: .degrees(center - segmentAngle / 2),
                    endAngle: .degrees(center + segmentAngle / 2),
                )
                .fill(Self.wedgeColors[index % Self.wedgeColors.count])
                .overlay(
                    Wedge(
                        startAngle: .degrees(center - segmentAngle / 2),
                        endAngle: .degrees(center + segmentAngle / 2),
                    )
                    .stroke(Color.white.opacity(0.85), lineWidth: 2),
                )

                Text(exercise.displayName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 2)
                    .offset(
                        x: cos(center * .pi / 180) * diameter * 0.3,
                        y: sin(center * .pi / 180) * diameter * 0.3,
                    )
            }
        }
        .frame(width: diameter, height: diameter)
        .overlay(
            Circle().stroke(Color.white.opacity(0.9), lineWidth: 4),
        )
    }

    private var pointer: some View {
        Image(systemName: "arrowtriangle.down.fill")
            .font(.system(size: 44))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 4)
    }

    /// Eased angle for a given elapsed time. Uses a cubic ease-out so the wheel
    /// decelerates smoothly to its resting angle.
    private func angle(forElapsed elapsed: Double) -> Double {
        let progress = min(max(elapsed / spinDuration, 0), 1)
        let eased = 1 - pow(1 - progress, 3)
        return spinFrom + spinDelta * eased
    }

    private func peg(for angle: Double) -> Int {
        Int(((angle - spinFrom) / pegDegrees).rounded(.down))
    }

    private func advanceTicks(to newPeg: Int) {
        guard newPeg > lastPeg else { return }
        lastPeg = newPeg
        if playsSound { ratchet.tick() }
    }

    private func startIfNeeded() {
        guard !didStart else { return }
        didStart = true

        // Brief pause so the wheel registers before it launches.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            spin()
        }
    }

    private func spin() {
        let chosenIndex = Int.random(in: 0 ..< exercises.count)
        chosen = exercises[chosenIndex]

        let residue = (270 - Double(chosenIndex) * segmentAngle)
            .truncatingRemainder(dividingBy: 360)
        let normalizedResidue = (residue + 360).truncatingRemainder(dividingBy: 360)

        spinFrom = rotation
        spinDelta = fullSpins * 360 + normalizedResidue
        lastPeg = 0
        spinStart = .now
    }

    private func finishSpin() {
        guard let chosen, spinStart != nil else { return }

        rotation = spinFrom + spinDelta
        spinStart = nil
        onResult(chosen)
    }
}

extension Exercise {
    /// Bundled voice clip announcing this exercise, played when the wheel lands.
    var announcementResource: String {
        switch self {
        case .pushUps: "VoiceExercisePushUps"
        case .pullUps: "VoiceExercisePullUps"
        case .plank: "VoiceExercisePlank"
        case .treadmill: "VoiceExerciseTreadmill"
        }
    }
}

/// A pie-slice from the center of the bounding box out to its inscribed circle.
private struct Wedge: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false,
        )
        path.closeSubpath()
        return path
    }
}
