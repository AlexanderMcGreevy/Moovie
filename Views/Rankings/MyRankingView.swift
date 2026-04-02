//
//  MyRankingView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 2/27/26.
//

import SwiftUI
import SwiftData
import Kingfisher

struct MyRankingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserMovieRanking.finalScore, order: .reverse) private var rankings: [UserMovieRanking]

    @State private var selectedRanking: UserMovieRanking?
    @State private var showingEditSheet = false
    @State private var rankingToDelete: UserMovieRanking?
    @State private var showingDeleteAlert = false

    var body: some View {
        Group {
            if rankings.isEmpty {
                emptyStateView
            } else {
                rankingsListView
            }
        }
        .navigationTitle("My Rankings")
        .onAppear {
            print("📺 MyRankingView appeared - Rankings count: \(rankings.count)")
        }
        .sheet(item: $selectedRanking) { ranking in
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
            ForEach(Array(rankings.enumerated()), id: \.element.id) { index, ranking in
                RankingRow(ranking: ranking, position: index + 1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRanking = ranking
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            rankingToDelete = ranking
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            selectedRanking = ranking
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
        modelContext.delete(ranking)
        try? modelContext.save()
    }
}

// MARK: - Ranking Row Component

struct RankingRow: View {
    let ranking: UserMovieRanking
    let position: Int

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
                HStack(spacing: 12) {
                    ScorePill(emoji: "😍", value: ranking.enjoyment)
                    ScorePill(emoji: "📖", value: ranking.story)
                    ScorePill(emoji: "🎭", value: ranking.acting)
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
}

// MARK: - Score Pill Component

struct ScorePill: View {
    let emoji: String
    let value: Int

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
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        MyRankingView()
    }
    .modelContainer(for: UserMovieRanking.self, inMemory: true)
}
