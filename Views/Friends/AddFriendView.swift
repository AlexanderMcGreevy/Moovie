//
//  AddFriendView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import SwiftUI
import SwiftData

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var allFriends: [Friend]

    @State private var friendCode: String = ""
    @State private var friendUsername: String = ""
    @State private var message: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var isSending = false

    private var currentProfile: UserProfile? {
        profiles.first
    }

    private var syncManager: SyncManager {
        SyncManager.shared
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Share your Friend Code with others or enter theirs to connect!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("How it Works")
                }

                Section {
                    HStack {
                        Text(currentProfile?.id.uuidString.prefix(8).uppercased() ?? "N/A")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)

                        Spacer()

                        Button {
                            if let code = currentProfile?.id.uuidString {
                                UIPasteboard.general.string = code
                                showingSuccess = true
                            }
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                    }

                    Text("Share this code with friends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Your Friend Code")
                }

                Section {
                    TextField("Friend's Username", text: $friendUsername)
                        .textInputAutocapitalization(.words)

                    TextField("Friend Code (UUID)", text: $friendCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    TextField("Message (Optional)", text: $message, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Add a Friend")
                }

                Section {
                    Button {
                        Task {
                            await sendFriendRequest()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSending {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isSending ? "Sending..." : "Send Friend Request")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(friendCode.isEmpty || friendUsername.isEmpty || isSending)
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success!", isPresented: $showingSuccess) {
                Button("OK", role: .cancel) {
                    if showingSuccess {
                        // Just copied code
                    } else {
                        // Sent friend request
                        dismiss()
                    }
                }
            } message: {
                Text(showingSuccess ? "Friend code copied to clipboard!" : "Friend request sent successfully!")
            }
        }
    }

    // MARK: - Helper Functions

    private func sendFriendRequest() async {
        guard let currentProfile = currentProfile else {
            errorMessage = "Please sign in first"
            showingError = true
            return
        }

        // Validate UUID
        guard let friendUUID = UUID(uuidString: friendCode) else {
            errorMessage = "Invalid friend code. Please check and try again."
            showingError = true
            return
        }

        // Check if trying to add self
        if friendUUID == currentProfile.id {
            errorMessage = "You can't add yourself as a friend!"
            showingError = true
            return
        }

        // Check if already friends
        let alreadyFriends = allFriends.contains { friend in
            friend.userId == currentProfile.id &&
            friend.friendUserId == friendUUID &&
            (friend.status == .accepted || friend.status == .pending)
        }

        if alreadyFriends {
            errorMessage = "You're already friends or have a pending request with this user."
            showingError = true
            return
        }

        isSending = true

        do {
            // Send friend request via Supabase
            try await syncManager.sendFriendRequest(
                fromUserId: currentProfile.id,
                toUserId: friendUUID,
                message: message.isEmpty ? nil : message
            )

            // Create local FriendRequest record for tracking
            let request = FriendRequest(
                fromUserId: currentProfile.id,
                fromUsername: currentProfile.username,
                toUserId: friendUUID,
                message: message.isEmpty ? nil : message
            )
            modelContext.insert(request)

            try modelContext.save()

            isSending = false
            showingSuccess = true

            // Clear fields
            friendCode = ""
            friendUsername = ""
            message = ""

        } catch {
            isSending = false
            errorMessage = "Failed to send friend request: \(error.localizedDescription)"
            showingError = true
        }
    }
}

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

    return AddFriendView()
        .modelContainer(container)
}
