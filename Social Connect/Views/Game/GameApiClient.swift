//
//  GameApiClient.swift
//  Social Connect
//
//  Created by Vanessa Chan on 28/5/2025.
//

import Foundation
import Combine

class GameApiClient: ObservableObject {
    private var GAME_API = "https://llmios.f1201609.hkbu.app"
    private var sessionId: String?
    private var cancellables = Set<AnyCancellable>()
    
    // Start a new game session
    func startNewGame(with cards: [Int], completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(GAME_API)/new-game") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["cards": cards]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NewGameResponse.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    break
                case .failure(let error):
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                self.sessionId = response.session
                completion(.success(response.hint))
            })
            .store(in: &cancellables)
    }

    // Send a message to the chat
    func sendMessage(_ message: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let sessionId = sessionId else {
            completion(.failure(NSError(domain: "No active session", code: 0, userInfo: nil)))
            return
        }

        guard let url = URL(string: "\(GAME_API)/chat/\(sessionId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["inp": ["message": message]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    break
                case .failure(let error):
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                completion(.success(response.assistant))
            })
            .store(in: &cancellables)
    }
}

struct NewGameResponse: Decodable {
    let session: String
    let hasSet: Bool
    let hint: String
}

struct ApiResponse: Decodable {
    let assistant: String
    let level: Int
}
