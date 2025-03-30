//
//  ChatView.swift
//  PokeVault
//
//
//  ChatView.swift
//  PokeVault
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    let friend: Friend
    @StateObject private var chatService = ChatService()
    @State private var messageText = ""
    @State private var chatId: String = ""
    @State private var receiverId: String = ""
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else {
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack {
                            ForEach(chatService.messages) { message in
                                MessageBubbleView(message: message, isFromCurrentUser: message.senderId == chatService.currentUserId)
                                    .id(message.id)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: chatService.messages.count) { _ in
                        if let lastMessage = chatService.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("\(friend.name)'s Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupChat()
        }
        .onDisappear {
            chatService.cleanup()
        }
    }
    
    private func setupChat() {
        // First, we need to find the user ID for this friend
        // This is a simplified version - in a real app, you'd have the user IDs stored in your Friend model
        
        // Check if we already have userId from Friend model
        if !friend.userId.isEmpty {
            receiverId = friend.userId
            createOrFindChat()
            return
        }
        
        // Otherwise search for the user by name
        let db = Firestore.firestore()
        
        db.collection("users").whereField("name", isEqualTo: friend.name).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding user: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents, let firstDoc = documents.first else {
                print("No user found with name: \(friend.name)")
                isLoading = false
                return
            }
            
            // Got the user ID for this friend
            receiverId = firstDoc.documentID
            createOrFindChat()
        }
    }
    
    private func createOrFindChat() {
        chatService.createChat(with: receiverId, userName: friend.name) { chatId in
            self.chatId = chatId
            
            if !chatId.isEmpty {
                // Load messages for this chat
                chatService.loadMessages(chatId: chatId)
            }
            
            isLoading = false
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        chatService.sendMessage(chatId: chatId, receiverId: receiverId, content: messageText) { success in
            if success {
                messageText = ""
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading) {
                Text(message.content)
                    .padding()
                    .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(isFromCurrentUser ? .white : .black)
                    .cornerRadius(10)
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}
