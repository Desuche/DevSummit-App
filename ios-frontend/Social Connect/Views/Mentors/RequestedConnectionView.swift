import SwiftUI

struct RequestedConnectionsView: View {
    private let authManager: AuthManager
    private let bearerToken: String

    @State private var pendingConnections: [PendingConnection] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    init(authManager: AuthManager) {
        self.authManager = authManager
        self.bearerToken = authManager.getBearerToken() ?? ""
    }

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Requests...")
                        .padding(.top, 20)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Requested Connections")
                                .font(.title)
                                .bold()
                                .padding(.horizontal)

                            ForEach(pendingConnections) { connection in
                                ConnectionRow(
                                    connection: connection,
                                    onAccept: { handleAccept(connectionId: connection.id) },
                                    onReject: { handleReject(mentorId: connection.userId) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Requested Connections")
            .onAppear(perform: fetchPendingConnections)
        }
    }

    private func fetchPendingConnections() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors/requests") else {
            errorMessage = "Invalid API URL."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Error fetching requests: \(error?.localizedDescription ?? "Unknown error")"
                }
                return
            }

            do {
                let fetchedConnections = try JSONDecoder().decode([PendingConnection].self, from: data)
                DispatchQueue.main.async {
                    self.pendingConnections = fetchedConnections
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error decoding requests: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }.resume()
    }

    private func handleAccept(connectionId: String) {
        updateConnectionStatus(connectionId: connectionId, status: "accepted")
    }

    private func handleReject(mentorId: String) {
        deleteConnection(mentorId: mentorId)
    }

    private func updateConnectionStatus(connectionId: String, status: String) {
        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors/requests/\(connectionId)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["status": status]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { _, response, _ in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            DispatchQueue.main.async {
                fetchPendingConnections()
            }
        }.resume()
    }

    private func deleteConnection(mentorId: String) {
        guard let url = URL(string: "\(MENTOR_BASE_URL)/mentors/connect") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["mentorId": mentorId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { _, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to reject connection: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                fetchPendingConnections()
            }
        }.resume()
    }
}

struct ConnectionRow: View {
    let connection: PendingConnection
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(connection.otherUserName)
                    .font(.headline)
                Text("Requested connection")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()

            HStack(spacing: 10) {
                Button(action: onAccept) {
                    Text("Accept")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                Button(action: onReject) {
                    Text("Reject")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

struct PendingConnection: Identifiable, Decodable {
    let id: String
    let userId: String
    let otherUserName: String
    var status: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case otherUserName
        case status
    }
}

#Preview {
    RequestedConnectionsView(authManager: AuthManager(dummy: true))
}
