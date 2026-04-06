//
//  Friend.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import Foundation
import SwiftData

enum FriendStatus: String, Codable {
    case pending
    case accepted
    case declined
    case blocked
}

@Model
class Friend {
    @Attribute(.unique) var id: UUID
    var userId: UUID  // The owner of this friend connection
    var friendUserId: UUID  // The friend's UserProfile ID
    var friendAppleID: String?  // Friend's Apple ID (optional for local MVP)
    var friendUsername: String
    var friendBio: String?
    var friendProfileImageName: String?
    var status: FriendStatus
    var dateAdded: Date
    var lastSynced: Date?

    init(
        userId: UUID,
        friendUserId: UUID,
        friendAppleID: String? = nil,
        friendUsername: String,
        friendBio: String? = nil,
        friendProfileImageName: String? = nil,
        status: FriendStatus = .pending
    ) {
        self.id = UUID()
        self.userId = userId
        self.friendUserId = friendUserId
        self.friendAppleID = friendAppleID
        self.friendUsername = friendUsername
        self.friendBio = friendBio
        self.friendProfileImageName = friendProfileImageName
        self.status = status
        self.dateAdded = Date()
        self.lastSynced = nil
    }
}
