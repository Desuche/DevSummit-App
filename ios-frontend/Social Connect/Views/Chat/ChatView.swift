//
//  ChatView.swift
//  Social Connect
//
//  Created by f1201609 on 30/11/2024.
//

import SwiftUI
import SwiftData


struct ChatView: View {
    let chatWithId : String
    let chatWithName : String
    @StateObject var chatService : ChatService
    @Environment(\.modelContext) private var swiftDataChatContext
    @State private var scrollViewProxy: ScrollViewProxy?
    
    init(authManager : AuthManager, chatWithId : String, chatWithName: String) {
        self.chatWithId = chatWithId
        self.chatWithName = chatWithName
        _chatService = StateObject(wrappedValue: ChatService(authManager: authManager, chatWith: chatWithId))
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            // Header
            ChatHeader(name: chatWithName)
            
            // Scrollable Chat Pane
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack {
                        ForEach(chatService.messages) { message in
                            ChatMessageView(message: message)
                                .id(message.id) // Assign an ID for scrolling
                        }
                    }
                    .padding(.horizontal, 15)
                }
                .padding(.bottom, 10)
                .onAppear {
                    // Store the proxy when the view appears
                    scrollViewProxy = scrollView
                    scrollToBottom(animated: false)  // Scroll to bottom on appear
                }
                .onChange(of: chatService.messages) { _ in
                    scrollToBottom(animated: true)  // Scroll to bottom whenever messages change
                    
                }
                
                ChatInput(chatService: chatService)
                
                
            }
        }
        .onAppear{
            chatService.registerContext(modelContext: swiftDataChatContext)
            chatService.connect()
            
            
        }
        .onDisappear {
            chatService.disconnect() // Disconnect when the view disappears
        }
    }
    
    // Function to scroll to the bottom
    private func scrollToBottom(animated: Bool) {
        guard let proxy = scrollViewProxy else { return }
        if let lastMessage = chatService.messages.last {
            if animated {
                withAnimation {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
}

struct ChatHeader : View{
    let name : String
    var body: some View {
        Text("Chat with \(name.split(separator: " ").first.map(String.init) ?? "your mentor")")
            .font(.title)
            .padding()
            .foregroundColor(.blue)
            .background()
        
    }
}

struct ChatInput: View {
    @State private var newMessage = ""
    var chatService : ChatService
    
    var body: some View {
        HStack {
            TextField("Type a message...", text: $newMessage, prompt: Text("Type a message..."))
                .textFieldStyle(.plain) // Use PlainStyle for better appearance
                .padding()
                .background(Color.white.opacity(0.4)) // Slightly opaque background
                .onSubmit { sendMessage() } // Send message on Enter key
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15) // Rounded background for the input area
                .stroke(Color.gray.opacity(0.5), lineWidth: 2) // Firm border
                .background(Color.clear) // Clear background to show the blur behind
        )
        .padding(.horizontal) // Padding around the input area
    }
    
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        chatService.sendMessage(newMessage)
        newMessage = ""
    }
}


//#Preview {
//    ChatView(authManager: AuthManager(dummy: true),chatWithId: "673d7bbe371d2f79e5a09808", chatWithName: "John Doe")
//        .modelContainer(for: SwiftDataChatMessage.self)
//}
