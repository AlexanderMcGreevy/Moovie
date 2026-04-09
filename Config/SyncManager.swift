//
//  SyncManager.swift
//  Moovie
//
//  Created by Claude Code on 4/9/26.
//

import Foundation
import SwiftData
import Combine

/// Handles synchronization between local SwiftData and Supabase
@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    private let supabase = SupabaseManager.shared

    private init() {}

    // MARK: - Profile Sync

    /// Sync user profile to Supabase
    func syncProfile(_ profile: UserProfile) async throws {
        guard let appleUserID = profile.appleUserID else {
            throw SyncError.notAuthenticated
        }

        _ = try await supabase.signInWithApple(
            appleUserID: appleUserID,
            email: profile.email,
            fullName: profile.username
        )
    }

    // MARK: - Rankings Sync

    /// Sync a single ranking to Supabase
    func syncRanking(_ ranking: UserMovieRanking, userId: UUID) async throws {
        let rankingDTO = MovieRankingDTO(
            id: ranking.id,
            userId: userId,
            movieId: ranking.movieId,
            movieTitle: ranking.movieTitle,
            posterPath: ranking.posterPath,
            releaseDate: ranking.releaseDate,
            finalScore: ranking.finalScore,
            enjoyment: ranking.enjoyment,
            story: ranking.story,
            acting: ranking.acting,
            soundtrack: ranking.soundtrack,
            rewatchability: ranking.rewatchability,
            genreScores: ranking.genreScores,
            dateRanked: ranking.dateRanked,
            lastUpdated: ranking.lastModified
        )

        try await supabase.upsertRanking(rankingDTO)
    }

    /// Sync all rankings to Supabase
    func syncAllRankings(_ rankings: [UserMovieRanking], userId: UUID) async throws {
        isSyncing = true
        syncError = nil

        do {
            for ranking in rankings {
                try await syncRanking(ranking, userId: userId)
            }

            lastSyncDate = Date()
            isSyncing = false
        } catch {
            syncError = error.localizedDescription
            isSyncing = false
            throw error
        }
    }

    /// Delete ranking from Supabase
    func deleteRanking(_ rankingId: UUID) async throws {
        try await supabase.deleteRanking(id: rankingId)
    }

    /// Fetch rankings from Supabase and update local database
    func fetchAndMergeRankings(userId: UUID, modelContext: ModelContext) async throws {
        let remoteRankings = try await supabase.fetchMyRankings(userId: userId)

        // Fetch local rankings
        let descriptor = FetchDescriptor<UserMovieRanking>()
        let localRankings = try modelContext.fetch(descriptor)

        // Create lookup dictionary for local rankings
        let localLookup = Dictionary(uniqueKeysWithValues: localRankings.map { ($0.id, $0) })

        for remoteDTO in remoteRankings {
            if let localRanking = localLookup[remoteDTO.id] {
                // Update existing local ranking if remote is newer
                if remoteDTO.lastUpdated > localRanking.lastModified {
                    updateLocalRanking(localRanking, from: remoteDTO)
                }
            } else {
                // Create new local ranking from remote data
                let newRanking = createLocalRanking(from: remoteDTO)
                modelContext.insert(newRanking)
            }
        }

        try modelContext.save()
    }

    // MARK: - Friends Sync

    /// Fetch friends from Supabase
    func fetchFriends(userId: UUID) async throws -> [FriendDTO] {
        return try await supabase.fetchFriends(userId: userId)
    }

    /// Send friend request via Supabase
    func sendFriendRequest(fromUserId: UUID, toUserId: UUID, message: String?) async throws {
        try await supabase.sendFriendRequest(fromUserId: fromUserId, toUserId: toUserId, message: message)
    }

    /// Fetch friend requests from Supabase
    func fetchFriendRequests(userId: UUID) async throws -> [FriendRequestDTO] {
        return try await supabase.fetchFriendRequests(userId: userId)
    }

    /// Accept friend request via Supabase
    func acceptFriendRequest(requestId: UUID) async throws {
        try await supabase.acceptFriendRequest(requestId: requestId)
    }

    /// Decline friend request via Supabase
    func declineFriendRequest(requestId: UUID) async throws {
        try await supabase.declineFriendRequest(requestId: requestId)
    }

    /// Delete friend via Supabase
    func deleteFriend(friendshipId: UUID) async throws {
        try await supabase.deleteFriend(friendshipId: friendshipId)
    }

    /// Fetch friend's rankings from Supabase
    func fetchFriendRankings(friendUserId: UUID) async throws -> [MovieRankingDTO] {
        return try await supabase.fetchFriendRankings(friendUserId: friendUserId)
    }

    /// Search users via Supabase
    func searchUsers(query: String) async throws -> [UserProfileDTO] {
        return try await supabase.searchUsers(query: query)
    }

    // MARK: - Helper Methods

    private func updateLocalRanking(_ local: UserMovieRanking, from remote: MovieRankingDTO) {
        local.finalScore = remote.finalScore
        local.enjoyment = remote.enjoyment
        local.story = remote.story
        local.acting = remote.acting
        local.soundtrack = remote.soundtrack
        local.rewatchability = remote.rewatchability
        local.genreScores = remote.genreScores ?? [:]
        local.lastModified = remote.lastUpdated
    }

    private func createLocalRanking(from remote: MovieRankingDTO) -> UserMovieRanking {
        let ranking = UserMovieRanking(
            movieId: remote.movieId,
            movieTitle: remote.movieTitle,
            posterPath: remote.posterPath,
            releaseDate: remote.releaseDate,
            finalScore: remote.finalScore,
            enjoyment: remote.enjoyment,
            story: remote.story,
            acting: remote.acting,
            soundtrack: remote.soundtrack,
            rewatchability: remote.rewatchability,
            genreScores: remote.genreScores ?? [:]
        )
        // Preserve remote timestamps
        ranking.dateRanked = remote.dateRanked
        ranking.lastModified = remote.lastUpdated
        return ranking
    }
}

// MARK: - Errors

enum SyncError: LocalizedError {
    case notAuthenticated
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not signed in. Please sign in to sync."
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}
