//import Foundation
//import Combine
//import SwiftUI
//
//class MentorService: ObservableObject {
//    private let authManager: AuthManager
//    private let mentorsBaseApi = "https://5449-2-58-242-76.ngrok-free.app"
//
//    init(authManager: AuthManager) {
//        self.authManager = authManager
//    }
//    
//    
//    
//    
//    func toggleConnectionToMentor(
//        mentorId: String,
//        onSuccess: @escaping (_ isConnected: Bool) -> Void,
//        onError: @escaping (String) -> Void
//    ) {
//        print("Toggling connection for mentor with ID: \(mentorId)")
//
//        guard let bearerToken = authManager.getBearerToken(), !bearerToken.isEmpty else {
//            print("Token unavailable")
//            onError("Token unavailable")
//            return
//        }
//
//        guard let url = URL(string: "\(mentorsBaseApi)/mentors/connect") else { return }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let body: [String: Any] = ["mentorId": mentorId]
//
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
//        } catch {
//            print("Error serializing JSON: \(error)")
//            onError("Error serializing JSON")
//            return
//        }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("Error toggling connection: \(error)")
//                    onError("Error toggling connection")
//                    return
//                }
//
//                guard let data = data else {
//                    print("No data received.")
//                    onError("No data received")
//                    return
//                }
//
//                do {
//                    let response = try JSONDecoder().decode(ConnectionToggleResponse.self, from: data)
//                    onSuccess(response.action == "created")
//                } catch {
//                    print("Error decoding response: \(error)")
//                    print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
//                    onError("Error decoding response")
//                }
//            }
//        }.resume()
//    }
//    
//    
//    
//
//    // Fetch all mentors
//    func fetchMentors(mentors: Binding<[Mentor]>, isLoading: Binding<Bool>) {
//        isLoading.wrappedValue = true
//        print("Fetching mentors...")
//
//        guard let bearerToken = authManager.getBearerToken(), !bearerToken.isEmpty else {
//            print("Token unavailable")
//            return
//        }
//
//        guard let url = URL(string: "\(mentorsBaseApi)/mentors") else { return }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            DispatchQueue.main.async {
//                isLoading.wrappedValue = false
//
//                if let error = error {
//                    print("Error fetching mentors: \(error)")
//                    return
//                }
//
//                guard let data = data else {
//                    print("No data received.")
//                    return
//                }
//
//                do {
//                    var decodedMentors = try JSONDecoder().decode([Mentor].self, from: data)
//
//                    // Fetch names for each mentor
//                    let group = DispatchGroup()
//                    for index in decodedMentors.indices {
//                        group.enter()
//                        self.fetchUserName(userId: decodedMentors[index].userId) { name in
//                            decodedMentors[index].name = name
//                            group.leave()
//                        }
//                    }
//
//                    group.notify(queue: .main) {
//                        mentors.wrappedValue = decodedMentors
//                        print("Successfully fetched mentors with names: \(mentors.wrappedValue.count)")
//                        print(mentors.wrappedValue)
//                    }
//                } catch {
//                    print("Error decoding mentors: \(error)")
//                }
//            }
//        }.resume()
//    }
//
//    // Fetch user name using userId
//    private func fetchUserName(userId: String, completion: @escaping (String?) -> Void) {
//        guard let url = URL(string: "\(mentorsBaseApi)/users/\(userId)") else {
//            completion(nil)
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(authManager.getBearerToken() ?? "")", forHTTPHeaderField: "Authorization")
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error fetching user name: \(error.localizedDescription)")
//                completion(nil)
//                return
//            }
//
//            guard let data = data else {
//                print("No data received for userId \(userId).")
//                completion(nil)
//                return
//            }
//
//            do {
//                let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
//                completion(userResponse.name)
//            } catch {
//                print("Error decoding user data: \(error.localizedDescription)")
//                completion(nil)
//            }
//        }.resume()
//    }
//}
//
//// Struct to decode the user response
//struct UserResponse: Decodable {
//    let name: String
//}
//
//struct ConnectionToggleResponse: Decodable {
//    let action: String // Either "created" or "deleted"
//    let message: String
//}
