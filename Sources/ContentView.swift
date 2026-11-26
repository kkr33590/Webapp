import SwiftUI

struct KeyValueItem: Identifiable {
    let id = UUID()
    let rawKey: String
    let key: String
    let value: String
    let icon: String
    let isImportant: Bool
}

// മോഡേൺ ഗ്ലാസ്-പിൽ ബട്ടൺ സ്റ്റൈൽ
struct ModernPillButtonStyle: ButtonStyle {
    var accent: Color = .white
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.68), value: configuration.isPressed)
    }
}

struct ContentView: View {
    @State private var vehicleNumber: String = ""
    @State private var searchedPlate: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var items: [KeyValueItem] = []
    @State private var rawResponse: String = ""
    @State private var showRaw: Bool = false
    @State private var copiedToast: String? = nil

    @Namespace private var tabNamespace
    @FocusState private var isInputFocused: Bool
    @AppStorage("beam_enabled") private var beamEnabled = true
    @AppStorage("beam_palette") private var paletteKey = "neon"

    private var activeColors: [Color] {
        BeamPalette.named(paletteKey)
    }

    private var primaryAccent: Color {
        activeColors.first ?? .cyan
    }

    private var secondaryAccent: Color {
        activeColors.last ?? .purple
    }

    private var highlightItems: [KeyValueItem] {
        items.filter { $0.isImportant }.prefix(4).map { $0 }
    }

    private var detailItems: [KeyValueItem] {
        let highlightIDs = Set(highlightItems.map { $0.id })
        return items.filter { !highlightIDs.contains($0.id) }
    }

    private var formattedShareText: String {
        let header = searchedPlate.isEmpty ? "Vehicle RC Details" : "Vehicle RC: \(searchedPlate)"
        let bodyText = items.map { "• \($0.key): \($0.value)" }.joined(separator: "\n")
        return bodyText.isEmpty ? rawResponse : "\(header)\n\n\(bodyText)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Deep Obsidian Background
                Color(red: 0.035, green: 0.04, blue: 0.065)
                    .ignoresSafeArea()

                // Dynamic Top Ambient Light
                VStack {
                    RadialGradient(
                        colors: [primaryAccent.opacity(0.24), secondaryAccent.opacity(0.08), Color.clear],
                        center: .top,
                        startRadius: 10,
                        endRadius: 380
                    )
                    .frame(height: 380)
                    Spacer()
                }
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    // Top Header Bar
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(primaryAccent)
                                    .frame(width: 7, height: 7)
                                    .shadow(color: primaryAccent, radius: 4)
                                Text("NEXT-GEN RC ENGINE")
                                    .font(.system(size: 10, weight: .heavy))
                                    .tracking(1.8)
                                    .foregroundColor(primaryAccent)
                            }

                            Text("Vehicle Info Pro")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Modern Beam Glow Toggle Button
                        Button {
                            let gen = UIImpactFeedbackGenerator(style: .light)
                            gen.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                beamEnabled.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: beamEnabled ? "sparkles" : "sparkle")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(beamEnabled ? primaryAccent : .white.opacity(0.45))
                                Text(beamEnabled ? "Glow On" : "Glow Off")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial.opacity(0.6))
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(ModernPillButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)

                    // Horizontal Modern Theme Selector Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BeamPalette.options, id: \.key) { option in
                                let isSelected = paletteKey == option.key
                                let colors = BeamPalette.named(option.key)

                                Button {
                                    let gen = UISelectionFeedbackGenerator()
                                    gen.selectionChanged()
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                                        paletteKey = option.key
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: colors,
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 10, height: 10)
                                            .shadow(color: isSelected ? (colors.first ?? .clear) : .clear, radius: 4)

                                        Text(option.title)
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                                            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                    }
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 7)
                                    .background(
                                        ZStack {
                                            if isSelected {
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                (colors.first ?? .blue).opacity(0.28),
                                                                (colors.last ?? .purple).opacity(0.18)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            } else {
                                                Capsule()
                                                    .fill(Color.white.opacity(0.045))
                                            }
                                        }
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                isSelected ? (colors.first ?? .white).opacity(0.65) : Color.white.opacity(0.08),
                                                lineWidth: isSelected ? 1.2 : 1
                                            )
                                    )
                                }
                                .buttonStyle(ModernPillButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Modern Search & Action Container
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(primaryAccent.opacity(0.15))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "car.front.waves.up")
                                    .foregroundColor(primaryAccent)
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            TextField("", text: $vehicleNumber, prompt: Text("KL55A9200").foregroundColor(.white.opacity(0.28)))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled(true)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .focused($isInputFocused)
                                .submitLabel(.search)
                                .onSubmit {
                                    fetchVehicleDetails()
                                }

                            // Modern Paste / Clear Mini-Pill Buttons
                            if vehicleNumber.isEmpty {
                                Button {
                                    if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                        let gen = UIImpactFeedbackGenerator(style: .light)
                                        gen.impactOccurred()
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                            vehicleNumber = clip.uppercased()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.clipboard")
                                        Text("Paste")
                                    }
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ModernPillButtonStyle())
                            } else {
                                Button {
                                    let gen = UIImpactFeedbackGenerator(style: .light)
                                    gen.impactOccurred()
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        vehicleNumber = ""
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 26, height: 26)
                                        .background(Color.white.opacity(0.12))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ModernPillButtonStyle())
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.32))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .borderBeam(
                            RoundedRectangle(cornerRadius: 16, style: .continuous),
                            active: isInputFocused || isLoading,
                            lineWidth: 1.8,
                            duration: isLoading ? 1.1 : 2.6
                        )

                        // Ultra-Modern Glass & Tactile Primary CTA Button
                        Button(action: fetchVehicleDetails) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Scanning RC Database...")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 26, height: 26)
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12, weight: .heavy))
                                    }
                                    Text("Search Vehicle Details")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                ZStack {
                                    LinearGradient(
                                        colors: [
                                            primaryAccent.opacity(0.95),
                                            secondaryAccent.opacity(0.92)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )

                                    // Top Glass Specular Shine
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.32),
                                            Color.white.opacity(0.05),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.1)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: primaryAccent.opacity(0.4), radius: 14, y: 6)
                        }
                        .buttonStyle(GlowPressStyle(shape: RoundedRectangle(cornerRadius: 16, style: .continuous)))
                        .disabled(isLoading)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.09), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Error Banner
                    if let errorMessage = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.92))
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.red.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.red.opacity(0.35), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    // Results Section
                    if !items.isEmpty || !rawResponse.isEmpty {
                        VStack(spacing: 12) {
                            // Custom Modern Sliding Pill Switcher + Action Pills
                            HStack(spacing: 8) {
                                // Custom Sliding Tab Control
                                HStack(spacing: 0) {
                                    tabButton(title: "Pro Cards", icon: "square.grid.2x2.fill", isRawTab: false)
                                    tabButton(title: "Raw JSON", icon: "curlybraces", isRawTab: true)
                                }
                                .padding(4)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )

                                Spacer()

                                // Copy All Pill Button
                                Button {
                                    copyAllResults()
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: "doc.on.doc.fill")
                                        Text("Copy")
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .background(Color.white.opacity(0.09))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ModernPillButtonStyle())

                                // Share Pill Button
                                ShareLink(item: formattedShareText) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 34, height: 34)
                                        .background(primaryAccent.opacity(0.22))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(primaryAccent.opacity(0.45), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(ModernPillButtonStyle())
                            }
                            .padding(.horizontal)

                            if showRaw {
                                ScrollView {
                                    Text(rawResponse)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.88))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(16)
                                        .textSelection(.enabled)
                                }
                                .background(Color.white.opacity(0.045))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .borderBeam(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous),
                                    active: true,
                                    lineWidth: 1.4,
                                    duration: 3.5,
                                    intensity: 0.75
                                )
                                .padding(.horizontal)
                            } else {
                                ScrollView(showsIndicators: false) {
                                    VStack(spacing: 14) {
                                        // Hero Plate Card
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "checkmark.seal.fill")
                                                        .foregroundColor(primaryAccent)
                                                    Text("OFFICIAL RC RECORD")
                                                        .font(.system(size: 10, weight: .heavy))
                                                        .tracking(1.5)
                                                        .foregroundColor(.white.opacity(0.65))
                                                }
                                                Spacer()
                                                Text("ACTIVE")
                                                    .font(.system(size: 10, weight: .heavy))
                                                    .padding(.horizontal, 9)
                                                    .padding(.vertical, 4)
                                                    .background(Color.green.opacity(0.2))
                                                    .foregroundColor(.green)
                                                    .clipShape(Capsule())
                                            }

                                            // Number Plate Display with Modern Copy Pill
                                            HStack {
                                                Text(searchedPlate.isEmpty ? vehicleNumber.uppercased() : searchedPlate)
                                                    .font(.system(size: 24, weight: .black, design: .monospaced))
                                                    .tracking(2)
                                                    .foregroundColor(.white)
                                                Spacer()
                                                Button {
                                                    let plate = searchedPlate.isEmpty ? vehicleNumber.uppercased() : searchedPlate
                                                    UIPasteboard.general.string = plate
                                                    showToast("Copied \(plate)")
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "doc.on.doc")
                                                        Text("Copy")
                                                    }
                                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.9))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.white.opacity(0.1))
                                                    .clipShape(Capsule())
                                                }
                                                .buttonStyle(ModernPillButtonStyle())
                                            }
                                            .padding(12)
                                            .background(Color.black.opacity(0.38))
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                            )

                                            // Top Highlight Grid
                                            if !highlightItems.isEmpty {
                                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                                    ForEach(highlightItems) { info in
                                                        Button {
                                                            UIPasteboard.general.string = info.value
                                                            showToast("Copied \(info.key)")
                                                        } label: {
                                                            VStack(alignment: .leading, spacing: 5) {
                                                                HStack(spacing: 5) {
                                                                    Image(systemName: info.icon)
                                                                        .font(.caption2)
                                                                        .foregroundColor(primaryAccent)
                                                                    Text(info.key)
                                                                        .font(.system(size: 10, weight: .bold))
                                                                        .foregroundColor(.white.opacity(0.55))
                                                                        .lineLimit(1)
                                                                }
                                                                Text(info.value)
                                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                                    .foregroundColor(.white)
                                                                    .lineLimit(2)
                                                                    .multilineTextAlignment(.leading)
                                                            }
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                            .padding(11)
                                                            .background(Color.white.opacity(0.055))
                                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                                            )
                                                        }
                                                        .buttonStyle(ModernPillButtonStyle())
                                                    }
                                                }
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    primaryAccent.opacity(0.16),
                                                    Color.white.opacity(0.04)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                        .borderBeam(
                                            RoundedRectangle(cornerRadius: 22, style: .continuous),
                                            active: true,
                                            lineWidth: 1.5,
                                            duration: 3.2,
                                            intensity: 0.85
                                        )

                                        // Complete Specifications Cards
                                        if !detailItems.isEmpty {
                                            VStack(alignment: .leading, spacing: 9) {
                                                Text("COMPLETE SPECIFICATIONS (\(detailItems.count))")
                                                    .font(.system(size: 10, weight: .heavy))
                                                    .tracking(1.5)
                                                    .foregroundColor(.white.opacity(0.5))
                                                    .padding(.horizontal, 4)

                                                VStack(spacing: 8) {
                                                    ForEach(detailItems) { item in
                                                        Button {
                                                            UIPasteboard.general.string = item.value
                                                            showToast("Copied \(item.key)")
                                                        } label: {
                                                            HStack(spacing: 12) {
                                                                ZStack {
                                                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                                                        .fill(primaryAccent.opacity(0.14))
                                                                        .frame(width: 38, height: 38)
                                                                    Image(systemName: item.icon)
                                                                        .font(.system(size: 14, weight: .bold))
                                                                        .foregroundColor(primaryAccent)
                                                                }

                                                                VStack(alignment: .leading, spacing: 3) {
                                                                    Text(item.key)
                                                                        .font(.system(size: 11, weight: .semibold))
                                                                        .foregroundColor(.white.opacity(0.55))

                                                                    Text(item.value)
                                                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                                                        .foregroundColor(.white)
                                                                        .multilineTextAlignment(.leading)
                                                                }

                                                                Spacer()

                                                                Image(systemName: "doc.on.doc")
                                                                    .font(.system(size: 12, weight: .semibold))
                                                                    .foregroundColor(.white.opacity(0.35))
                                                                    .padding(8)
                                                                    .background(Color.white.opacity(0.05))
                                                                    .clipShape(Circle())
                                                            }
                                                            .padding(12)
                                                            .background(Color.white.opacity(0.045))
                                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                                            )
                                                        }
                                                        .buttonStyle(ModernPillButtonStyle())
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 28)
                                }
                            }
                        }
                    } else if !isLoading && errorMessage == nil {
                        Spacer()
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 82, height: 82)
                                    .borderBeam(Circle(), active: true, lineWidth: 1.6, duration: 3.0)

                                Image(systemName: "car.side.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(primaryAccent)
                            }

                            Text("Ready for Lookup")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.95))

                            Text("വാഹന നമ്പർ നൽകി Search Vehicle Details അമർത്തുക\nകാർഡുകൾ ടാപ്പ് ചെയ്ത് വിവരങ്ങൾ കോപ്പി ചെയ്യാം")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        Spacer()
                    }
                }

                // Floating Glass Toast Notification
                if let toast = copiedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(toast)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(.ultraThinMaterial)
                        .background(Color(red: 0.12, green: 0.14, blue: 0.20).opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.45), radius: 14, y: 6)
                        .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .preferredColorScheme(.dark)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // Custom Sliding Pill Tab Button
    @ViewBuilder
    private func tabButton(title: String, icon: String, isRawTab: Bool) -> some View {
        let isActive = (showRaw == isRawTab)
        Button {
            let gen = UISelectionFeedbackGenerator()
            gen.selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                showRaw = isRawTab
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundColor(isActive ? .white : .white.opacity(0.55))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isActive {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [primaryAccent.opacity(0.85), secondaryAccent.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .matchedGeometryEffect(id: "ACTIVE_TAB", in: tabNamespace)
                            .shadow(color: primaryAccent.opacity(0.35), radius: 6, y: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private func showToast(_ message: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            copiedToast = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation {
                if copiedToast == message {
                    copiedToast = nil
                }
            }
        }
    }

    private func copyAllResults() {
        UIPasteboard.general.string = formattedShareText
        showToast("All details copied!")
    }

    private func iconForKey(_ lowerKey: String) -> String {
        if lowerKey.contains("owner") || lowerKey.contains("name") { return "person.fill" }
        if lowerKey.contains("model") || lowerKey.contains("maker") || lowerKey.contains("brand") { return "car.fill" }
        if lowerKey.contains("fuel") { return "fuelpump.fill" }
        if lowerKey.contains("rto") || lowerKey.contains("city") || lowerKey.contains("state") || lowerKey.contains("address") { return "mappin.and.ellipse" }
        if lowerKey.contains("insurance") || lowerKey.contains("policy") { return "shield.checkered" }
        if lowerKey.contains("date") || lowerKey.contains("expiry") || lowerKey.contains("validity") || lowerKey.contains("year") { return "calendar" }
        if lowerKey.contains("engine") || lowerKey.contains("chassis") || lowerKey.contains("vin") { return "gearshape.2.fill" }
        if lowerKey.contains("color") || lowerKey.contains("colour") { return "paintpalette.fill" }
        if lowerKey.contains("status") || lowerKey.contains("class") || lowerKey.contains("category") { return "tag.fill" }
        return "info.circle.fill"
    }

    private func isPriorityKey(_ lowerKey: String) -> Bool {
        let keywords = ["owner", "model", "maker", "brand", "fuel", "rto", "class", "category", "status", "insurance"]
        return keywords.contains { lowerKey.contains($0) }
    }

    func fetchVehicleDetails() {
        let cleaned = vehicleNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        guard !cleaned.isEmpty else {
            withAnimation {
                errorMessage = "ദയവായി ഒരു വാഹന നമ്പർ നൽകുക (ഉദാ: KL55A9200)"
            }
            return
        }

        searchedPlate = cleaned
        isInputFocused = false
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation {
            isLoading = true
            errorMessage = nil
            items = []
            rawResponse = ""
        }

        guard let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://rc2numv2.drazexosint.workers.dev/fetch?vehicle=\(encoded)") else {
            isLoading = false
            errorMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isLoading = false

                    if let error = error {
                        errorMessage = "Network Error: \(error.localizedDescription)"
                        return
                    }

                    if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                        errorMessage = "Server Error: HTTP \(httpResponse.statusCode)"
                        return
                    }

                    guard let data = data, !data.isEmpty else {
                        errorMessage = "API-യിൽ നിന്ന് ഡാറ്റ ലഭിച്ചില്ല."
                        return
                    }

                    rawResponse = String(data: data, encoding: .utf8) ?? ""

                    do {
                        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                        var extracted: [KeyValueItem] = []
                        flattenJSON(jsonObject, prefix: "", into: &extracted)

                        if extracted.isEmpty {
                            errorMessage = "ഈ നമ്പറിൽ വിവരങ്ങൾ ലഭ്യമല്ല."
                        } else {
                            items = extracted
                        }
                    } catch {
                        showRaw = true
                    }
                }
            }
        }.resume()
    }

    func flattenJSON(_ value: Any, prefix: String, into list: inout [KeyValueItem]) {
        if let dict = value as? [String: Any] {
            for (k, v) in dict.sorted(by: { $0.key < $1.key }) {
                let cleanKey = k.replacingOccurrences(of: "_", with: " ").capitalized
                let newPrefix = prefix.isEmpty ? cleanKey : "\(prefix) • \(cleanKey)"
                flattenJSON(v, prefix: newPrefix, into: &list)
            }
        } else if let array = value as? [Any] {
            for (index, element) in array.enumerated() {
                let newPrefix = "\(prefix) #\(index + 1)"
                flattenJSON(element, prefix: newPrefix, into: &list)
            }
        } else {
            let strVal = "\(value)"
            if !strVal.isEmpty && strVal != "<null>" {
                let title = prefix.isEmpty ? "Result" : prefix
                let lower = title.lowercased()
                list.append(
                    KeyValueItem(
                        rawKey: title,
                        key: title,
                        value: strVal,
                        icon: iconForKey(lower),
                        isImportant: isPriorityKey(lower)
                    )
                )
            }
        }
    }
}
