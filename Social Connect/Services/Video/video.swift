//
//  video.swift
//  video
//
//  Created by f4506540 on 18/11/2024.
//

import Foundation
import SwiftUI

struct User: Identifiable, Decodable {
    let id: String
    let name: String
}

class Video: Identifiable, ObservableObject {
    let id: String
    let title: String
    let description: String
    let url: URL
    let uploadDateString: String
    @Published var upvotes: Int
    @Published var hasUpvoted: Bool
    let uploader: User
    let tag: Tag
    let authManager: AuthManager
    
    init(id: String, title: String, description: String, url: URL, uploadDateString: String, upvotes: Int, hasUpvoted: Bool, uploader: User, tag: Tag, authManager: AuthManager) {
        self.id = id
        self.title = title
        self.description = description
        self.url = url
        self.uploadDateString = uploadDateString
        self.upvotes = upvotes
        self.hasUpvoted = hasUpvoted
        self.uploader = uploader
        self.tag = tag
        self.authManager = authManager
    }
    
    func upvoteToggle() {
        guard let bearerToken = authManager.getBearerToken(), bearerToken != "" else {
            print("Token unavailable")
            return
        }
        
        guard let url = URL(string: "\(VIDEO_BASE_URL)/video/\(id)/upvote") else {  return }
        
        var request = URLRequest(url: url)
        request.httpMethod = hasUpvoted ? "DELETE" : "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }
            
            DispatchQueue.main.async {
                self.upvotes += self.hasUpvoted ? -1 : 1
                self.hasUpvoted = !self.hasUpvoted
            }
            
        }.resume()
    }
}

struct VideoResponse: Decodable {
    let id: String
    let title: String
    let description: String
    let fileExtension: String
    let uploadDate: String
    let upvotes: Int
    let hasUpvoted: Bool
    let uploader: User
    let tag: Tag
}

struct VideoContainerResponse: Decodable {
    let page: Int
    let limit: Int
    let total: Int
    let videos: [VideoResponse]
}

class VideoService: ObservableObject {
    @Published var videos: [Video] = []
    var query: String? = nil
    var tag: String? = nil
    
    private var currentPage = 0
    private(set) var total = 0
    private let perPage = 10
    
    @Published var isLoading = false
    @Published var error: String?

    var authManager: AuthManager?
    
    init(authManager: AuthManager? = nil) {
        self.authManager = authManager
    }
    
    func start() {
        videos.removeAll()
        error = nil
        total = 0
        currentPage = 0
        fetchNextPage()
    }
    
    func search(_ query: String?) {
        self.query = query
        start()
    }
    
    func specifyTag(_ tagId: String?) {
        self.tag = tagId
        start()
    }
    
    func loadIfNeeded(video: Video) {
        if error == nil, total > currentPage * perPage, !videos.isEmpty, let lastVideo = videos.last, lastVideo.id == video.id, !isLoading {
            self.isLoading = true
            fetchNextPage()
        }
    }
    
    private func fetchNextPage() {
        guard let authManager = authManager, let bearerToken = authManager.getBearerToken(), bearerToken != "" else {
            print("Token unavailable")
            return
        }
        
        self.isLoading = true
        
        var queryItems = [URLQueryItem(name: "page", value: String(currentPage + 1)), URLQueryItem(name: "limit", value: String(perPage))]
        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        if let tag = tag {
            queryItems.append(URLQueryItem(name: "tag", value: tag))
        }
        guard var urlComps = URLComponents(string: "\(VIDEO_BASE_URL)/video/") else { return }
        urlComps.queryItems = queryItems
        guard let url = urlComps.url else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data, let container = try? JSONDecoder().decode(VideoContainerResponse.self, from: data) else {
                    self.videos.removeAll()
                    self.error = "An error occured. Videos can`t be loaded."
                    self.isLoading = false
                    return
                }
                
                self.currentPage = container.page
                self.total = container.total
                
                let inputFormatter = ISO8601DateFormatter()
                inputFormatter.formatOptions = [
                    .withDashSeparatorInDate,
                    .withFullDate,
                    .withFractionalSeconds
                ]
                container.videos.forEach { video in
                    guard let date = inputFormatter.date(from: video.uploadDate) else {
                        // will just drop this one video
                        return
                    }
                    let outputFormatter = DateFormatter()
                    outputFormatter.dateStyle = .short
                    
                    self.videos.append(Video(id: video.id, title: video.title, description: video.description, url: URL(string: "\(VIDEO_BASE_URL)/video/play/\(video.id).\(video.fileExtension)")!, uploadDateString: outputFormatter.string(from: date), upvotes: video.upvotes, hasUpvoted: video.hasUpvoted, uploader: video.uploader, tag: video.tag, authManager: self.authManager!))
                }
                self.isLoading = false
            }
            
        }.resume()
    }
}
