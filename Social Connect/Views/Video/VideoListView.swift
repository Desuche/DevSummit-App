//
//  VideoView.swift
//  video
//
//  Created by f4506540 on 18/11/2024.
//

import SwiftUI
import AVKit

struct VideoListView: View {
    @StateObject var videoService: VideoService
    @ObservedObject var tagService: TagService
    @State var query: String = ""
    @State private var debounce: Timer?
    var authManager: AuthManager
    
    init(tagService: TagService, authManager: AuthManager) {
        _videoService = StateObject(wrappedValue: VideoService(authManager: authManager))
        self.tagService = tagService
        self.authManager = authManager
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio config failed: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    if !query.isEmpty {
                        Text("\(videoService.total) tutorials found")
                    }
                    
                    HStack {
                        ForEach(tagService.tags) { tag in
                            Text(tag.name)
                                .onTapGesture {
                                    videoService.specifyTag(videoService.tag == tag.id ? nil : tag.id)
                                }
                                .padding()
                                .background(videoService.tag == tag.id ? Color.gray : Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundStyle(.blue)
                                .fontWeight(.bold)
                        }
                    }.padding([.leading, .bottom, .trailing])
                    
                    ForEach(videoService.videos) { video in
                        NavigationLink(destination: VideoPlayerView(video: video, setTag: { tag in
                            videoService.specifyTag(tag)
                        })) {
                            VStack(alignment: .leading) {
                                VideoThumbnail(url: video.url)
                                Text(video.title).padding(.horizontal).onAppear { videoService.loadIfNeeded(video: video) }
                                Text("\(video.uploader.name)  |  \(video.uploadDateString)  |  \(video.tag.name)")
                                    .padding(.horizontal)
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                            }.padding([.bottom], 20)
                        }
                    }
                    
                    if videoService.isLoading {
                        ProgressView()
                        
                    } else if videoService.videos.isEmpty, !videoService.isLoading {
                        Text("No videos available").foregroundStyle(.gray)
                    }
                    
                    if let error = videoService.error {
                        Text(error)
                            .foregroundStyle(.red)
                            .padding()
                    }
                    
                    Spacer()
                }
            }
            .onAppear {
                videoService.start()
            }
            .searchable(text: $query, prompt: "Search for a tutorial")
            .onChange(of: query, search)
            .navigationBarTitleDisplayMode(.automatic)
            .navigationTitle("Social Connect")
            .overlay { // TODO only for mentors
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(destination: VideoUploadView(tagService: tagService, videoService: videoService)) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .gray.opacity(0.6), radius: 5, x: 0, y: 4)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    func search() {
        debounce?.invalidate()
        debounce = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            videoService.search(query)
        }
    }
}

struct VideoThumbnail: View {
    let url: URL
    @State private var triedLoading = false
    @State private var thumbnail: UIImage?
    static private var store = [String:UIImage]()
    
    var body: some View {
        VStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            } else if triedLoading {
                VideoPlayer(player: AVPlayer(url: url))
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            } else {
                Text("The preview can not be loaded.")
                    .padding()
                    .foregroundStyle(.gray)
            }
        }.onAppear {
            if triedLoading {
                return
            }
            
            if let thumbnail = VideoThumbnail.store[url.absoluteString] {
                self.thumbnail = thumbnail
                return
            }

            triedLoading = true
            
            DispatchQueue.global().async {
                let asset = AVAsset(url: url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                let time = CMTime(seconds: 0.0, preferredTimescale: 600)
                do {
                    let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                    DispatchQueue.main.async {
                        thumbnail = UIImage(cgImage: cgImage)
                        if let thumbnail = thumbnail {
                            VideoThumbnail.store.updateValue(thumbnail, forKey: url.absoluteString)
                        }
                    }
                } catch {
                    print("error generating thumbnail")
                }
            }
        }
    }
}

#Preview {
    let tagService = TagService()
    VideoListView(tagService: tagService, authManager: AuthManager()).onAppear { tagService.fetch() }
}
