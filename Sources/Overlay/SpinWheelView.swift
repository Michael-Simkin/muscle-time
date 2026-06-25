import MuscleCore
import SwiftUI

/// A roulette-style wheel that spins and lands on a random exercise.
///
/// The wheel draws one wedge per `Exercise` in case order. Wedge `i` is
/// centered at angle `i * segmentAngle`, measured from due east and increasing
/// clockwise (SwiftUI's screen convention, where the y-axis points down). The
/// pointer is fixed at the top of the wheel (due north, 270°). To land wedge
/// `i` under the pointer the wheel must rotate so that `i * segmentAngle`
/// reaches 270°, i.e. by `270 - i * segmentAngle` degrees (plus whole turns for
/// the spinning effect).
struct SpinWheelView: View {
    /// Called with the chosen exercise once the wheel finishes spinning.
    let onResult: @MainActor (Exercise) -> Void

    @State private var rotation = 0.0
    @State private var isSpinning = false
    @State private var hasResult = false

    private let exercises = Exercise.allCases
    private let spinDuration = 3.5
    private let diameter = 320.0

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
        VStack(spacing: 22) {
            ZStack {
                wheel
                    .rotationEffect(.degrees(rotation))

                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.4), radius: 4)

                pointer
                    .offset(y: -(diameter / 2) - 2)
            }
            .frame(width: diameter, height: diameter)

            Button(hasResult ? "Spin again" : "Spin the wheel") {
                spin()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(red: 0.62, green: 0.40, blue: 0.95))
            .disabled(isSpinning)
        }
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
                    .font(.headline)
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
            .font(.system(size: 34))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 4)
    }

    private func spin() {
        guard !isSpinning else { return }

        let chosenIndex = Int.random(in: 0 ..< exercises.count)
        let chosen = exercises[chosenIndex]

        let residue = (270 - Double(chosenIndex) * segmentAngle)
            .truncatingRemainder(dividingBy: 360)
        let normalizedResidue = (residue + 360).truncatingRemainder(dividingBy: 360)

        let fullSpins = 5.0
        let currentBase = (rotation / 360).rounded(.down) * 360
        var target = currentBase + fullSpins * 360 + normalizedResidue
        if target <= rotation {
            target += 360
        }

        isSpinning = true
        withAnimation(.easeOut(duration: spinDuration)) {
            rotation = target
        } completion: {
            isSpinning = false
            hasResult = true
            onResult(chosen)
        }
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
