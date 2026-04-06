//
//  FriendRequestsView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import SwiftUI
import SwiftData

struct FriendRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var allRequests: [FriendRequest]
    @Query private var allFriends: [Friend]

    private var currentProfile: UserProfile? {
        profiles.first
    }

    private var pendingRequests: [FriendRequest] {
        guard let profile = currentProfile else { return [] }
        return allRequests.filter { $0.toUserId == profile.id && $0.status == .pending }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pendingRequests.isEmpty {
                    emptyStateView
                } else {
                    requestsListView
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.open")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Pending Requests")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Friend requests will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    // MARK: - Requests List

    private var requestsListView: some View {
        List {
            ForEach(pendingRequests, id: \.id) { request in
                FriendRequestRow(
                    request: request,
                    onAccept: { acceptRequest(request) },
                    onDecline: { declineRequest(request) }
                )
            }
        }
    }

    // MARK: - Actions

    private func acceptRequest(_ request: FriendRequest) {
        guard let currentProfile = currentProfile else { return }

        // Update request status
        request.status = .accepted
        request.dateResponded = Date()

        // Find or create the Friend record
        if let existingFriend = allFriends.first(where: {
            $0.userId == currentProfile.id && $0.friendUserId == request.fromUserId
        }) {
            existingFriend.status = .accepted
        } else {
            // Create new friend connection
            let newFriend = Friend(
                userId: currentProfile.id,
                friendUserId: request.fromUserId,
                friendUsername: request.fromUsername,
                status: .accepted
            )
            modelContext.insert(newFriend)
        }

        // Create reciprocal friendship (so both users see each other)
        let reciprocalFriend = Friend(
            userId: request.fromUserId,
            friendUserId: currentProfile.id,
            friendUsername: currentProfile.username,
            friendBio: currentProfile.bio,
            status: .accepted
        )
        modelContext.insert(reciprocalFriend)

        try? modelContext.save()
    }

    private func declineRequest(_ request: FriendRequest) {
        request.status = .declined
        request.dateResponded = Date()

        // Update any pending friend records
        if let existingFriend = allFriends.first(where: {
            $0.userId == currentProfile?.id && $0.friendUserId == request.fromUserId && $0.status == .pending
        }) {
            existingFriend.status = .declined
        }

        try? modelContext.save()
    }
}

// MARK: - Friend Request Row

struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Profile Picture Placeholder
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.fromUsername)
                        .font(.headline)

                    Text(formatDate(request.dateSent))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if let message = request.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 62)
            }

            HStack(spacing: 12) {
                Button {
                    onAccept()
                } label: {
                    Text("Accept")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }

                Button {
                    onDecline()
                } label: {
                    Text("Decline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.leading, 62)
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Sent " + formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: UserProfile.self, Friend.self, FriendRequest.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let profile = UserProfile(
        username: "Alex",
        appleUserID: "test-id"
    )
    container.mainContext.insert(profile)

    // Create test requests
    let request1 = FriendRequest(
        fromUserId: UUID(),
        fromUsername: "Sarah",
        toUserId: profile.id,
        message: "Hey! Let's compare our movie rankings!"
    )

    let request2 = FriendRequest(
        fromUserId: UUID(),
        fromUsername: "Mike",
        toUserId: profile.id
    )

    let request3 = FriendRequest(
        fromUserId: UUID(),
        fromUsername: "Jessica",
        toUserId: profile.id,
        message: "I saw you rated Parasite too! Wanna be friends?"
    )

    container.mainContext.insert(request1)
    container.mainContext.insert(request2)
    container.mainContext.insert(request3)

    return FriendRequestsView()
        .modelContainer(container)
}
