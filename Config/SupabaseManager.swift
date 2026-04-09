//
//  SupabaseManager.swift
//  Moovie
//
//  Created by Claude Code on 4/9/26.
//

import Foundation
import Supabase

/// Singleton manager for Supabase client and database operations
class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    // MARK: - Authentication

    /// Sign in with Apple ID and create/update user profile
    func signInWithApple(appleUserID: String, email: String?, fullName: String?) async throws -> UserProfileDTO {
        // Sign in to Supabase Auth with Apple ID
        // Note: You'll need to configure Apple provider in Supabase dashboard

        // For now, we'll use the Apple ID as a custom identifier
        // In production, integrate with Supabase's Apple OAuth provider

        // Check if profile exists
        let existingProfile: [UserProfileDTO] = try await client
            .from("profiles")
            .select()
            .eq("apple_user_id", value: appleUserID)
            .execute()
            .value

        if let profile = existingProfile.first {
            return profile
        }

        // Create new profile
        let newProfile = UserProfileDTO(
            id: UUID(),
            username: fullName ?? "User",
            bio: nil,
            profileImageName: nil,
            appleUserID: appleUserID,
            email: email,
            isPublic: true,
            shareRankings: true,
            allowFriendRequests: true,
            dateJoined: Date()
        )

        let created: UserProfileDTO = try await client
            .from("profiles")
            .insert(newProfile)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    // MARK: - Movie Rankings

    /// Fetch all rankings for the current user
    func fetchMyRankings(userId: UUID) async throws -> [MovieRankingDTO] {
        let rankings: [MovieRankingDTO] = try await client
            .from("movie_rankings")
            .select()
            .eq("user_id", value: userId)
            .order("final_score", ascending: false)
            .execute()
            .value

        return rankings
    }

    /// Upload/sync a ranking to Supabase
    func upsertRanking(_ ranking: MovieRankingDTO) async throws {
        try await client
            .from("movie_rankings")
            .upsert(ranking)
            .execute()
    }

    /// Delete a ranking
    func deleteRanking(id: UUID) async throws {
        try await client
            .from("movie_rankings")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Friends

    /// Search for users by username
    func searchUsers(query: String) async throws -> [UserProfileDTO] {
        let profiles: [UserProfileDTO] = try await client
            .rpc("search_users", params: ["search_query": query])
            .execute()
            .value

        return profiles
    }

    /// Send a friend request
    func sendFriendRequest(fromUserId: UUID, toUserId: UUID, message: String?) async throws {
        let request = FriendRequestDTO(
            id: UUID(),
            fromUserId: fromUserId,
            toUserId: toUserId,
            message: message,
            status: "pending",
            dateSent: Date()
        )

        try await client
            .from("friend_requests")
            .insert(request)
            .execute()
    }

    /// Fetch pending friend requests for a user
    func fetchFriendRequests(userId: UUID) async throws -> [FriendRequestDTO] {
        let requests: [FriendRequestDTO] = try await client
            .from("friend_requests")
            .select()
            .eq("to_user_id", value: userId)
            .eq("status", value: "pending")
            .order("date_sent", ascending: false)
            .execute()
            .value

        return requests
    }

    /// Accept a friend request (creates reciprocal friendship)
    func acceptFriendRequest(requestId: UUID) async throws {
        try await client
            .rpc("accept_friend_request", params: ["request_id": requestId.uuidString])
            .execute()
    }

    /// Decline a friend request
    func declineFriendRequest(requestId: UUID) async throws {
        try await client
            .from("friend_requests")
            .update(["status": "declined"])
            .eq("id", value: requestId)
            .execute()
    }

    /// Fetch user's friends
    func fetchFriends(userId: UUID) async throws -> [FriendDTO] {
        let friends: [FriendDTO] = try await client
            .from("friends")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: "accepted")
            .order("date_added", ascending: false)
            .execute()
            .value

        return friends
    }

    /// Fetch a friend's rankings (respects privacy settings)
    func fetchFriendRankings(friendUserId: UUID) async throws -> [MovieRankingDTO] {
        let rankings: [MovieRankingDTO] = try await client
            .rpc("get_friend_rankings", params: ["friend_user_id": friendUserId.uuidString])
            .execute()
            .value

        return rankings
    }

    /// Delete a friend
    func deleteFriend(friendshipId: UUID) async throws {
        try await client
            .from("friends")
            .delete()
            .eq("id", value: friendshipId)
            .execute()
    }
}

// MARK: - Data Transfer Objects (DTOs)

/// These structs match the Supabase database schema
struct UserProfileDTO: Codable {
    let id: UUID
    var username: String
    var bio: String?
    var profileImageName: String?
    var appleUserID: String?
    var email: String?
    var isPublic: Bool
    var shareRankings: Bool
    var allowFriendRequests: Bool
    let dateJoined: Date

    enum CodingKeys: String, CodingKey {
        case id, username, bio, email
        case profileImageName = "profile_image_name"
        case appleUserID = "apple_user_id"
        case isPublic = "is_public"
        case shareRankings = "share_rankings"
        case allowFriendRequests = "allow_friend_requests"
        case dateJoined = "date_joined"
    }
}

struct MovieRankingDTO: Codable {
    let id: UUID
    let userId: UUID
    let movieId: Int
    let movieTitle: String
    let posterPath: String?
    let releaseDate: String
    let finalScore: Int
    let enjoyment: Int
    let story: Int
    let acting: Int
    let soundtrack: Int
    let rewatchability: Int
    let genreScores: [String: Int]?
    let dateRanked: Date
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case id, enjoyment, story, acting, soundtrack, rewatchability
        case userId = "user_id"
        case movieId = "movie_id"
        case movieTitle = "movie_title"
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case finalScore = "final_score"
        case genreScores = "genre_scores"
        case dateRanked = "date_ranked"
        case lastUpdated = "last_updated"
    }
}

struct FriendDTO: Codable {
    let id: UUID
    let userId: UUID
    let friendUserId: UUID
    let friendUsername: String
    let status: String
    let dateAdded: Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case userId = "user_id"
        case friendUserId = "friend_user_id"
        case friendUsername = "friend_username"
        case dateAdded = "date_added"
    }
}

struct FriendRequestDTO: Codable {
    let id: UUID
    let fromUserId: UUID
    let toUserId: UUID
    let message: String?
    let status: String
    let dateSent: Date

    enum CodingKeys: String, CodingKey {
        case id, message, status
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case dateSent = "date_sent"
    }
}
