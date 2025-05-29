import SwiftUI

struct AllMentorsView: View {
    private let authManager: AuthManager
    private let bearerToken: String

    @State private var mentors: [Mentor2] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var searchQuery: String = ""

    init(authManager: AuthManager) {
        self.authManager = authManager
        self.bearerToken = authManager.getBearerToken() ?? ""
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                // Title
                Text("All Mentors")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top, 20)

                // Search Bar
                HStack {
                    TextField("Search mentors...", text: $searchQuery, onCommit: searchMentors)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)

                    if !searchQuery.isEmpty {
                        Button(action: clearSearch) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 10)
                        }
                    }
                }
                .padding(.bottom, 10)

                // Main Content
                ZStack(alignment: .top) {
                    // Loading Indicator
                    if isLoading && mentors.isEmpty {
                        ProgressView("Loading Mentors...")
                            .frame(maxWidth: .infinity, alignment: .top)
                            .padding(.top, 20)
                    } else if let errorMessage = errorMessage {
                        // Error Message
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        // Mentor List
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(mentors) { mentor in
                                    NavigationLink(
                                        destination: MentorDetailView(
                                            authManager: authManager,
                                            mentorId: mentor.id,
                                            name: mentor.name
                                        )
                                    ) {
                                        MentorRow( authManager: authManager, mentor: mentor, onAction: {
                                            handleConnectionAction(for: mentor)
                                        })
                                        .padding(.horizontal)
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(12)
                                        .shadow(color: Color.gray.opacity(0.1), radius: 2, x: 0, y: 2)
                                        .padding(.horizontal)
                                    }
                                    
                                }
                            }
                            .padding(.top, 10)
                            .padding(.horizontal)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top) // Fix components to the top
            }
            .navigationBarHidden(true)
            .onAppear(perform: fetchMentors)
            .refreshable(action: fetchMentors)
        }
    }

    private func fetchMentors() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors") else {
            errorMessage = "Invalid API URL."
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
                    errorMessage = "Error fetching mentors: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }

                do {
                    let fetchedMentors = try JSONDecoder().decode([Mentor2].self, from: data)
                    self.mentors = fetchedMentors
                } catch {
                    errorMessage = "Error decoding mentors: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func searchMentors() {
        guard !searchQuery.isEmpty else {
            fetchMentors()
            return
        }

        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors/search?query=\(searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            errorMessage = "Invalid Search URL."
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
                    errorMessage = "Error searching mentors: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }

                do {
                    let fetchedMentors = try JSONDecoder().decode([Mentor2].self, from: data)
                    self.mentors = fetchedMentors
                } catch {
                    errorMessage = "Error decoding search results: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func clearSearch() {
        searchQuery = ""
        fetchMentors()
    }

    private func handleConnectionAction(for mentor: Mentor2) {
        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors/connect") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["mentorId": mentor.userId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { _, response, _ in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error toggling connection")
                return
            }
            fetchMentors()
        }.resume()
    }
}

struct MentorRow: View {
    let authManager: AuthManager
    let mentor: Mentor2
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text(mentor.name)
                    .font(.headline)
                    .bold()

                Text(mentor.fieldOfInterest)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Experience: \(mentor.experience) years")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(mentor.bio)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            if mentor.status != "accepted" {
                Button(action: onAction) {
                    Text(mentor.status == "none"
                        ? "Connect"
                        : mentor.status == "pending"
                        ? "Cancel Request"
                        : mentor.status == "rejected"
                        ? "Reconnect"
                        : "Waiting")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(mentor.status == "none" || mentor.status == "rejected"
                            ? Color.blue
                            : Color.red)
                        .cornerRadius(8)
                        .frame(width: 120)
                }
                .disabled(mentor.status == "waiting to accept")
                .buttonStyle(PlainButtonStyle()) // Prevent blue styling
            } else {
                NavigationLink(destination: ChatView(authManager: authManager, chatWithId: mentor.userId, chatWithName: mentor.name)) {
                    Text("Chat")
                        .foregroundColor(.white) // Text color
                        .padding(8)              // Padding around the text
                        .background(Color.green) // Background color
                        .cornerRadius(8)        // Rounded corners
                        .frame(maxWidth: .infinity) // Make the button take the full width
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 120)
            }
        }
        .padding(.leading, 4)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6)) // Make the entire mentor row gray
        )
    }
}

struct Mentor2: Identifiable, Decodable {
    let id: String
    let userId: String
    let fieldOfInterest: String
    let experience: String
    let bio: String
    var name: String
    var status: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case fieldOfInterest
        case experience
        case bio
        case name
        case status
    }
}


#Preview {
    AllMentorsView(authManager: AuthManager(dummy: true))
}
