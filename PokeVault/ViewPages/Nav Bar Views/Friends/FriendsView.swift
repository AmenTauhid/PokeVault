//
//  FriendsView.swift
//  PokeVault
//

import SwiftUI

struct Friend: Identifiable {
    var id = UUID()
    var name: String
}

struct FriendsView: View {
    @State private var expandedFriend: UUID? = nil
    @State private var friends: [Friend] = [
        Friend(name: "Ash"),
        Friend(name: "Misty"),
        Friend(name: "Brock"),
        Friend(name: "Pikachu"),
        Friend(name: "Charizard")
    ]
    
    @State private var searchText = ""
    @State private var newFriendName = ""

    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search friends list...", text: $searchText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    Button(action: addNewFriend) {
                        Label("", systemImage: "person.fill.badge.plus")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }

                List(filteredFriends) { friend in
                    FriendRow(friend: friend, expandedFriend: $expandedFriend)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Friends List")
            .onAppear {
                expandedFriend = nil
            }
        }
    }

    func addNewFriend() {
        guard !newFriendName.isEmpty else { return }
        friends.append(Friend(name: newFriendName))
        newFriendName = ""
    }
}

struct FriendRow: View {
    let friend: Friend
    @Binding var expandedFriend: UUID?

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(friend.name)
                        .font(.headline)
                        .padding(.vertical, 10)

                    Spacer()

                    Image(systemName: expandedFriend == friend.id ? "chevron.up" : "chevron.down")
                        .rotationEffect(.degrees(expandedFriend == friend.id ? 180 : 0))
                        .animation(.easeInOut, value: expandedFriend)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        expandedFriend = expandedFriend == friend.id ? nil : friend.id
                    }
                }

                if expandedFriend == friend.id {
                    Spacer().frame(height: 50)
                }
            }

            if expandedFriend == friend.id {
                VStack {
                    Spacer()

                    HStack(spacing: 10) {
                        Button(action: {}) {
                            Text("Chat")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .background(
                            NavigationLink(destination: ChatView(friend: friend)) {
                                EmptyView()
                            }
                        )

                        Button(action: {}) {
                            Text("Trade")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .background(
                            NavigationLink(destination: TradeView(friend: friend)) {
                                EmptyView()
                            }
                        )
                    }

                }
            }
        }
        .padding(.vertical, 5)
    }
}
