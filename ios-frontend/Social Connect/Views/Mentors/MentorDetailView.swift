import SwiftUI

struct MentorDetailView: View {
    private let authManager: AuthManager
    private let mentorId: String
    private let name: String
    private let tagApiUrl = "\(VIDEO_BASE_URL)/tag/" // API for fetching tag names

    @State private var mentor: MentorDetail?
    @State private var tagNames: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    init(authManager: AuthManager, mentorId: String, name:String) {
        self.authManager = authManager
        self.mentorId = mentorId
        self.name = name
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Mentor Details...")
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if let mentor = mentor {
                VStack(alignment: .leading, spacing: 20) {
                    Text(name)
                        .font(.title)
                        .bold()

                    Text("Field of Interest: \(mentor.fieldOfInterest)")
                        .font(.headline)

                    Text("Experience: \(mentor.experience) years")
                        .font(.headline)

                    Text("Bio: \(mentor.bio)")
                        .font(.body)

                    if !tagNames.isEmpty {
                        Text("Tags:")
                            .font(.headline)
                        ForEach(tagNames, id: \.self) { tag in
                            Text(tag)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear(perform: fetchMentorDetails)
        .navigationBarTitle("Mentor Details", displayMode: .inline)
    }

    private func fetchMentorDetails() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors/\(mentorId)") else {
            errorMessage = "Invalid API URL."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authManager.getBearerToken() ?? "")", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = "Error fetching mentor details: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }

                do {
                    let fetchedMentor = try JSONDecoder().decode(MentorDetail.self, from: data)
                    self.mentor = fetchedMentor
                    fetchTagNames(for: fetchedMentor.tags)
                } catch {
                    errorMessage = "Error decoding mentor details: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func fetchTagNames(for tagIds: [String]) {
        guard let url = URL(string: tagApiUrl) else {
            errorMessage = "Invalid Tag API URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Error fetching tag names: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received for tags."
                    return
                }

                do {
                    let fetchedTags = try JSONDecoder().decode([Tag].self, from: data)
                    self.tagNames = fetchedTags
                        .filter { tagIds.contains($0.id) }
                        .map { $0.name }
                } catch {
                    errorMessage = "Error decoding tag names: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct MentorDetail: Decodable {
    let id: String
    let userId: String
    let fieldOfInterest: String
    let experience: String
    let bio: String
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case fieldOfInterest
        case experience
        case bio
        case tags
    }
}

//#Preview {
//    MentorDetailView(authManager: AuthManager(dummy: true), mentorId:"674c0427cd5324f313835081")
//}
