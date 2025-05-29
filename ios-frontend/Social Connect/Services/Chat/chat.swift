//
//  chat.swift
//  Social Connect
//
//  Created by f1201609 on 30/11/2024.
//

import SwiftUI
import SwiftData
import CoreData


class ChatService: ObservableObject {
    
    
    private var chatPartnerUserId : String
    private var authManager: AuthManager
    @Published var messages: [ChatMessage] = []
    
    //swiftData
    private var modelContext : ModelContext? = nil
    
    //Websocket variables
    private var websocket: URLSessionWebSocketTask?
    private var urlString: String
    private let session: URLSession
    
    
    
    init (authManager : AuthManager, chatWith: String){
        self.authManager = authManager
        self.chatPartnerUserId = chatWith
        self.urlString = "\(CHAT_WS_BASE_URL)?chatUserId=\(chatPartnerUserId)&token=\(authManager.getBearerToken() ?? "notokenavailable")"
        self.session = URLSession(configuration: .default)
        //self.modelContext = modelContext
        
    }
    
    func sendMessage(_ messageContent: String){
        let message = ChatMessage(
            id: UUID().uuidString, // Generate a unique ID as a string
            senderId: authManager.getMyUserId(),  // Replace with your actual user ID
            myUserId: authManager.getMyUserId(),   // Same as above for comparison
            content: messageContent,
            datetime: "...sending"
        )
        
        self.messages.append(message)
        
        self.sendMessageToServer(messageContent: messageContent)
        
    }
    
    
}

//SwiftData code
extension ChatService {
    
    func registerContext (modelContext: ModelContext) {
        self.modelContext = modelContext
        loadChatFromLocalStorage()
        if let idOfLastmessageInLocalStorage = messages.last?.id {
            self.urlString = self.urlString + "&lastMessageId=\(idOfLastmessageInLocalStorage)"
        }
        
    }
    
    private func encodeChatMessageToSDChatMessage(chatMessage: ChatMessage) -> SwiftDataChatMessage {
        return SwiftDataChatMessage(id: chatMessage.id, idOfChatPartner: self.chatPartnerUserId, senderId: chatMessage.senderId, content: chatMessage.content, datetime: chatMessage.datetime)
    }
    
    private func decodeChatMessageFromSDChatMessage(sdChatMessage: SwiftDataChatMessage) -> ChatMessage {
        return ChatMessage(id: sdChatMessage.id, senderId: sdChatMessage.senderId, myUserId: self.authManager.getMyUserId(), content: sdChatMessage.content, datetime: sdChatMessage.datetime)
    }
    
    private func loadChatFromLocalStorage() {
        guard let context = modelContext else {
            print("Loading Chat Failed: Model Context Unavailable")
            return
        }
        
        print("Loading chats from storage")
        
        let fetchDescriptor = FetchDescriptor<SwiftDataChatMessage>(
            predicate: #Predicate {$0.idOfChatPartner == chatPartnerUserId as String},
            sortBy: [
                SortDescriptor(\.datetime, order: .forward)  //Sorting the chats by datetime, oldest first
            ]
        )
        
        let result = try? context.fetch(fetchDescriptor)
        guard let swiftDataChatMessages = result else {
            print("Loading from Local storage failed. Guard triggered after fetching chats")
            return
        }
        
        //Convert the SwiftDataChatMessage objects to regular ChatMessage structs
        let chatMessages = swiftDataChatMessages.map{ decodeChatMessageFromSDChatMessage(sdChatMessage: $0)}
        self.messages = chatMessages
        print("\(chatMessages.count) chat messages have been loaded from local storage")
    }
    
    
    private func insertDummyMessagesToContext() {
        guard let context = modelContext else {
            print("No context registered")
            return
        }
        
        // Create an array of sample messages
        let sampleMessages = [
            SwiftDataChatMessage(id: "674d24b1148f5b2542d4bf62", idOfChatPartner: "673d7bbe371d2f79e5a09808", senderId: "6747efe3412c1ea7f2fbf898", content: "hello", datetime: "2024-12-02T03:08:33.222Z")
        ]
        
        // Insert each sample message into the context
        for message in sampleMessages {
            context.insert(message)
        }
        
        // Optionally, save the context to persist the changes
        do {
            try context.save()
            print("Dummy messages added successfully.")
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
}










//Websocket Code
extension ChatService {
    
    func connect() {
        // Ensure the URL is valid
        guard let url = URL(string: self.urlString) else {
            print("Invalid WebSocket URL: \(self.urlString)")
            return
        }
        
        // Create the WebSocket task
        websocket = session.webSocketTask(with: url)
        
        // Check if the websocket was created successfully
        guard websocket != nil else {
            print("Failed to create WebSocket task.")
            return
        }
        
        // Start the WebSocket connection
        websocket?.resume()
        
        // Start receiving messages
        receiveMessage()
    }
    
    // Function to receive messages
    private func receiveMessage() {
        websocket?.receive(completionHandler: { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleIncomingMessage(message)
                // Continue receiving messages
                self?.receiveMessage()
            case .failure(let error):
                print("Chat Websocket: Connection Error \n \n: \(error)")
            }
        })
    }
    
    private func handleIncomingMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let jsonString):
            print("Received chat messages \(jsonString)")
            decodeAndPrintChatResponses(from: jsonString)
        case .data(let data):
            print("Received data: \(data)")
        @unknown default:
            print("Received unknown message type")
        }
    }
    
    private func decodeAndPrintChatResponses(from jsonString: String) {
        let decoder = JSONDecoder()
        do {
            let responseMessages = try decoder.decode([ChatResponseMessage].self, from: Data(jsonString.utf8))
            let newMessages = responseMessages.map { response in
                ChatMessage(
                    id: response._id,
                    senderId: response.senderId,
                    myUserId: authManager.getMyUserId(),
                    content: response.message,
                    datetime: response.timestamp
                )
            }
            self.updateMessages(newMessages: newMessages)
            
        } catch {
            print("Error decoding JSON: \(error.localizedDescription)")
        }
    }
    
    private func updateMessages(newMessages: [ChatMessage]) {
        // Remove all messages where datetime == "...sending"
        DispatchQueue.main.async{
            self.messages = self.messages.filter { $0.datetime != "...sending" }
            
            // Add new messages to view array
            self.messages += newMessages
        }
        
        
        //Add new messages to swiftData model container
        guard let context = modelContext else {
            print("Error persisting new messages: context unavailable")
            return
        }
        
        // Insert each new message into the context
        let swiftDataMessages = newMessages.map{ encodeChatMessageToSDChatMessage(chatMessage: $0)}
        for message in swiftDataMessages {
            context.insert(message)
        }
        
        // Optionally, save the context to persist the changes
        do {
            try context.save()
            print("New messages persisted successfully.")
        } catch {
            print("Error persisting new messages: \(error.localizedDescription)")
        }
        
    }
    
    private func sendMessageToServer(messageContent: String) {
        // Check if the websocket is active
        guard let websocket = websocket else {
            print("Websocket is not active. Message sending failed.")
            return
        }
        
        // Dispatch the send operation to a background queue
        DispatchQueue.global().async {
            // Create a text message
            let message = URLSessionWebSocketTask.Message.string(messageContent)
            
            // Send the message
            websocket.send(message) { error in
                if let error = error {
                    print("Failed to send message: \(error.localizedDescription)")
                } else {
                    print("Message sent successfully: \(messageContent)")
                }
            }
        }
    }
    
    
    
    
    func disconnect() {
        websocket?.cancel(with: .goingAway, reason: nil)
    }
}
