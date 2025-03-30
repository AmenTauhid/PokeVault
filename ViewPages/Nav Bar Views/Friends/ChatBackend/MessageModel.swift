//
//  MessageModel.swift
//  PokeVault
//
//  Created by Omar Al dulaimi on 2025-03-29.
//
//
//  MessageModel.swift
//  PokeVault
//

import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable, Equatable {
    var id: String
    var senderId: String
    var senderName: String
    var receiverId: String
    var content: String
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case senderName
        case receiverId
        case content
        case timestamp
    }
    
    init(id: String = UUID().uuidString,
         senderId: String,
         senderName: String,
         receiverId: String,
         content: String,
         timestamp: Date = Date()) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.receiverId = receiverId
        self.content = content
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        senderId = try container.decode(String.self, forKey: .senderId)
        senderName = try container.decode(String.self, forKey: .senderName)
        receiverId = try container.decode(String.self, forKey: .receiverId)
        content = try container.decode(String.self, forKey: .content)
        
        let timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
        self.timestamp = timestamp.dateValue()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(senderName, forKey: .senderName)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(content, forKey: .content)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "senderId": senderId,
            "senderName": senderName,
            "receiverId": receiverId,
            "content": content,
            "timestamp": Timestamp(date: timestamp)
        ]
    }
    
    // Implement Equatable
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.senderId == rhs.senderId &&
               lhs.senderName == rhs.senderName &&
               lhs.receiverId == rhs.receiverId &&
               lhs.content == rhs.content &&
               lhs.timestamp == rhs.timestamp
    }
}

struct Chat: Identifiable {
    var id: String
    var participants: [String]
    var participantNames: [String: String]
    var lastMessage: String
    var lastMessageTimestamp: Date
    
    init(id: String = UUID().uuidString,
         participants: [String],
         participantNames: [String: String],
         lastMessage: String = "",
         lastMessageTimestamp: Date = Date()) {
        self.id = id
        self.participants = participants
        self.participantNames = participantNames
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
    }
    
    // Return the name of the other participant
    func otherParticipantName(currentUserId: String) -> String {
        for participant in participants {
            if participant != currentUserId {
                return participantNames[participant] ?? "Unknown User"
            }
        }
        return "Unknown User"
    }
    
    // Return the ID of the other participant
    func otherParticipantId(currentUserId: String) -> String {
        for participant in participants {
            if participant != currentUserId {
                return participant
            }
        }
        return ""
    }
}
