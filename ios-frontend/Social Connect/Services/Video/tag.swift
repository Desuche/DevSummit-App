//
//  tag.swift
//  video
//
//  Created by f4506540 on 25/11/2024.
//

import Foundation
import SwiftUI

struct Tag: Hashable, Decodable, Identifiable {
    let id: String
    let name: String
}

class TagService: ObservableObject {
    @Published var tags: [Tag] = []
    var authManager: AuthManager? = nil
    
    func fetch() {
        guard let authManager = authManager, let bearerToken = authManager.getBearerToken(), bearerToken != "" else {
            print("Token unavailable")
            return
        }
        
        guard let url = URL(string: "\(VIDEO_BASE_URL)/tag") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data, let tags = try? JSONDecoder().decode([Tag].self, from: data) else {
                return
            }
            
            DispatchQueue.main.async {
                self.tags = tags
            }
            
        }.resume()
    }
}
