import SwiftUI

struct MentorListView: View {
    private let authManager: AuthManager
    private let bearerToken: String

    @State private var connectedMentors: [MentorModel] = []
    @State private var isMentor: Bool = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    init(authManager: AuthManager) {
        self.authManager = authManager
        self.bearerToken = authManager.getBearerToken() ?? ""
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading && connectedMentors.isEmpty {
                    ProgressView("Loading...")
                } else {
                    VStack(spacing: 10) { // Ensure spacing between sections
                        // Navigation Links Section
                        Section {
                            Divider()
                            if isMentor {
                                NavigationLink(destination: RequestedConnectionsView(authManager: authManager)) {
                                    HStack {
                                        Text("See Requested Connections")
                                            .foregroundColor(.black)
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                            .fontWeight(.heavy)
                                    }
                                }
                                .padding(.top, 10)
                            } else {
                                NavigationLink(destination: BecomeMentorView(authManager: authManager)) {
                                    HStack {
                                        Text("Become a Mentor")
                                            .foregroundColor(.black)
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.green)
                                            .fontWeight(.heavy)
                                    }
                                }
                                .padding(.top, 10)
                            }

                            Divider()

                            NavigationLink(destination: AllMentorsView(authManager: authManager)) {
                                HStack {
                                    Text("All Mentors")
                                        .foregroundColor(.black)
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.red)
                                        .fontWeight(.heavy)
                                }
                            }
                            .padding(.top, 10)
                            Divider()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                        // My Mentors Section
                        VStack {
                            Text("My Chats")
                                .font(.headline)
                                .padding(.horizontal)

                            if connectedMentors.isEmpty {
                                Text("No mentors connected yet.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                List(connectedMentors) { mentor in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(mentor.name ?? "Unknown")
                                                .font(.headline)
                                            if (mentor.bio != ""){
                                                Text(mentor.fieldOfInterest)
                                                    .font(.subheadline)
                                                Text("Experience: \(mentor.experience) years")
                                                    .font(.caption)
                                                Text(mentor.bio)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .lineLimit(2)
                                            } else {
                                                Text("Not yet a mentor")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                                    .lineLimit(2)
                                            }
                                        }
                                        Spacer()
                                        NavigationLink(destination: ChatView(authManager: authManager, chatWithId: mentor.userId, chatWithName: mentor.name ?? "mentor")) {
                                            Text("Chat")
                                                .foregroundColor(.white) // Text color
                                                .padding(8)              // Padding around the text
                                                .background(Color.green) // Background color
                                                .cornerRadius(8)        // Rounded corners
                                                .frame(maxWidth: .infinity) // Make the button take the full width
                                        }
                                        .buttonStyle(BorderedProminentButtonStyle())
                                        .frame(width: 120)
                                    }
                                    .padding(.vertical, 5)
                                }
                                .listStyle(PlainListStyle())
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top) // Ensure all content aligns to top
                }
            }
            .navigationBarTitle("Mentors", displayMode: .large)
            .onAppear(perform: loadMentorData)
        }
    }

    private func loadMentorData() {
        isLoading = true
        errorMessage = nil

        checkIfMentor { isMentorResult in
            self.isMentor = isMentorResult
            fetchConnectedMentors()
        }
    }

    private func checkIfMentor(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors/is-mentor") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                completion(false)
                return
            }

            do {
                let response = try JSONDecoder().decode(IsMentorResponse.self, from: data)
                completion(response.isMentor)
            } catch {
                completion(false)
            }
        }.resume()
    }

    private func fetchConnectedMentors() {
        isLoading = false
        errorMessage = nil

        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors/connected") else {
            errorMessage = "Invalid API URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                self.errorMessage = "Error fetching mentors: \(error.localizedDescription)"
                return
            }

            guard let data = data else {
                self.errorMessage = "No data received."
                return
            }

            do {
                self.connectedMentors = try JSONDecoder().decode([MentorModel].self, from: data)
            } catch {
                self.errorMessage = "Error decoding mentors: \(error.localizedDescription)"
            }
        }.resume()
    }
}

struct MentorModel: Identifiable, Decodable {
    let id: String
    let userId: String
    let fieldOfInterest: String
    let experience: String
    let bio: String
    var name: String?
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



struct IsMentorResponse: Decodable {
    let isMentor: Bool
}

#Preview {
    MentorListView(authManager: AuthManager(dummy: true))
}
