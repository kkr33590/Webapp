import SwiftUI

struct KeyValueItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

struct ContentView: View {
    @State private var vehicleNumber: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var items: [KeyValueItem] = []
    @State private var rawResponse: String = ""
    @State private var showRaw: Bool = false
    @State private var copiedToast: String? = nil

    @FocusState private var isInputFocused: Bool
    @AppStorage("beam_enabled") private var beamEnabled = true
    @AppStorage("beam_palette") private var paletteKey = "neon"

    private var activeColors: [Color] {
        BeamPalette.named(paletteKey)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Sleek Dark Background
                Color(red: 0.05, green: 0.06, blue: 0.09)
                    .ignoresSafeArea()

                // Ambient Top Glow
                RadialGradient(
                    colors: [
                        (activeColors.first ?? .blue).opacity(0.18),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 20,
                    endRadius: 340
                )
                .ignoresSafeArea()

                VStack(spacing: 18) {
                    // Header & Theme Controls
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RC FINDER")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .tracking(2)
                                .foregroundColor(activeColors.first ?? .cyan)

                            Text("Vehicle Lookup")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Palette Selector Menu
                        Menu {
                            Section("Beam Theme") {
                                ForEach(BeamPalette.options, id: \.key) { option in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            paletteKey = option.key
                                        }
                                    } label: {
                                        HStack {
                                            Text(option.title)
                                            if paletteKey == option.key {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                            Divider()
                            Button {
                                withAnimation {
                                    beamEnabled.toggle()
                                }
                            } label: {
                                Label(
                                    beamEnabled ? "Disable Glow Beam" : "Enable Glow Beam",
                                    systemImage: beamEnabled ? "sparkles" : "sparkle"
                                )
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: activeColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 12, height: 12)
                                Text(BeamPalette.options.first(where: { $0.key == paletteKey })?.title ?? "Neon")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Search Card with Border Beam
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "car.front.waves.up")
                                .foregroundColor(activeColors.first ?? .cyan)
                                .font(.system(size: 18))

                            TextField("", text: $vehicleNumber, prompt: Text("e.g. KL55A9200").foregroundColor(.white.opacity(0.35)))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled(true)
                                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .focused($isInputFocused)
                                .submitLabel(.search)
                                .onSubmit {
                                    fetchVehicleDetails()
                                }

                            if !vehicleNumber.isEmpty {
                                Button {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        vehicleNumber = ""
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .borderBeam(
                            RoundedRectangle(cornerRadius: 14, style: .continuous),
                            active: isInputFocused || isLoading,
                            lineWidth: 1.8,
                            duration: isLoading ? 1.2 : 2.8
                        )

                        // Smooth Gradient Search Button with GlowPressStyle
                        Button(action: fetchVehicleDetails) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Fetching Details...")
                                        .fontWeight(.semibold)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .fontWeight(.bold)
                                    Text("Search Vehicle")
                                        .fontWeight(.bold)
                                }
                            }
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        (activeColors.first ?? .blue).opacity(0.85),
                                        (activeColors.last ?? .purple).opacity(0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: (activeColors.first ?? .blue).opacity(0.35), radius: 10, y: 4)
                        }
                        .buttonStyle(GlowPressStyle(shape: RoundedRectangle(cornerRadius: 14, style: .continuous)))
                        .disabled(isLoading)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Error Box
                    if let errorMessage = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.red.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.red.opacity(0.35), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Results Area
                    if !items.isEmpty || !rawResponse.isEmpty {
                        VStack(spacing: 12) {
                            HStack {
                                Picker("Mode", selection: $showRaw) {
                                    Text("Details").tag(false)
                                    Text("Raw JSON").tag(true)
                                }
                                .pickerStyle(.segmented)

                                Button {
                                    copyAllResults()
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(9)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                            .padding(.horizontal)

                            if showRaw {
                                ScrollView {
                                    Text(rawResponse)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.85))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(16)
                                        .textSelection(.enabled)
                                }
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .borderBeam(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous),
                                    active: true,
                                    lineWidth: 1.4,
                                    duration: 3.5,
                                    intensity: 0.7
                                )
                                .padding(.horizontal)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 10) {
                                        ForEach(items) { item in
                                            Button {
                                                UIPasteboard.general.string = item.value
                                                showToast("Copied \(item.key)")
                                            } label: {
                                                HStack(alignment: .center, spacing: 12) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(item.key)
                                                            .font(.caption2)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.white.opacity(0.5))
                                                            .textCase(.uppercase)

                                                        Text(item.value)
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.white)
                                                            .multilineTextAlignment(.leading)
                                                    }
                                                    Spacer()
                                                    Image(systemName: "doc.on.doc")
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.25))
                                                }
                                                .padding(14)
                                                .background(Color.white.opacity(0.05))
                                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 20)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else if !isLoading && errorMessage == nil {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 76, height: 76)
                                    .borderBeam(Circle(), active: true, lineWidth: 1.5, duration: 3.0)

                                Image(systemName: "car.side.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(activeColors.first ?? .cyan)
                            }

                            Text("Ready to Search")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))

                            Text("വാഹനത്തിന്റെ രജിസ്ട്രേഷൻ നമ്പർ നൽകി\nSearch Vehicle അമർത്തുക")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        Spacer()
                    }
                }

                // Copy Toast Notification
                if let toast = copiedToast {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(radius: 10)
                            .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .preferredColorScheme(.dark)
            .toolbar(.hidden, for: .navigationBar)
        }
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
        let combined = items.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        UIPasteboard.general.string = combined.isEmpty ? rawResponse : combined
        showToast("All details copied!")
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
                let cleanKey = k.replacingOccurrences(of: "_", with: " ")
                let newPrefix = prefix.isEmpty ? cleanKey : "\(prefix) - \(cleanKey)"
                flattenJSON(v, prefix: newPrefix, into: &list)
            }
        } else if let array = value as? [Any] {
            for (index, element) in array.enumerated() {
                let newPrefix = "\(prefix) [\(index + 1)]"
                flattenJSON(element, prefix: newPrefix, into: &list)
            }
        } else {
            let strVal = "\(value)"
            if !strVal.isEmpty && strVal != "<null>" {
                list.append(KeyValueItem(key: prefix.isEmpty ? "Result" : prefix, value: strVal))
            }
        }
    }
}
