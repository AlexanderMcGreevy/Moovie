//
//  FriendsView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 3/30/26.
//

import SwiftUI
import SwiftData

struct FriendsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var allFriends: [Friend]
    @Query private var allRequests: [FriendRequest]

    @State private var showingAddFriend = false
    @State private var showingRequests = false

    private var currentProfile: UserProfile? {
        profiles.first
    }

    private var myFriends: [Friend] {
        guard let profile = currentProfile else { return [] }
        return allFriends.filter { $0.userId == profile.id && $0.status == .accepted }
    }

    private var pendingRequests: [FriendRequest] {
        guard let profile = currentProfile else { return [] }
        return allRequests.filter { $0.toUserId == profile.id && $0.status == .pending }
    }

    var body: some View {
        Group {
            if myFriends.isEmpty && pendingRequests.isEmpty {
                emptyStateView
            } else {
                friendsListView
            }
        }
        .navigationTitle("Friends")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddFriend = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView()
        }
        .sheet(isPresented: $showingRequests) {
            FriendRequestsView()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("No Friends Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add friends to share rankings and compare movies!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingAddFriend = true
            } label: {
                Label("Add Friend", systemImage: "person.badge.plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            Spacer()
        }
    }

    // MARK: - Friends List

    private var friendsListView: some View {
        List {
            // Pending Requests Section
            if !pendingRequests.isEmpty {
                Section {
                    Button {
                        showingRequests = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope.badge")
                                .foregroundColor(.blue)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Friend Requests")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("\(pendingRequests.count) pending")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }

            // Friends List Section
            if !myFriends.isEmpty {
                Section {
                    ForEach(myFriends, id: \.id) { friend in
                        NavigationLink(destination: FriendProfileView(friend: friend)) {
                            FriendRow(friend: friend)
                        }
                    }
                    .onDelete(perform: deleteFriend)
                } header: {
                    Text("My Friends (\(myFriends.count))")
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func deleteFriend(at offsets: IndexSet) {
        for index in offsets {
            let friend = myFriends[index]
            modelContext.delete(friend)
        }
        try? modelContext.save()
    }
}

// MARK: - Friend Row Component

struct FriendRow: View {
    let friend: Friend
    @Query private var sharedRankings: [SharedRanking]

    private var friendRankingsCount: Int {
        sharedRankings.filter { $0.friendId == friend.friendUserId }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture Placeholder
            if let imageName = friend.friendProfileImageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.friendUsername)
                    .font(.headline)

                if friendRankingsCount > 0 {
                    Text("\(friendRankingsCount) movies ranked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No rankings yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: UserProfile.self, Friend.self, FriendRequest.self, SharedRanking.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Create test profile
    let profile = UserProfile(
        username: "Alex",
        bio: "Movie enthusiast",
        appleUserID: "test-id"
    )
    container.mainContext.insert(profile)

    // Create test friends
    let friend1UserId = UUID()
    let friend1 = Friend(
        userId: profile.id,
        friendUserId: friend1UserId,
        friendUsername: "Sarah",
        friendBio: "Film critic",
        status: .accepted
    )

    let friend2UserId = UUID()
    let friend2 = Friend(
        userId: profile.id,
        friendUserId: friend2UserId,
        friendUsername: "Mike",
        status: .accepted
    )

    container.mainContext.insert(friend1)
    container.mainContext.insert(friend2)

    // Create test shared rankings
    let sharedRanking1 = SharedRanking(
        friendId: friend1UserId,
        movieId: 694,
        movieTitle: "The Shining",
        posterPath: "/xazWoLealQwEgqZ89MLZklLZD3k.jpg",
        releaseDate: "1980-05-23",
        finalScore: 8500,
        enjoyment: 85,
        story: 80,
        acting: 90,
        soundtrack: 85,
        rewatchability: 75
    )
    container.mainContext.insert(sharedRanking1)

    // Create test friend request
    let request = FriendRequest(
        fromUserId: UUID(),
        fromUsername: "Jessica",
        toUserId: profile.id,
        message: "Let's compare our movie rankings!"
    )
    container.mainContext.insert(request)

    return NavigationStack {
        FriendsView()
    }
    .modelContainer(container)
}
