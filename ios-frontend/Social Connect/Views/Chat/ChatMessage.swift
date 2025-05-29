//
//  ChatMessage.swift
//  Social Connect
//
//  Created by f1201609 on 30/11/2024.
//

import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: message.isMine ? .trailing : .leading) {

            HStack {
                if message.isMine {
                    Spacer()
                }
                
                Text(message.content)
                    .padding()
                    .background(message.isMine ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: 300, alignment: message.isMine ? .trailing : .leading)
                
                if !message.isMine {
                    Spacer()
                }
            }
            .padding(message.isMine ? .leading : .trailing, 50)

            Text(formatDate(message.datetime))
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(maxWidth: 300, alignment: message.isMine ? .trailing : .leading)
        }
        .padding(.vertical, 5)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}


#Preview {
    VStack{
        Spacer()
        ForEach(ChatMessage.samples){
            message in
            ChatMessageView(message: message)
        }
        Spacer()
    }.padding(.horizontal, 30)
}
