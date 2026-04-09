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

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var processingRequestId: UUID?

    private var currentProfile: UserProfile? {
        profiles.first
    }

    private var syncManager: SyncManager {
        SyncManager.shared
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
            .onAppear {
                Task {
                    await fetchRequestsFromSupabase()
                }
            }
            .refreshable {
                await fetchRequestsFromSupabase()
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading requests...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
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
                    isProcessing: processingRequestId == request.id,
                    onAccept: {
                        Task {
                            await acceptRequest(request)
                        }
                    },
                    onDecline: {
                        Task {
                            await declineRequest(request)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Actions

    private func fetchRequestsFromSupabase() async {
        guard let profile = currentProfile, profile.appleUserID != nil else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let remoteRequests = try await syncManager.fetchFriendRequests(userId: profile.id)

            // Merge remote requests with local requests
            for remoteDTO in remoteRequests where remoteDTO.status == "pending" {
                let requestExists = allRequests.contains {
                    $0.fromUserId == remoteDTO.fromUserId && $0.toUserId == remoteDTO.toUserId
                }

                if !requestExists {
                    let newRequest = FriendRequest(
                        fromUserId: remoteDTO.fromUserId,
                        fromUsername: remoteDTO.fromUserId.uuidString, // We'll need to fetch username from profiles
                        toUserId: remoteDTO.toUserId,
                        message: remoteDTO.message
                    )
                    newRequest.id = remoteDTO.id
                    newRequest.dateSent = remoteDTO.dateSent
                    modelContext.insert(newRequest)
                }
            }

            try modelContext.save()
            isLoading = false

        } catch {
            errorMessage = "Failed to load friend requests: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func acceptRequest(_ request: FriendRequest) async {
        guard let currentProfile = currentProfile else { return }

        processingRequestId = request.id
        errorMessage = nil

        do {
            // Accept via Supabase (creates reciprocal friendship)
            try await syncManager.acceptFriendRequest(requestId: request.id)

            // Update local request status
            request.status = .accepted
            request.dateResponded = Date()

            // Create new friend connection locally
            let newFriend = Friend(
                userId: currentProfile.id,
                friendUserId: request.fromUserId,
                friendUsername: request.fromUsername,
                status: .accepted
            )
            modelContext.insert(newFriend)

            try modelContext.save()
            processingRequestId = nil

        } catch {
            errorMessage = "Failed to accept friend request: \(error.localizedDescription)"
            processingRequestId = nil
        }
    }

    private func declineRequest(_ request: FriendRequest) async {
        processingRequestId = request.id
        errorMessage = nil

        do {
            // Decline via Supabase
            try await syncManager.declineFriendRequest(requestId: request.id)

            // Update local request status
            request.status = .declined
            request.dateResponded = Date()

            try modelContext.save()
            processingRequestId = nil

        } catch {
            errorMessage = "Failed to decline friend request: \(error.localizedDescription)"
            processingRequestId = nil
        }
    }
}

// MARK: - Friend Request Row

struct FriendRequestRow: View {
    let request: FriendRequest
    var isProcessing: Bool = false
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
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isProcessing ? "Processing..." : "Accept")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isProcessing)

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
                .disabled(isProcessing)
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
