//
//  VideoUploadView.swift
//  video
//
//  Created by f4506540 on 25/11/2024.
//

import SwiftUI
import PhotosUI
import AVKit

struct VideoUploadView: View {
    @State private var selectedVideo: PhotosPickerItem? = nil
    @State private var selectedVideoUrl: URL? = nil
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedTag: String? = nil
    @State private var isUploading = false
    @State private var statusMessage: String? = nil
    
    @ObservedObject var tagService: TagService
    var videoService: VideoService
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if let videoUrl = selectedVideoUrl {
                        VideoPlayer(player: AVPlayer(url: videoUrl)).frame(height: 300)
                    }
                    
                    PhotosPicker(
                        selection: $selectedVideo,
                        matching: .videos,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Spacer()
                            Image(systemName: "video.fill")
                            Text(selectedVideo == nil ? "Select Video" : "Change Selected Video")
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                    }.onChange(of: selectedVideo) { loadVideo() }
                    
                    VStack(alignment: .leading) {
                        Text("Title")
                            .font(.headline)
                            .fontWeight(.bold)
                        TextField("Enter Title", text: $title)
                            .padding()
                            .background(Color(Color.gray.opacity(0.2))) // TODO solve systemGray6
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.bold)
                        TextField("Enter Description", text: $description, axis: .vertical)
                            .lineLimit(
                                3...10
                            )
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                    
                    VStack {
                        HStack {
                            Text("Topic of the tutorial")
                                .fixedSize()
                            Spacer()
                            Picker("Topic of the tutorial", selection: $selectedTag) {
                                Text("No topic selected").tag(Optional<String>(nil))
                                ForEach(tagService.tags, id: \.self) { tag in
                                    Text(tag.name).tag(tag.id)
                                }
                            }
                            .labelsHidden()
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                    
                    let disabled = isUploading || selectedVideo == nil || title.isEmpty || description.isEmpty || selectedTag == nil
                    Button(action: uploadVideo) {
                        if isUploading {
                            ProgressView()
                        } else {
                            Text("Publish Tutorial")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(disabled ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.headline)
                        }
                    }
                    .disabled(disabled)
                    
                    if let status = statusMessage {
                        Text(status)
                            .foregroundColor(status.contains("successfully") ? .green : .red)
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Upload Tutorial")
            }
            .onChange(of: selectedVideo) { if selectedVideo != nil { statusMessage = nil } }
            .onChange(of: title) { if title != "" { statusMessage = nil } }
            .onChange(of: selectedTag) { if selectedTag != nil { statusMessage = nil } }
            .onChange(of: description) { if description != "" { statusMessage = nil } }
        }
    }
    
    private func loadVideo() {
        guard let pickerItem = selectedVideo else { return }
        
        Task {
            do {
                if let videoData = try await pickerItem.loadTransferable(type: Data.self) {
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let videoUrl = tempDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    try videoData.write(to: videoUrl)
                    selectedVideoUrl = videoUrl
                }
            } catch {
                print("Error loading video: \(error)")
                statusMessage = "The video could not be loaded from your files."
            }
        }
    }
    
    private func uploadVideo() {
        guard let bearerToken = authManager.getBearerToken(), bearerToken != "" else {
            print("Token unavailable")
            return
        }
        
        guard let videoUrl = selectedVideoUrl, let selectedTag = selectedTag else { return }
        
        isUploading = true
        statusMessage = nil
        
        let url = URL(string: "\(VIDEO_BASE_URL)/video/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(title)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(description)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"tagId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedTag)\r\n".data(using: .utf8)!)
        
        let filename = videoUrl.lastPathComponent
        let mimeType = "video/mp4"
        let videoData = try! Data(contentsOf: videoUrl)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            isUploading = false
            
            if let error = error {
                print("Error: \(error)")
                statusMessage = "An error occured on your device."
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                statusMessage = "The application is not working correctly. We will work on it."
                return
            }
            
            if httpResponse.statusCode == 201 {
                selectedVideo = nil
                selectedVideoUrl = nil
                title = ""
                description = ""
                self.selectedTag = nil
                statusMessage = "Video uploaded successfully!"
                
                DispatchQueue.main.async {
                    videoService.start()
                }
                
            } else {
                statusMessage = "Upload failed. Please try again"
            }
            
        }.resume()
    }
}

#Preview {
    VideoUploadView(tagService: TagService(), videoService: VideoService())
}
