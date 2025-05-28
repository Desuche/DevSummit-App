//
//  VideoPlayerView.swift
//  video
//
//  Created by f4506540 on 18/11/2024.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let video: Video
    let setTag: (String) -> Void
    @State private var player: AVPlayer?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading) {
            VideoPlayer(player: player).frame(height: 300)
                .onAppear {
                    player = AVPlayer(url: video.url)
                    player?.play()
                }
                .onDisappear {
                    player?.pause()
                    player = nil
                }
            Text(video.title).font(.title).padding([.top, .leading, .trailing])
            Text(video.uploadDateString).foregroundStyle(.gray).padding(.horizontal)
            
            HStack {
                Text(video.uploader.name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundStyle(.blue)
                    .fontWeight(.bold)
                ThumbsUp(video: video)
                Text(video.tag.name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundStyle(.blue)
                    .fontWeight(.bold)
                    .onTapGesture {
                        setTag(video.tag.id)
                        presentationMode.wrappedValue.dismiss()
                    }
            }.padding()
            
            Text(video.description).padding(.horizontal)
            
            Spacer()
        }
            .navigationTitle(video.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThumbsUp: View {
    @ObservedObject var video: Video
    
    var body: some View {
        Button(action: video.upvoteToggle) {
            HStack {
                Image(systemName: video.hasUpvoted ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .foregroundColor(video.hasUpvoted ? .blue : .gray)
                Text(String(video.upvotes)).font(.body)
                    .foregroundColor(video.hasUpvoted ? .blue : .gray)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    VideoPlayerView(video: Video(id: "6739c5a59fe6064fd0286e8d", title: "ahsdkfhaklsdf asdf asf asd f", description: "afshdf kljahsdkljf hszljdfh asklj fhakjshd fkljasdhf kjas fkljash dfkjasdhfjlhasf ljkashbdfkjlahs dfjkahsdiluf hasb,jdfh asuldhjfbjkashd flkajsndfkjlah sfdkajsbdhf ikaus hdfkajsh ", url: URL(string: "\(VIDEO_BASE_URL)/video/play/6739bffb5b115a1b31b71b3e.mp4")!, uploadDateString: "date", upvotes: 2, hasUpvoted: true, uploader: User(id: "6739c5a59fe6064fd0286e8d", name: "Julian"), tag: Tag(id: "6739bab23b20f8f8668b7824", name: "Tag"), authManager: AuthManager()), setTag: {tag in print(tag)})
}
