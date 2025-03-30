//
//  ChatListView.swift
//  PokeVault
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatListView: View {
    @StateObject private var chatService = ChatService()
    @State private var showingNewChatSheet = false
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading chats...")
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Error loading chats")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            loadChats()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else if chatService.chats.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding()
                        
                        Text("No chats yet")
                            .font(.headline)
                        
                        Text("Start a new conversation by tapping the button in the top right")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingNewChatSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("New Chat")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(chatService.chats) { chat in
                            NavigationLink(destination: ChatView(friend: Friend(name: chat.otherParticipantName(currentUserId: chatService.currentUserId), userId: chat.otherParticipantId(currentUserId: chatService.currentUserId)))) {
                                ChatRowView(chat: chat, currentUserId: chatService.currentUserId)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        loadChats()
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewChatSheet = true
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewChatSheet) {
                NewChatView(chatService: chatService, isPresented: $showingNewChatSheet)
            }
            .onAppear {
                // Ensure user data exists in Firestore
                chatService.ensureUserDataInFirestore { success in
                    if success {
                        loadChats()
                    } else {
                        errorMessage = "Failed to setup user data"
                        isLoading = false
                    }
                }
            }
            .onDisappear {
                chatService.cleanup()
            }
        }
    }
    
    private func loadChats() {
        isLoading = true
        errorMessage = nil
        
        // Add a bit of delay to ensure UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            chatService.loadChats()
            isLoading = false
        }
    }
}


struct ChatRowView: View {
    let chat: Chat
    let currentUserId: String
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Text(String(chat.otherParticipantName(currentUserId: currentUserId).prefix(1).uppercased()))
                    .font(.title2.bold())
                    .foregroundColor(.blue)
            }
            
            // Chat info
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.otherParticipantName(currentUserId: currentUserId))
                    .font(.headline)
                    .lineLimit(1)
                
                Text(chat.lastMessage.isEmpty ? "No messages yet" : chat.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time and unread indicator
            VStack(alignment: .trailing, spacing: 5) {
                Text(formatRelativeTime(chat.lastMessageTimestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let unreadCount = getUnreadCount(for: chat.id), unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func getUnreadCount(for chatId: String) -> Int? {
        // This would come from your chat service or local state
        // For now, returning a sample value
        return nil
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        
        let timeInterval = date.timeIntervalSinceNow
        
        if abs(timeInterval) < 60 {
            return "Just now"
        }
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
//
//  NewChatView.swift
//  PokeVault
//

import SwiftUI

struct NewChatView: View {
    @ObservedObject var chatService: ChatService
    @Binding var isPresented: Bool
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var searchTimer: Timer?
    @State private var selectedUser: ChatService.UserProfile?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search by name or email", text: $searchQuery)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: searchQuery) { newValue in
                            // Cancel previous timer
                            searchTimer?.invalidate()
                            
                            if newValue.isEmpty {
                                isSearching = false
                                chatService.searchResults = []
                            } else {
                                isSearching = true
                                
                                // Debounce search
                                searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                    chatService.searchUsers(query: newValue)
                                }
                            }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                            chatService.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Status or error message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Results
                if isSearching {
                    if chatService.searchResults.isEmpty && !searchQuery.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No users found")
                                .font(.headline)
                            
                            Text("Try a different name or email")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(chatService.searchResults) { user in
                                Button(action: {
                                    selectedUser = user
                                    startChat(with: user)
                                }) {
                                    HStack {
                                        // User avatar
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.3))
                                                .frame(width: 50, height: 50)
                                            
                                            Text(String(user.name.prefix(1).uppercased()))
                                                .font(.title2.bold())
                                                .foregroundColor(.blue)
                                        }
                                        
                                        // User info
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(user.name)
                                                .font(.headline)
                                            
                                            Text(user.email)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "message.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                } else {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Search for users")
                            .font(.headline)
                        
                        Text("Find friends by their name or email address")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("New Chat")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
    
    // Modify the startChat function in your NewChatView.swift
    private func startChat(with user: ChatService.UserProfile) {
        errorMessage = nil
        
        // Show loading indicator
        isSearching = true
        
        chatService.createChat(with: user.id, userName: user.name) { chatId in
            isSearching = false
            
            if !chatId.isEmpty {
                // Set flag to refresh chats in parent view
                chatService.needsRefresh = true
                
                // Close sheet
                isPresented = false
            } else {
                errorMessage = "Failed to create chat. Please try again."
            }
        }
    }
}
