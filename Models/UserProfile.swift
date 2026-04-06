//
//  UserProfile.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import Foundation
import SwiftData

@Model
class UserProfile {
    @Attribute(.unique) var id: UUID
    var username: String
    var profileImageName: String?
    var bio: String
    var dateJoined: Date
    var appleUserID: String?
    var email: String?

    // Friend sharing settings
    var isPublic: Bool
    var shareRankings: Bool
    var allowFriendRequests: Bool

    init(
        username: String,
        profileImageName: String? = nil,
        bio: String = "",
        appleUserID: String? = nil,
        email: String? = nil,
        isPublic: Bool = true,
        shareRankings: Bool = true,
        allowFriendRequests: Bool = true
    ) {
        self.id = UUID()
        self.username = username
        self.profileImageName = profileImageName
        self.bio = bio
        self.dateJoined = Date()
        self.appleUserID = appleUserID
        self.email = email
        self.isPublic = isPublic
        self.shareRankings = shareRankings
        self.allowFriendRequests = allowFriendRequests
    }
}
