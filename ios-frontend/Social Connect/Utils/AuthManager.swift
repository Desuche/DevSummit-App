//
//  AuthManager.swift
//  Social Connect
//
//  Created by f1201609 on 19/11/2024.
//

import Foundation
import Combine

struct AuthenticatedUser {
    let userId: String;
    let name: String;
    let email: String;
}

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var authenticatedUser: Optional<AuthenticatedUser> = nil;
    @Published private var bearerToken: String = ""
    
    private let tokenKey = "jwtToken"
    
    init() {
        // Check if a token exists when initializing
        isAuthenticated = loadToken() != nil
    }
    
    init(dummy: Bool){
        isAuthenticated = true
        authenticatedUser = AuthManager.dummyUser
        bearerToken = AuthManager.dummyToken
    }
    
    // MARK: - Authentication Methods
    
    func login(with token: String) {
        saveToken(token)
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }
    
    func logout() {
        deleteToken()
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }
    
    func getBearerToken() -> String? {
        return bearerToken;
    }
    
    // MARK: - Token Management
    
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        DispatchQueue.main.async {
            self.bearerToken = token
        }
        decodeJWT(token: token)
    }
    
    private func loadToken() -> String? {
        let token = UserDefaults.standard.string(forKey: tokenKey)
        if let token = token {
            self.bearerToken = token
            
            decodeJWT(token: token)
        }
        return token
    }
    
    private func deleteToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    // MARK: - Check Authentication Status
    
    func isUserLoggedIn() -> Bool {
        return loadToken() != nil
    }
    
    func getMyUserId() -> String {
        return authenticatedUser?.userId ?? ""
        
    }
}

extension AuthManager {
    func decodeJWT(token: String) {
        let components = token.split(separator: ".")
        
        guard components.count == 3 else {
            print("Invalid JWT format")
            return
        }
        
        let payloadBase64 = String(components[1])
        
        // Base64 URL decode the payload
        let paddedBase64 = payloadBase64 + String(repeating: "=", count: (4 - payloadBase64.count % 4) % 4)
        guard let payloadData = Data(base64Encoded: paddedBase64, options: .ignoreUnknownCharacters) else {
            print("Failed to decode base64 payload")
            return
        }
        
        do {
            // Convert the payload to a JSON dictionary
            if let json = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
                // Extract specific fields
                if let userId = json["_id"] as? String,
                   let name = json["name"] as? String,
                   let email = json["email"] as? String,
                   let createdAt = json["createdAt"] as? String {
                    
                    print("User ID: \(userId)")
                    print("Name: \(name)")
                    print("Email: \(email)")
                    print("Created At: \(createdAt)")
                    
                    DispatchQueue.main.async {
                        self.authenticatedUser = AuthenticatedUser(userId: userId, name: name, email: email)
                    }
                } else {
                    print("Expected fields not found in payload")
                }
            }
        } catch {
            print("Failed to parse JSON: \(error)")
        }
    }
}

//Haraka
//extension AuthManager {
//    static let dummyUser = AuthenticatedUser(userId: "6747efe3412c1ea7f2fbf898", name: "Haraka Baraka", email: "Haraka@gmail.com")
//    static let dummyToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NzQ3ZWZlMzQxMmMxZWE3ZjJmYmY4OTgiLCJuYW1lIjoiSGFyYWthIEJhcmFrYSIsImVtYWlsIjoiSGFyYWthQGdtYWlsLmNvbSIsImNyZWF0ZWRBdCI6IjIwMjQtMTEtMjhUMDQ6MjE6NTUuMzA5WiIsImlhdCI6MTczMjc3NTEzNn0.KM7f8EqoVpC25aVq3AfiuidU1ID4CJzGOBEW3cmjKq8"
//}



//Des


extension AuthManager {
    static let dummyUser = AuthenticatedUser(userId: "673d7bbe371d2f79e5a09808", name: "Des", email: "Dede@mail.com")
    static let dummyToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NzNkN2JiZTM3MWQyZjc5ZTVhMDk4MDgiLCJuYW1lIjoiRGVzIiwiZW1haWwiOiJEZWRlQG1haWwuY29tIiwiY3JlYXRlZEF0IjoiMjAyNC0xMS0yMFQwNjowMzo0Mi4yNjRaIiwiaWF0IjoxNzMzMDM0OTE5fQ.NhpgNKalsTvzbL633jA1OzF8eNv1K6UiOvYB9nkuZAY"
}


//Abc
//extension AuthManager {
//    static let dummyUser = AuthenticatedUser(userId: "674c5f369b445c663bc65a88", name: "ABC", email: "Abc@gmail.com")
//    static let dummyToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NzRjNWYzNjliNDQ1YzY2M2JjNjVhODgiLCJuYW1lIjoiQUJDIiwiZW1haWwiOiJBYmNAZ21haWwuY29tIiwiY3JlYXRlZEF0IjoiMjAyNC0xMi0wMVQxMzowNTo1OC4xMTlaIiwiaWF0IjoxNzMzMDYyMjA1fQ.F7wvEIsF_qHhLNx14dRACuyeWRLxijZfAsPEm4kF8eg"
//}

struct JWT: Codable {
    var jwt: String
}
