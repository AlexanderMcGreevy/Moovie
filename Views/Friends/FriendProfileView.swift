//
//  FriendProfileView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import SwiftUI
import SwiftData
import Kingfisher

struct FriendProfileView: View {
    let friend: Friend

    @Environment(\.modelContext) private var modelContext
    @Query private var allSharedRankings: [SharedRanking]

    @State private var isLoading = false
    @State private var errorMessage: String?

    private var syncManager: SyncManager {
        SyncManager.shared
    }

    private var friendRankings: [SharedRanking] {
        allSharedRankings.filter { $0.friendId == friend.friendUserId }
            .sorted { $0.finalScore > $1.finalScore }
    }

    private var favoriteMovie: SharedRanking? {
        friendRankings.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                profileHeader

                // Stats Section
                statsSection

                // Favorite Movie Section
                if let favorite = favoriteMovie {
                    VStack(spacing: 8) {
                        Divider()
                        favoritesSection(favorite: favorite)
                        Divider()
                    }
                }

                // View All Rankings Button
                if !friendRankings.isEmpty {
                    NavigationLink(destination: FriendRankingsView(friend: friend)) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View All Rankings")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }

                // Top Movies by Genre
                topMoviesByGenreSection

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(friend.friendUsername)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await fetchFriendRankings()
            }
        }
        .refreshable {
            await fetchFriendRankings()
        }
        .overlay {
            if isLoading {
                ProgressView("Loading rankings...")
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

    // MARK: - Data Fetching

    private func fetchFriendRankings() async {
        isLoading = true
        errorMessage = nil

        do {
            let remoteRankings = try await syncManager.fetchFriendRankings(friendUserId: friend.friendUserId)

            // Convert DTOs to SharedRanking objects
            for rankingDTO in remoteRankings {
                // Check if ranking already exists locally
                let rankingExists = allSharedRankings.contains {
                    $0.friendId == friend.friendUserId && $0.movieId == rankingDTO.movieId
                }

                if !rankingExists {
                    let sharedRanking = SharedRanking(
                        friendId: friend.friendUserId,
                        movieId: rankingDTO.movieId,
                        movieTitle: rankingDTO.movieTitle,
                        posterPath: rankingDTO.posterPath,
                        releaseDate: rankingDTO.releaseDate,
                        finalScore: rankingDTO.finalScore,
                        enjoyment: rankingDTO.enjoyment,
                        story: rankingDTO.story,
                        acting: rankingDTO.acting,
                        soundtrack: rankingDTO.soundtrack,
                        rewatchability: rankingDTO.rewatchability,
                        genreScores: rankingDTO.genreScores ?? [:]
                    )
                    modelContext.insert(sharedRanking)
                }
            }

            try modelContext.save()
            isLoading = false

        } catch {
            errorMessage = "Failed to load friend's rankings: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Picture
            if let imageName = friend.friendProfileImageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    )
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            }

            // Username
            Text(friend.friendUsername)
                .font(.title)
                .fontWeight(.bold)

            // Bio
            if let bio = friend.friendBio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 40) {
            StatCard(title: "Movies Rated", value: "\(friendRankings.count)")
            StatCard(title: "Friends Since", value: friendsSinceText)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var friendsSinceText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: friend.dateAdded)
    }

    // MARK: - Favorite Movie Section

    private func favoritesSection(favorite: SharedRanking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorite Movie")
                .font(.title2)
                .fontWeight(.bold)

            NavigationLink(destination: DetailedMovieView(movie: createMovieInfo(from: favorite))) {
                HStack(spacing: 16) {
                    // Poster
                    if let posterPath = favorite.posterPath, !posterPath.isEmpty {
                        let imageURL = "https://image.tmdb.org/t/p/w185\(posterPath)"
                        KFImage(URL(string: imageURL))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 120)
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(favorite.movieTitle)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundColor(.primary)

                        Text(favorite.releaseDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", Double(favorite.finalScore) / 1000))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Top Movies by Genre

    private var topMoviesByGenreSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Top Movies by Genre")
                .font(.title2)
                .fontWeight(.bold)

            // Horror
            if let topHorror = getTopMovieForGenre("scariness") {
                GenreTopMovieRowFriend(
                    genreTitle: "Horror 💀",
                    movie: topHorror,
                    genreScoreKey: "scariness"
                )
            }

            // Comedy
            if let topComedy = getTopMovieForGenre("funniness") {
                GenreTopMovieRowFriend(
                    genreTitle: "Comedy 🤣",
                    movie: topComedy,
                    genreScoreKey: "funniness"
                )
            }

            // Action
            if let topAction = getTopMovieForGenre("actionIntensity") {
                GenreTopMovieRowFriend(
                    genreTitle: "Action 💥",
                    movie: topAction,
                    genreScoreKey: "actionIntensity"
                )
            }

            // Sci-Fi
            if let topSciFi = getTopMovieForGenre("mindBending") {
                GenreTopMovieRowFriend(
                    genreTitle: "Sci-Fi 🌌",
                    movie: topSciFi,
                    genreScoreKey: "mindBending"
                )
            }

            // Drama
            if let topDrama = getTopMovieForGenre("emotionalDepth") {
                GenreTopMovieRowFriend(
                    genreTitle: "Drama 💔",
                    movie: topDrama,
                    genreScoreKey: "emotionalDepth"
                )
            }

            // Romance
            if let topRomance = getTopMovieForGenre("romanceLevel") {
                GenreTopMovieRowFriend(
                    genreTitle: "Romance 💖",
                    movie: topRomance,
                    genreScoreKey: "romanceLevel"
                )
            }

            // Thriller
            if let topThriller = getTopMovieForGenre("suspense") {
                GenreTopMovieRowFriend(
                    genreTitle: "Thriller 😱",
                    movie: topThriller,
                    genreScoreKey: "suspense"
                )
            }
        }
    }

    // MARK: - Helper Functions

    private func getTopMovieForGenre(_ genreKey: String) -> SharedRanking? {
        friendRankings
            .filter { $0.genreScores[genreKey] != nil }
            .sorted { first, second in
                let firstScore = first.genreScores[genreKey] ?? 0
                let secondScore = second.genreScores[genreKey] ?? 0
                return firstScore > secondScore
            }
            .first
    }

    private func createMovieInfo(from ranking: SharedRanking) -> MovieInfo {
        MovieInfo(
            id: ranking.movieId,
            title: ranking.movieTitle,
            releaseDate: ranking.releaseDate,
            description: nil,
            poster_path: ranking.posterPath
        )
    }
}

// MARK: - Genre Top Movie Row for Friend

struct GenreTopMovieRowFriend: View {
    let genreTitle: String
    let movie: SharedRanking
    let genreScoreKey: String

    var genreScore: Int {
        movie.genreScores[genreScoreKey] ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(genreTitle)
                .font(.headline)

            NavigationLink(destination: DetailedMovieView(movie: createMovieInfo(from: movie))) {
                HStack(spacing: 12) {
                    // Poster
                    if let posterPath = movie.posterPath, !posterPath.isEmpty {
                        let imageURL = "https://image.tmdb.org/t/p/w92\(posterPath)"
                        KFImage(URL(string: imageURL))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.movieTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .foregroundColor(.primary)

                        Text(movie.releaseDate)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Text("Score:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(genreScore)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }

    private func createMovieInfo(from ranking: SharedRanking) -> MovieInfo {
        MovieInfo(
            id: ranking.movieId,
            title: ranking.movieTitle,
            releaseDate: ranking.releaseDate,
            description: nil,
            poster_path: ranking.posterPath
        )
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Friend.self, SharedRanking.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let friendUserId = UUID()
    let friend = Friend(
        userId: UUID(),
        friendUserId: friendUserId,
        friendUsername: "Sarah",
        friendBio: "Film enthusiast and critic",
        status: .accepted
    )
    container.mainContext.insert(friend)

    // Add sample rankings for friend
    let shining = SharedRanking(
        friendId: friendUserId,
        movieId: 694,
        movieTitle: "The Shining",
        posterPath: "/xazWoLealQwEgqZ89MLZklLZD3k.jpg",
        releaseDate: "1980-05-23",
        finalScore: 9200,
        enjoyment: 92,
        story: 88,
        acting: 95,
        soundtrack: 90,
        rewatchability: 85,
        genreScores: ["scariness": 96, "suspense": 92]
    )

    let grandBudapest = SharedRanking(
        friendId: friendUserId,
        movieId: 120467,
        movieTitle: "The Grand Budapest Hotel",
        posterPath: "/eWdyYQreja6JGCzqHWXpWHDrrPo.jpg",
        releaseDate: "2014-03-07",
        finalScore: 8900,
        enjoyment: 90,
        story: 88,
        acting: 92,
        soundtrack: 95,
        rewatchability: 85,
        genreScores: ["funniness": 88, "visualCreativity": 98]
    )

    let interstellar = SharedRanking(
        friendId: friendUserId,
        movieId: 157336,
        movieTitle: "Interstellar",
        posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
        releaseDate: "2014-11-05",
        finalScore: 9500,
        enjoyment: 95,
        story: 92,
        acting: 90,
        soundtrack: 98,
        rewatchability: 88,
        genreScores: ["mindBending": 98, "emotionalDepth": 90]
    )

    container.mainContext.insert(shining)
    container.mainContext.insert(grandBudapest)
    container.mainContext.insert(interstellar)

    return NavigationStack {
        FriendProfileView(friend: friend)
    }
    .modelContainer(container)
}
