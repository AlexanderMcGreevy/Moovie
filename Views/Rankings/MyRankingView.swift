//
//  MyRankingView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 2/27/26.
//

import SwiftUI
import SwiftData
import Kingfisher

enum RankingSortOption: String, CaseIterable, Identifiable {
    case overall = "Overall Score"
    case actionIntensity = "Action 💥"
    case funniness = "Comedy 🤣"
    case scariness = "Horror 💀"
    case romanceLevel = "Romance 💖"
    case mindBending = "Sci-Fi 🌌"
    case suspense = "Thriller 😱"
    case emotionalDepth = "Drama 💔"
    case visualCreativity = "Animation ✨"
    case worldBuilding = "Fantasy 🌟"
    case mysteryIntrigue = "Mystery 🕵️"
    case educationalValue = "Documentary 🧠"
    case adventureScale = "Adventure 🚀"
    case soundtrackQuality = "Music 🎼"
    case warIntensity = "War 🔥"
    case westernVibes = "Western 🐎"
    case historicalAccuracy = "History ⏳"
    case familyFriendly = "Family 🎉"
    case tvProduction = "TV Movie 🎬"

    var id: String { rawValue }

    var genreScoreKey: String {
        // Returns the key used in genreScores dictionary (matches SliderQuestion.id)
        switch self {
        case .overall: return ""
        case .actionIntensity: return "actionIntensity"
        case .funniness: return "funniness"
        case .scariness: return "scariness"
        case .romanceLevel: return "romanceLevel"
        case .mindBending: return "mindBending"
        case .suspense: return "suspense"
        case .emotionalDepth: return "emotionalDepth"
        case .visualCreativity: return "visualCreativity"
        case .worldBuilding: return "worldBuilding"
        case .mysteryIntrigue: return "mysteryIntrigue"
        case .educationalValue: return "educationalValue"
        case .adventureScale: return "adventureScale"
        case .soundtrackQuality: return "soundtrackQuality"
        case .warIntensity: return "warIntensity"
        case .westernVibes: return "westernVibes"
        case .historicalAccuracy: return "historicalAccuracy"
        case .familyFriendly: return "familyFriendly"
        case .tvProduction: return "tvProduction"
        }
    }
}

struct MyRankingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserMovieRanking.finalScore, order: .reverse) private var rankings: [UserMovieRanking]
    @Query private var profiles: [UserProfile]

    @State private var rankingToEdit: UserMovieRanking?
    @State private var rankingToDelete: UserMovieRanking?
    @State private var showingDeleteAlert = false
    @State private var sortOption: RankingSortOption = .overall

    private var currentProfile: UserProfile? {
        profiles.first
    }

    private var syncManager: SyncManager {
        SyncManager.shared
    }

    var sortedRankings: [UserMovieRanking] {
        if sortOption == .overall {
            return rankings.sorted { $0.finalScore > $1.finalScore }
        } else {
            // Filter rankings that have the selected genre score
            let genreKey = sortOption.genreScoreKey
            let filtered = rankings.filter { ranking in
                ranking.genreScores[genreKey] != nil
            }

            // Sort by the genre-specific score
            return filtered.sorted { first, second in
                let firstScore = first.genreScores[genreKey] ?? 0
                let secondScore = second.genreScores[genreKey] ?? 0
                return firstScore > secondScore
            }
        }
    }

    var sortOptionShortName: String {
        // Extract just the emoji from the option
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

    var body: some View {
        Group {
            if rankings.isEmpty {
                emptyStateView
            } else {
                rankingsListView
            }
        }
        .navigationTitle("My Rankings")
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
        .onAppear {
            print("📺 MyRankingView appeared - Rankings count: \(rankings.count)")
        }
        .sheet(item: $rankingToEdit) { ranking in
            NavigationStack {
                RankingView(movie: createMovieInfo(from: ranking), existingRanking: ranking)
            }
        }
        .alert("Delete Ranking", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let ranking = rankingToDelete {
                    deleteRanking(ranking)
                }
            }
        } message: {
            Text("Are you sure you want to delete this ranking?")
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "star.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("No Rankings Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start ranking movies to see them here!")
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
                NavigationLink(destination: DetailedMovieView(movie: createMovieInfo(from: ranking))) {
                    RankingRow(ranking: ranking, position: index + 1, sortOption: sortOption)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        rankingToDelete = ranking
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        rankingToEdit = ranking
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Helper Functions

    private func createMovieInfo(from ranking: UserMovieRanking) -> MovieInfo {
        MovieInfo(
            id: ranking.movieId,
            title: ranking.movieTitle,
            releaseDate: ranking.releaseDate,
            description: nil,
            poster_path: ranking.posterPath
        )
    }

    private func deleteRanking(_ ranking: UserMovieRanking) {
        let rankingId = ranking.id

        // Delete locally
        modelContext.delete(ranking)
        try? modelContext.save()

        // Delete from Supabase
        if let profile = currentProfile, profile.appleUserID != nil {
            Task {
                do {
                    try await syncManager.deleteRanking(rankingId)
                    print("☁️ Ranking deleted from Supabase")
                } catch {
                    print("⚠️ Failed to delete ranking from Supabase: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Ranking Row Component

struct RankingRow: View {
    let ranking: UserMovieRanking
    let position: Int
    let sortOption: RankingSortOption

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
                    // Show genre-specific score when sorting by genre
                    HStack(spacing: 12) {
                        if let genreScore = ranking.genreScores[sortOption.genreScoreKey] {
                            ScorePill(emoji: getGenreEmoji(for: sortOption), value: genreScore, highlighted: true)
                        }
                        ScorePill(emoji: "😍", value: ranking.enjoyment)
                        ScorePill(emoji: "📖", value: ranking.story)
                    }
                }

                // Date Ranked
                Text("Ranked \(formatDate(ranking.dateRanked))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Chevron
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

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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

// MARK: - Score Pill Component

struct ScorePill: View {
    let emoji: String
    let value: Int
    var highlighted: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            Text(emoji)
                .font(.caption2)
            Text("\(value)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(highlighted ? Color.blue.opacity(0.2) : Color(.systemGray5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(highlighted ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    let container = try! ModelContainer(
        for: UserMovieRanking.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Horror movies
    let theShining = UserMovieRanking(
        movieId: 694,
        movieTitle: "The Shining",
        posterPath: "/xazWoLealQwEgqZ89MLZklLZD3k.jpg",
        releaseDate: "1980-05-23",
        finalScore: 8500,
        enjoyment: 90,
        story: 85,
        acting: 95,
        soundtrack: 88,
        rewatchability: 80,
        genreScores: ["scariness": 95, "suspense": 90]
    )

    let getOut = UserMovieRanking(
        movieId: 419430,
        movieTitle: "Get Out",
        posterPath: "/tFXcEccSQMf3lfhfXKSU9iRBpa3.jpg",
        releaseDate: "2017-02-24",
        finalScore: 8200,
        enjoyment: 85,
        story: 90,
        acting: 88,
        soundtrack: 75,
        rewatchability: 75,
        genreScores: ["scariness": 70, "suspense": 85, "mysteryIntrigue": 80]
    )

    let hereditay = UserMovieRanking(
        movieId: 493922,
        movieTitle: "Hereditary",
        posterPath: "/p6OzPcI5xvZTlWNMH7PLGYeVqab.jpg",
        releaseDate: "2018-06-04",
        finalScore: 7800,
        enjoyment: 75,
        story: 80,
        acting: 92,
        soundtrack: 85,
        rewatchability: 60,
        genreScores: ["scariness": 88, "emotionalDepth": 75]
    )

    // Comedy movies
    let superbad = UserMovieRanking(
        movieId: 8363,
        movieTitle: "Superbad",
        posterPath: "/ek8e8txUyUwd2BNqj6lFEerJfbq.jpg",
        releaseDate: "2007-08-17",
        finalScore: 8700,
        enjoyment: 95,
        story: 75,
        acting: 85,
        soundtrack: 80,
        rewatchability: 95,
        genreScores: ["funniness": 92]
    )

    let grandBudapest = UserMovieRanking(
        movieId: 120467,
        movieTitle: "The Grand Budapest Hotel",
        posterPath: "/eWdyYQreja6JGCzqHWXpWHDrrPo.jpg",
        releaseDate: "2014-03-07",
        finalScore: 9200,
        enjoyment: 98,
        story: 88,
        acting: 90,
        soundtrack: 92,
        rewatchability: 88,
        genreScores: ["funniness": 75, "visualCreativity": 95]
    )

    // Action movies
    let madMax = UserMovieRanking(
        movieId: 76341,
        movieTitle: "Mad Max: Fury Road",
        posterPath: "/hA2ple9q4qnwxp3hKVNhroipsir.jpg",
        releaseDate: "2015-05-15",
        finalScore: 9000,
        enjoyment: 95,
        story: 80,
        acting: 88,
        soundtrack: 95,
        rewatchability: 92,
        genreScores: ["actionIntensity": 98, "adventureScale": 90]
    )

    let johnWick = UserMovieRanking(
        movieId: 245891,
        movieTitle: "John Wick",
        posterPath: "/fZPSd91yGE9fCcCe6OoQr6E3Bev.jpg",
        releaseDate: "2014-10-24",
        finalScore: 8400,
        enjoyment: 88,
        story: 70,
        acting: 85,
        soundtrack: 82,
        rewatchability: 90,
        genreScores: ["actionIntensity": 95, "suspense": 75]
    )

    // Sci-Fi
    let interstellar = UserMovieRanking(
        movieId: 157336,
        movieTitle: "Interstellar",
        posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
        releaseDate: "2014-11-05",
        finalScore: 9100,
        enjoyment: 92,
        story: 95,
        acting: 90,
        soundtrack: 98,
        rewatchability: 85,
        genreScores: ["mindBending": 88, "emotionalDepth": 85, "adventureScale": 92]
    )

    // Romance
    let lalaland = UserMovieRanking(
        movieId: 313369,
        movieTitle: "La La Land",
        posterPath: "/uDO8zWDhfWwoFdKS4fzkUJt0Rf0.jpg",
        releaseDate: "2016-12-09",
        finalScore: 8600,
        enjoyment: 90,
        story: 82,
        acting: 88,
        soundtrack: 95,
        rewatchability: 80,
        genreScores: ["romanceLevel": 85, "soundtrackQuality": 98, "emotionalDepth": 78]
    )

    // Drama
    let parasite = UserMovieRanking(
        movieId: 496243,
        movieTitle: "Parasite",
        posterPath: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
        releaseDate: "2019-05-30",
        finalScore: 9500,
        enjoyment: 98,
        story: 98,
        acting: 95,
        soundtrack: 90,
        rewatchability: 88,
        genreScores: ["emotionalDepth": 92, "suspense": 88, "mysteryIntrigue": 85]
    )

    // Add all movies to container
    container.mainContext.insert(theShining)
    container.mainContext.insert(getOut)
    container.mainContext.insert(hereditay)
    container.mainContext.insert(superbad)
    container.mainContext.insert(grandBudapest)
    container.mainContext.insert(madMax)
    container.mainContext.insert(johnWick)
    container.mainContext.insert(interstellar)
    container.mainContext.insert(lalaland)
    container.mainContext.insert(parasite)

    return NavigationStack {
        MyRankingView()
    }
    .modelContainer(container)
}
