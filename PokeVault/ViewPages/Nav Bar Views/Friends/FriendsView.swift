//
//  FriendsView.swift
//  PokeVault
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Friend: Identifiable {
    var id = UUID()
    var name: String
    var userId: String = "" // Added userId property
}

struct FriendsView: View {
    @StateObject private var chatService = ChatService()
    @State private var isLoading = true
    @State private var showingNewChatSheet = false
    @State private var errorMessage: String? = nil
    @State private var hasInitialized = false
    
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
            .navigationTitle("Friends & Chats")
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
                // Only reload chats after dismissing the sheet if a new chat was created
                if chatService.needsRefresh {
                    loadChats()
                    chatService.needsRefresh = false
                }
            } content: {
                NewChatView(chatService: chatService, isPresented: $showingNewChatSheet)
            }
            .onAppear {
                // Only initialize once when the view first appears
                if !hasInitialized {
                    initializeView()
                    hasInitialized = true
                }
            }
            .onDisappear {
                // Don't clean up listeners when just navigating to a chat
                // This will be handled when the app is backgrounded or the view is removed
            }
        }
    }
    
    private func initializeView() {
        isLoading = true
        errorMessage = nil
        
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
    
    private func loadChats() {
        isLoading = true
        errorMessage = nil
        
        // Add a bit of delay to ensure UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // First clean up any existing listeners to avoid duplicates
            chatService.cleanup()
            
            // Then load chats
            chatService.loadChats()
            isLoading = false
        }
    }
}
