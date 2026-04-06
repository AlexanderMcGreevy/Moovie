//
//  FriendRankingsView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import SwiftUI
import SwiftData
import Kingfisher

struct FriendRankingsView: View {
    let friend: Friend

    @Environment(\.modelContext) private var modelContext
    @Query private var allSharedRankings: [SharedRanking]
    @Query private var myRankings: [UserMovieRanking]

    @State private var sortOption: RankingSortOption = .overall

    private var friendRankings: [SharedRanking] {
        allSharedRankings.filter { $0.friendId == friend.friendUserId }
    }

    private var sortedRankings: [SharedRanking] {
        if sortOption == .overall {
            return friendRankings.sorted { $0.finalScore > $1.finalScore }
        } else {
            let filtered = friendRankings.filter { ranking in
                ranking.genreScores[sortOption.genreScoreKey] != nil
            }
            return filtered.sorted { first, second in
                let firstScore = first.genreScores[sortOption.genreScoreKey] ?? 0
                let secondScore = second.genreScores[sortOption.genreScoreKey] ?? 0
                return firstScore > secondScore
            }
        }
    }

    private func hasRankedMovie(_ movieId: Int) -> UserMovieRanking? {
        myRankings.first { $0.movieId == movieId }
    }

    var body: some View {
        Group {
            if friendRankings.isEmpty {
                emptyStateView
            } else {
                rankingsListView
            }
        }
        .navigationTitle("\(friend.friendUsername)'s Rankings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(RankingSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption == .overall ? "Sort" : sortOptionShortName)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "film.stack")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("No Rankings Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(friend.friendUsername) hasn't ranked any movies yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Rankings List

    private var rankingsListView: some View {
        List {
            ForEach(Array(sortedRankings.enumerated()), id: \.element.id) { index, ranking in
                ZStack(alignment: .leading) {
                    NavigationLink(destination: DetailedMovieView(movie: createMovieInfo(from: ranking))) {
                        EmptyView()
                    }
                    .opacity(0)

                    FriendRankingRow(
                        ranking: ranking,
                        position: index + 1,
                        sortOption: sortOption,
                        youRankedIt: hasRankedMovie(ranking.movieId),
                        friendUsername: friend.friendUsername
                    )
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if let myRanking = hasRankedMovie(ranking.movieId) {
                        NavigationLink(destination: CompareRankingsView(
                            myRanking: myRanking,
                            friendRanking: ranking,
                            friendUsername: friend.friendUsername
                        )) {
                            Label("Compare", systemImage: "arrow.left.arrow.right")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Helper Properties

    private var sortOptionShortName: String {
        switch sortOption {
        case .overall: return "Overall"
        case .actionIntensity: return "💥"
        case .funniness: return "🤣"
        case .scariness: return "💀"
        case .romanceLevel: return "💖"
        case .mindBending: return "🌌"
        case .suspense: return "😱"
        case .emotionalDepth: return "💔"
        case .visualCreativity: return "✨"
        case .worldBuilding: return "🌟"
        case .mysteryIntrigue: return "🕵️"
        case .educationalValue: return "🧠"
        case .adventureScale: return "🚀"
        case .soundtrackQuality: return "🎼"
        case .warIntensity: return "🔥"
        case .westernVibes: return "🐎"
        case .historicalAccuracy: return "⏳"
        case .familyFriendly: return "🎉"
        case .tvProduction: return "🎬"
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

// MARK: - Friend Ranking Row

struct FriendRankingRow: View {
    let ranking: SharedRanking
    let position: Int
    let sortOption: RankingSortOption
    let youRankedIt: UserMovieRanking?
    let friendUsername: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Position Badge
            ZStack {
                Circle()
                    .fill(positionColor)
                    .frame(width: 40, height: 40)

                Text("#\(position)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // Poster
            if let posterPath = ranking.posterPath, !posterPath.isEmpty {
                let imageURL = "https://image.tmdb.org/t/p/w185\(posterPath)"
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
                    .overlay(
                        Image(systemName: "film")
                            .foregroundColor(.secondary)
                    )
            }

            // Movie Info
            VStack(alignment: .leading, spacing: 6) {
                Text(ranking.movieTitle)
                    .font(.headline)
                    .lineLimit(2)

                Text(ranking.releaseDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Score Breakdown
                if sortOption == .overall {
                    HStack(spacing: 12) {
                        ScorePill(emoji: "😍", value: ranking.enjoyment)
                        ScorePill(emoji: "📖", value: ranking.story)
                        ScorePill(emoji: "🎭", value: ranking.acting)
                    }
                } else {
                    HStack(spacing: 12) {
                        if let genreScore = ranking.genreScores[sortOption.genreScoreKey] {
                            ScorePill(emoji: getGenreEmoji(for: sortOption), value: genreScore, highlighted: true)
                        }
                        ScorePill(emoji: "😍", value: ranking.enjoyment)
                        ScorePill(emoji: "📖", value: ranking.story)
                    }
                }

                // You ranked it indicator
                if let myRanking = youRankedIt {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text("You: \(String(format: "%.1f", Double(myRanking.finalScore) / 1000))")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }

    private var positionColor: Color {
        switch position {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return Color.blue
        }
    }

    private func getGenreEmoji(for option: RankingSortOption) -> String {
        switch option {
        case .overall: return "⭐"
        case .actionIntensity: return "💥"
        case .funniness: return "🤣"
        case .scariness: return "💀"
        case .romanceLevel: return "💖"
        case .mindBending: return "🌌"
        case .suspense: return "😱"
        case .emotionalDepth: return "💔"
        case .visualCreativity: return "✨"
        case .worldBuilding: return "🌟"
        case .mysteryIntrigue: return "🕵️"
        case .educationalValue: return "🧠"
        case .adventureScale: return "🚀"
        case .soundtrackQuality: return "🎼"
        case .warIntensity: return "🔥"
        case .westernVibes: return "🐎"
        case .historicalAccuracy: return "⏳"
        case .familyFriendly: return "🎉"
        case .tvProduction: return "🎬"
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Friend.self, SharedRanking.self, UserMovieRanking.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let friendUserId = UUID()
    let friend = Friend(
        userId: UUID(),
        friendUserId: friendUserId,
        friendUsername: "Sarah",
        status: .accepted
    )
    container.mainContext.insert(friend)

    // Friend's rankings
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
        genreScores: ["scariness": 96]
    )

    let parasite = SharedRanking(
        friendId: friendUserId,
        movieId: 496243,
        movieTitle: "Parasite",
        posterPath: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
        releaseDate: "2019-05-30",
        finalScore: 9500,
        enjoyment: 95,
        story: 98,
        acting: 92,
        soundtrack: 88,
        rewatchability: 90,
        genreScores: ["emotionalDepth": 94]
    )

    let madMax = SharedRanking(
        friendId: friendUserId,
        movieId: 76341,
        movieTitle: "Mad Max: Fury Road",
        posterPath: "/hA2ple9q4qnwxp3hKVNhroipsir.jpg",
        releaseDate: "2015-05-15",
        finalScore: 8800,
        enjoyment: 90,
        story: 75,
        acting: 85,
        soundtrack: 92,
        rewatchability: 88,
        genreScores: ["actionIntensity": 95]
    )

    container.mainContext.insert(shining)
    container.mainContext.insert(parasite)
    container.mainContext.insert(madMax)

    // Your ranking (to show "You ranked it" indicator and enable compare)
    let myShining = UserMovieRanking(
        movieId: 694,
        movieTitle: "The Shining",
        posterPath: "/xazWoLealQwEgqZ89MLZklLZD3k.jpg",
        releaseDate: "1980-05-23",
        finalScore: 8500,
        enjoyment: 85,
        story: 80,
        acting: 90,
        soundtrack: 85,
        rewatchability: 75,
        genreScores: ["scariness": 90, "suspense": 88]
    )
    container.mainContext.insert(myShining)

    return NavigationStack {
        FriendRankingsView(friend: friend)
    }
    .modelContainer(container)
}
