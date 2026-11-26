import SwiftUI

// ബോർഡറിലൂടെ ഓടുന്ന തിളങ്ങുന്ന "beam".
// ആശയം: ismnoiet/border-beam-ios (MIT). ഇത് Metal ഇല്ലാതെ SwiftUI-യിൽ സ്വന്തമായി എഴുതിയതാണ്.

enum BeamPalette {
    static let neon: [Color] = [
        Color(red: 0.00, green: 0.90, blue: 1.00),
        Color(red: 0.25, green: 0.55, blue: 1.00),
        Color(red: 0.55, green: 0.35, blue: 1.00),
        Color(red: 1.00, green: 0.30, blue: 0.85)
    ]

    static let aurora: [Color] = [
        Color(red: 0.45, green: 1.00, blue: 0.80),
        Color(red: 0.40, green: 0.75, blue: 1.00),
        Color(red: 0.40, green: 0.45, blue: 1.00),
        Color(red: 0.75, green: 0.60, blue: 1.00)
    ]

    static let sunset: [Color] = [
        Color(red: 1.00, green: 0.85, blue: 0.30),
        Color(red: 1.00, green: 0.60, blue: 0.20),
        Color(red: 1.00, green: 0.40, blue: 0.45),
        Color(red: 0.65, green: 0.35, blue: 0.95)
    ]

    static let spectrum: [Color] = [
        Color(red: 0.25, green: 0.50, blue: 1.00),
        Color(red: 0.00, green: 0.80, blue: 0.85),
        Color(red: 0.30, green: 0.90, blue: 0.50),
        Color(red: 1.00, green: 0.90, blue: 0.25),
        Color(red: 1.00, green: 0.55, blue: 0.20),
        Color(red: 1.00, green: 0.30, blue: 0.30)
    ]

    static let silver: [Color] = [
        Color(white: 0.55),
        Color(red: 0.80, green: 0.88, blue: 1.00),
        Color.white
    ]

    static let accent: [Color] = [
        Color(red: 0.30, green: 0.55, blue: 1.00).opacity(0.7),
        Color(red: 0.30, green: 0.55, blue: 1.00)
    ]

    struct Option {
        let key: String
        let title: String
    }

    static let options: [Option] = [
        Option(key: "neon", title: "Neon"),
        Option(key: "aurora", title: "Aurora"),
        Option(key: "sunset", title: "Sunset"),
        Option(key: "spectrum", title: "Spectrum"),
        Option(key: "silver", title: "Silver"),
        Option(key: "accent", title: "Blue")
    ]

    static func named(_ key: String) -> [Color] {
        switch key {
        case "aurora": return aurora
        case "sunset": return sunset
        case "spectrum": return spectrum
        case "silver": return silver
        case "accent": return accent
        default: return neon
        }
    }
}

struct BeamBorder<S: InsettableShape>: View {
    let shape: S
    let active: Bool
    let colors: [Color]?
    let lineWidth: CGFloat
    let duration: Double
    let reverse: Bool
    let intensity: Double
    let fps: Double
    let glow: Bool

    @AppStorage("beam_enabled") private var enabled = true
    @AppStorage("beam_palette") private var paletteKey = "neon"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(shape: S,
         active: Bool,
         colors: [Color]?,
         lineWidth: CGFloat,
         duration: Double,
         reverse: Bool,
         intensity: Double,
         fps: Double,
         glow: Bool) {
        self.shape = shape
        self.active = active
        self.colors = colors
        self.lineWidth = lineWidth
        self.duration = duration
        self.reverse = reverse
        self.intensity = intensity
        self.fps = fps
        self.glow = glow
    }

    var body: some View {
        let palette = colors ?? BeamPalette.named(paletteKey)
        let shown = enabled && active

        TimelineView(.animation(minimumInterval: 1.0 / max(fps, 1), paused: !shown || reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let progress = (t / max(duration, 0.1)).truncatingRemainder(dividingBy: 1)
            let direction: Double = reverse ? -1 : 1
            let angle: Double = reduceMotion ? 40 : direction * progress * 360
            let gradient = Self.gradient(palette, angle: angle, intensity: intensity)

            ZStack {
                if glow {
                    shape
                        .strokeBorder(gradient, lineWidth: lineWidth * 3.5)
                        .blur(radius: 7)
                        .opacity(0.65)
                }
                shape
                    .strokeBorder(gradient, lineWidth: lineWidth)
            }
        }
        .opacity(shown ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: shown)
        .allowsHitTesting(false)
    }

    static func gradient(_ colors: [Color], angle: Double, intensity: Double) -> AngularGradient {
        let list = colors.isEmpty ? [Color.white] : colors
        let count = list.count
        let start = 0.04
        let length = 0.32

        var stops: [Gradient.Stop] = [
            Gradient.Stop(color: list[0].opacity(0), location: 0)
        ]

        for (index, color) in list.enumerated() {
            let fraction = count > 1 ? Double(index) / Double(count - 1) : 1
            let strength = (0.35 + 0.65 * fraction) * intensity
            stops.append(
                Gradient.Stop(color: color.opacity(strength), location: start + length * fraction)
            )
        }

        let last = list[count - 1]
        stops.append(Gradient.Stop(color: last.opacity(0), location: start + length + 0.03))
        stops.append(Gradient.Stop(color: last.opacity(0), location: 1))

        return AngularGradient(
            gradient: Gradient(stops: stops),
            center: .center,
            angle: .degrees(angle)
        )
    }
}

extension View {
    func borderBeam<S: InsettableShape>(
        _ shape: S,
        active: Bool = true,
        colors: [Color]? = nil,
        lineWidth: CGFloat = 1.6,
        duration: Double = 2.6,
        reverse: Bool = false,
        intensity: Double = 1,
        fps: Double = 60,
        glow: Bool = true
    ) -> some View {
        overlay(
            BeamBorder(
                shape: shape,
                active: active,
                colors: colors,
                lineWidth: lineWidth,
                duration: duration,
                reverse: reverse,
                intensity: intensity,
                fps: fps,
                glow: glow
            )
        )
    }
}

struct GlowPressStyle<S: InsettableShape>: ButtonStyle {
    let shape: S

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .borderBeam(shape, active: configuration.isPressed, duration: 1.1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
