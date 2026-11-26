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

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Input Section
                HStack(spacing: 10) {
                    TextField("Enter Number (e.g. DL9C0001)", text: $vehicleNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .submitLabel(.search)
                        .onSubmit {
                            fetchVehicleDetails()
                        }

                    Button(action: fetchVehicleDetails) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 60)
                        } else {
                            Text("Search")
                                .fontWeight(.semibold)
                                .frame(width: 60)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                // Results Section
                if !items.isEmpty || !rawResponse.isEmpty {
                    Picker("View Mode", selection: $showRaw) {
                        Text("Details").tag(false)
                        Text("Raw JSON").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if showRaw {
                        ScrollView {
                            Text(rawResponse)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        List(items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.key)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Text(item.value)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 2)
                        }
                        .listStyle(.insetGrouped)
                    }
                } else if !isLoading && errorMessage == nil {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue.opacity(0.7))
                        Text("വാഹന നമ്പർ നൽകി Search അമർത്തുക")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    Spacer()
                } else {
                    Spacer()
                }
            }
            .navigationTitle("Vehicle RC Finder")
        }
    }

    func fetchVehicleDetails() {
        let cleaned = vehicleNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        guard !cleaned.isEmpty else {
            errorMessage = "ദയവായി ഒരു വാഹന നമ്പർ നൽകുക (ഉദാ: DL9C0001)"
            return
        }

        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        isLoading = true
        errorMessage = nil
        items = []
        rawResponse = ""

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
                    // JSON അല്ലെങ്കിൽ Raw Text കാണിക്കാൻ സജ്ജമാക്കുന്നു
                    showRaw = true
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
