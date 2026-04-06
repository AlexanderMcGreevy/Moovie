//
//  FriendRequest.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import Foundation
import SwiftData

enum FriendRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
}

@Model
class FriendRequest {
    @Attribute(.unique) var id: UUID
    var fromUserId: UUID  // Who sent the request
    var fromUsername: String
    var toUserId: UUID  // Who receives the request
    var message: String?
    var status: FriendRequestStatus
    var dateSent: Date
    var dateResponded: Date?

    init(
        fromUserId: UUID,
        fromUsername: String,
        toUserId: UUID,
        message: String? = nil
    ) {
        self.id = UUID()
        self.fromUserId = fromUserId
        self.fromUsername = fromUsername
        self.toUserId = toUserId
        self.message = message
        self.status = .pending
        self.dateSent = Date()
        self.dateResponded = nil
    }
}
