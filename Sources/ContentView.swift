import SwiftUI

struct KeyValueItem: Identifiable {
    let id = UUID()
    let rawKey: String
    let key: String
    let value: String
    let icon: String
    let isImportant: Bool
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

    var body: some View {
        NavigationStack {
            ZStack {
                // Deep Pro Background
                Color(red: 0.04, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()

                // Ambient Glows
                VStack {
                    RadialGradient(
                        colors: [primaryAccent.opacity(0.22), Color.clear],
                        center: .top,
                        startRadius: 10,
                        endRadius: 360
                    )
                    .frame(height: 360)
                    Spacer()
                }
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Header & Theme Selector
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(primaryAccent)
                                    .frame(width: 7, height: 7)
                                Text("SMART RC LOOKUP")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.8)
                                    .foregroundColor(primaryAccent)
                            }

                            Text("Vehicle Info Pro")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        Spacer()

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
                                    .frame(width: 13, height: 13)
                                Text(BeamPalette.options.first(where: { $0.key == paletteKey })?.title ?? "Neon")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Search Input Card
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .foregroundColor(primaryAccent)
                                .font(.system(size: 20))

                            TextField("", text: $vehicleNumber, prompt: Text("Enter RC Number (e.g. KL55A9200)").foregroundColor(.white.opacity(0.35)))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled(true)
                                .font(.system(size: 17, weight: .bold, design: .monospaced))
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
                                        .foregroundColor(.white.opacity(0.45))
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
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

                        Button(action: fetchVehicleDetails) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Fetching Vehicle Data...")
                                        .fontWeight(.semibold)
                                } else {
                                    Image(systemName: "bolt.shield.fill")
                                    Text("Lookup Vehicle")
                                        .fontWeight(.bold)
                                }
                            }
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                LinearGradient(
                                    colors: [primaryAccent.opacity(0.9), secondaryAccent.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: primaryAccent.opacity(0.35), radius: 12, y: 5)
                        }
                        .buttonStyle(GlowPressStyle(shape: RoundedRectangle(cornerRadius: 14, style: .continuous)))
                        .disabled(isLoading)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Error Banner
                    if let errorMessage = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.92))
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
                    }

                    // Pro Results View
                    if !items.isEmpty || !rawResponse.isEmpty {
                        VStack(spacing: 12) {
                            // Mode Switcher & Copy All Button
                            HStack(spacing: 10) {
                                Picker("View", selection: $showRaw) {
                                    Text("Pro Card View").tag(false)
                                    Text("Raw JSON").tag(true)
                                }
                                .pickerStyle(.segmented)

                                Button {
                                    copyAllResults()
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: "doc.on.doc.fill")
                                        Text("Copy All")
                                    }
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                }
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
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .borderBeam(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous),
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
                                                HStack(spacing: 8) {
                                                    Image(systemName: "rectangle.and.text.magnifyingglass")
                                                        .foregroundColor(primaryAccent)
                                                    Text("REGISTRATION PLATE")
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                        .tracking(1.5)
                                                        .foregroundColor(.white.opacity(0.6))
                                                }
                                                Spacer()
                                                Text("VERIFIED DATA")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(primaryAccent.opacity(0.18))
                                                    .foregroundColor(primaryAccent)
                                                    .clipShape(Capsule())
                                            }

                                            // Number Plate Display
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
                                                    Image(systemName: "copy")
                                                        .foregroundColor(.white.opacity(0.75))
                                                        .padding(8)
                                                        .background(Color.white.opacity(0.08))
                                                        .clipShape(Circle())
                                                }
                                            }
                                            .padding(12)
                                            .background(Color.black.opacity(0.35))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                            )

                                            // Top Highlight Mini-Grid
                                            if !highlightItems.isEmpty {
                                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                                    ForEach(highlightItems) { info in
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            HStack(spacing: 5) {
                                                                Image(systemName: info.icon)
                                                                    .font(.caption2)
                                                                    .foregroundColor(primaryAccent)
                                                                Text(info.key)
                                                                    .font(.system(size: 10, weight: .semibold))
                                                                    .foregroundColor(.white.opacity(0.55))
                                                                    .lineLimit(1)
                                                            }
                                                            Text(info.value)
                                                                .font(.caption)
                                                                .fontWeight(.bold)
                                                                .foregroundColor(.white)
                                                                .lineLimit(2)
                                                        }
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .padding(10)
                                                        .background(Color.white.opacity(0.05))
                                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                    }
                                                }
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    primaryAccent.opacity(0.14),
                                                    Color.white.opacity(0.04)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                        .borderBeam(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous),
                                            active: true,
                                            lineWidth: 1.5,
                                            duration: 3.2,
                                            intensity: 0.85
                                        )

                                        // All Other Details Section
                                        if !detailItems.isEmpty {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("COMPLETE SPECIFICATIONS (\(detailItems.count))")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .tracking(1.4)
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
                                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                                        .fill(primaryAccent.opacity(0.12))
                                                                        .frame(width: 36, height: 36)
                                                                    Image(systemName: item.icon)
                                                                        .font(.system(size: 14, weight: .semibold))
                                                                        .foregroundColor(primaryAccent)
                                                                }

                                                                VStack(alignment: .leading, spacing: 3) {
                                                                    Text(item.key)
                                                                        .font(.system(size: 11, weight: .semibold))
                                                                        .foregroundColor(.white.opacity(0.55))

                                                                    Text(item.value)
                                                                        .font(.subheadline)
                                                                        .fontWeight(.semibold)
                                                                        .foregroundColor(.white)
                                                                        .multilineTextAlignment(.leading)
                                                                }

                                                                Spacer()

                                                                Image(systemName: "doc.on.doc")
                                                                    .font(.caption)
                                                                    .foregroundColor(.white.opacity(0.28))
                                                            }
                                                            .padding(12)
                                                            .background(Color.white.opacity(0.045))
                                                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                                            )
                                                        }
                                                        .buttonStyle(.plain)
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
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 78, height: 78)
                                    .borderBeam(Circle(), active: true, lineWidth: 1.5, duration: 3.0)

                                Image(systemName: "car.side.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(primaryAccent)
                            }

                            Text("Ready for Lookup")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.92))

                            Text("വാഹന നമ്പർ നൽകി Lookup Vehicle അമർത്തുക\nകാർഡുകൾ ടാപ്പ് ചെയ്ത് വിവരങ്ങൾ കോപ്പി ചെയ്യാം")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        Spacer()
                    }
                }

                // Toast Notification
                if let toast = copiedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(toast)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.14, green: 0.16, blue: 0.22))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 12, y: 5)
                        .padding(.bottom, 22)
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
        let header = searchedPlate.isEmpty ? "" : "Vehicle: \(searchedPlate)\n"
        let bodyText = items.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        let combined = header + bodyText
        UIPasteboard.general.string = combined.isEmpty ? rawResponse : combined
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
