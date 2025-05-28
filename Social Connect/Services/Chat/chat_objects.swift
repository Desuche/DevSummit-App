//
//  chat_objects.swift
//  Social Connect
//
//  Created by f1201609 on 30/11/2024.
//
import SwiftUI
import SwiftData

struct ChatMessage: Identifiable, Equatable  {
    let id: String
    let senderId: String
    let myUserId: String
    let content: String
    let datetime: String
    var isMine: Bool {
        senderId == myUserId
    }
}

extension ChatMessage {
    static let samples = [
        ChatMessage(id: "1", senderId: "user1", myUserId: "user2", content: "Hey! How are you?", datetime: "2024-11-29T15:53:41.561+00:00"),
        ChatMessage(id: "2", senderId: "user2", myUserId: "user2", content: "I'm good, thanks! How about you?", datetime: "2024-11-29T15:54:10.561+00:00"),
        ChatMessage(id: "3", senderId: "user1", myUserId: "user2", content: "Just working on some projects.", datetime: "2024-11-29T15:55:00.561+00:00"),
        ChatMessage(id: "4", senderId: "user2", myUserId: "user2", content: "Sounds interesting! What kind of projects?", datetime: "2024-11-29T15:56:15.561+00:00"),
        ChatMessage(id: "5", senderId: "user1", myUserId: "user2", content: "Mostly app development. I'm excited about it!", datetime: "2024-11-29T15:57:30.561+00:00"),
        ChatMessage(id: "6", senderId: "user2", myUserId: "user2", content: "That's awesome! Keep me updated.", datetime: "2024-11-29T15:58:45.561+00:00")
    ]
}


struct ChatResponseMessage: Codable {
    let connectionId: String
    let message: String
    let senderId: String
    let timestamp: String
    let _id: String
}




@Model
class SwiftDataChatMessage{
    var id: String
    var idOfChatPartner: String
    var senderId: String
    var content: String
    var datetime: String
    
    init(id: String, idOfChatPartner: String, senderId: String, content: String, datetime: String) {
        self.id = id
        self.idOfChatPartner = idOfChatPartner
        self.senderId = senderId
        self.content = content
        self.datetime = datetime
    }
}
