import SwiftUI

struct BecomeMentorView: View {
    private let authManager: AuthManager
    private let bearerToken: String
    private let tagApiUrl = "\(VIDEO_BASE_URL)/tag/" // API URL for fetching tags

    @State private var fieldOfInterest = ""
    @State private var experience = ""
    @State private var bio = ""
    @State private var selectedTags: [MentorTag] = []
    @State private var tags: [MentorTag] = []
    @State private var showTagsPicker = false
    @State private var isLoading = false
    @State private var successMessage: String? = nil
    @State private var errorMessage: String? = nil

    init(authManager: AuthManager) {
        self.authManager = authManager
        self.bearerToken = authManager.getBearerToken() ?? ""
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading...")
                } else if let successMessage = successMessage {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.green)
                        
                        Text("Congratulations!")
                            .font(.largeTitle)
                            .bold()
                        
                        Text(successMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Button("Back") {
                            self.successMessage = nil // Reset state to allow re-entry
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Become a Mentor")
                                .font(.title)
                                .bold()

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Field of Interest")
                                    .font(.headline)
                                TextField("Enter your field of interest", text: $fieldOfInterest)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Years of Experience")
                                    .font(.headline)
                                TextField("Enter years of experience", text: $experience)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Bio")
                                    .font(.headline)
                                TextEditor(text: $bio)
                                    .frame(height: 100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Tags")
                                    .font(.headline)
                                Button(action: {
                                    showTagsPicker.toggle()
                                }) {
                                    HStack {
                                        Text(selectedTags.isEmpty ? "Select Tags" : selectedTags.map { $0.name }.joined(separator: ", "))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                                .sheet(isPresented: $showTagsPicker) {
                                    TagSelectionView(tags: tags, selectedTags: $selectedTags)
                                }
                            }

                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            Button(action: registerAsMentor) {
                                Text("Register as Mentor")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: fetchTags)
        }
    }

    private func fetchTags() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: tagApiUrl) else {
            errorMessage = "Invalid Tag API URL."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = "Error fetching tags: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }

                do {
                    let fetchedTags = try JSONDecoder().decode([MentorTag].self, from: data)
                    self.tags = fetchedTags
                } catch {
                    errorMessage = "Error decoding tags: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func registerAsMentor() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors/register") else {
            errorMessage = "Invalid API URL."
            isLoading = false
            return
        }

        let selectedTagIds = selectedTags.map { $0.id }
        let body: [String: Any] = [
            "fieldOfInterest": fieldOfInterest,
            "experience": experience,
            "bio": bio,
            "tags": selectedTagIds
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            errorMessage = "Error serializing JSON: \(error.localizedDescription)"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = "Error registering as mentor: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "Failed to register as mentor."
                    return
                }

                // Successful registration
                successMessage = "You are now a mentor!"
            }
        }.resume()
    }
}

struct TagSelectionView: View {
    let tags: [MentorTag]
    @Binding var selectedTags: [MentorTag]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List(tags) { tag in
                Button(action: {
                    toggleTagSelection(tag: tag)
                }) {
                    HStack {
                        Text(tag.name)
                        Spacer()
                        if selectedTags.contains(where: { $0.id == tag.id }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func toggleTagSelection(tag: MentorTag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

struct MentorTag: Identifiable, Decodable {
    let id: String
    let name: String
}

#Preview {
    BecomeMentorView(authManager: AuthManager(dummy: true))
}
