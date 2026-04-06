//
//  CompareRankingsView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import SwiftUI
import Kingfisher

struct CompareRankingsView: View {
    let myRanking: UserMovieRanking
    let friendRanking: SharedRanking
    let friendUsername: String

    private var scoreDifference: Double {
        Double(myRanking.finalScore - friendRanking.finalScore) / 1000
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Movie Header
                movieHeader

                // Overall Scores
                overallScoreComparison

                // Universal Scores Comparison
                universalScoresComparison

                // Genre Scores Comparison
                genreScoresComparison

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Compare Rankings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Movie Header

    private var movieHeader: some View {
        VStack(spacing: 16) {
            if let posterPath = myRanking.posterPath, !posterPath.isEmpty {
                let imageURL = "https://image.tmdb.org/t/p/w342\(posterPath)"
                KFImage(URL(string: imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text(myRanking.movieTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(myRanking.releaseDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Overall Score Comparison

    private var overallScoreComparison: some View {
        VStack(spacing: 16) {
            Text("Overall Scores")
                .font(.headline)

            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1f", Double(myRanking.finalScore) / 1000))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.blue)
                }

                VStack(spacing: 8) {
                    Text(friendUsername)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1f", Double(friendRanking.finalScore) / 1000))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.green)
                }
            }

            // Difference
            HStack(spacing: 8) {
                Image(systemName: scoreDifference > 0 ? "arrow.up.circle.fill" : scoreDifference < 0 ? "arrow.down.circle.fill" : "equal.circle.fill")
                    .foregroundColor(scoreDifference > 0 ? .blue : scoreDifference < 0 ? .red : .gray)

                Text(scoreDifference > 0 ? "You rated \(String(format: "%.1f", abs(scoreDifference))) higher" :
                     scoreDifference < 0 ? "\(friendUsername) rated \(String(format: "%.1f", abs(scoreDifference))) higher" :
                     "You both rated it the same!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }

    // MARK: - Universal Scores

    private var universalScoresComparison: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Scores")
                .font(.headline)

            ComparisonRow(
                title: "Enjoyment",
                emoji: "😍",
                yourScore: myRanking.enjoyment,
                friendScore: friendRanking.enjoyment
            )

            ComparisonRow(
                title: "Story",
                emoji: "📖",
                yourScore: myRanking.story,
                friendScore: friendRanking.story
            )

            ComparisonRow(
                title: "Acting",
                emoji: "🎭",
                yourScore: myRanking.acting,
                friendScore: friendRanking.acting
            )

            ComparisonRow(
                title: "Soundtrack",
                emoji: "🎼",
                yourScore: myRanking.soundtrack,
                friendScore: friendRanking.soundtrack
            )

            ComparisonRow(
                title: "Rewatchability",
                emoji: "🔥",
                yourScore: myRanking.rewatchability,
                friendScore: friendRanking.rewatchability
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Genre Scores

    private var genreScoresComparison: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !commonGenreScoreKeys.isEmpty {
                Text("Genre Scores")
                    .font(.headline)

                ForEach(commonGenreScoreKeys, id: \.self) { key in
                    if let yourScore = myRanking.genreScores[key],
                       let friendScore = friendRanking.genreScores[key] {
                        ComparisonRow(
                            title: genreTitle(for: key),
                            emoji: genreEmoji(for: key),
                            yourScore: yourScore,
                            friendScore: friendScore
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var commonGenreScoreKeys: [String] {
        let yourGenres = Set(myRanking.genreScores.keys)
        let friendGenres = Set(friendRanking.genreScores.keys)
        let common = yourGenres.intersection(friendGenres)
        return Array(common).sorted()
    }

    // MARK: - Helper Functions

    private func genreTitle(for key: String) -> String {
        switch key {
        case "scariness": return "Scariness"
        case "funniness": return "Funniness"
        case "actionIntensity": return "Action Intensity"
        case "romanceLevel": return "Romance Level"
        case "mindBending": return "Mind-Bending"
        case "suspense": return "Suspense"
        case "emotionalDepth": return "Emotional Depth"
        case "visualCreativity": return "Visual Creativity"
        case "worldBuilding": return "World-Building"
        case "mysteryIntrigue": return "Mystery/Intrigue"
        case "educationalValue": return "Educational Value"
        case "adventureScale": return "Adventure Scale"
        case "soundtrackQuality": return "Musical Quality"
        case "warIntensity": return "War Intensity"
        case "westernVibes": return "Western Vibes"
        case "historicalAccuracy": return "Historical Feel"
        case "familyFriendly": return "Family-Friendly"
        case "tvProduction": return "Production Quality"
        default: return key
        }
    }

    private func genreEmoji(for key: String) -> String {
        switch key {
        case "scariness": return "💀"
        case "funniness": return "🤣"
        case "actionIntensity": return "💥"
        case "romanceLevel": return "💖"
        case "mindBending": return "🌌"
        case "suspense": return "😱"
        case "emotionalDepth": return "💔"
        case "visualCreativity": return "✨"
        case "worldBuilding": return "🌟"
        case "mysteryIntrigue": return "🕵️"
        case "educationalValue": return "🧠"
        case "adventureScale": return "🚀"
        case "soundtrackQuality": return "🎼"
        case "warIntensity": return "🔥"
        case "westernVibes": return "🐎"
        case "historicalAccuracy": return "⏳"
        case "familyFriendly": return "🎉"
        case "tvProduction": return "🎬"
        default: return "⭐"
        }
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let title: String
    let emoji: String
    let yourScore: Int
    let friendScore: Int

    private var difference: Int {
        yourScore - friendScore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(emoji)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack(spacing: 16) {
                // Your score
                HStack {
                    Text("You:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(yourScore)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Difference indicator
                if difference != 0 {
                    Text(difference > 0 ? "+\(difference)" : "\(difference)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(difference > 0 ? .blue : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((difference > 0 ? Color.blue : Color.red).opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Image(systemName: "equal")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Friend score
                HStack {
                    Text("Friend:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(friendScore)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Visual bar comparison
            GeometryReader { geometry in
                HStack(spacing: 4) {
                    // Your bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: geometry.size.width * (CGFloat(yourScore) / 100) * 0.48)

                    Spacer()

                    // Friend bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.7))
                        .frame(width: geometry.size.width * (CGFloat(friendScore) / 100) * 0.48)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let myRanking = UserMovieRanking(
        movieId: 694,
        movieTitle: "The Shining",
        posterPath: "/xazWoLealQwEgqZ89MLZklLZD3k.jpg",
        releaseDate: "1980-05-23",
        finalScore: 9500,
        enjoyment: 95,
        story: 90,
        acting: 98,
        soundtrack: 92,
        rewatchability: 88,
        genreScores: ["scariness": 98, "suspense": 95]
    )

    let friendRanking = SharedRanking(
        friendId: UUID(),
        movieId: 694,
        movieTitle: "The Shining",
        posterPath: "/xazWoLealQwEgqZ89MLZklLZD3k.jpg",
        releaseDate: "1980-05-23",
        finalScore: 8200,
        enjoyment: 82,
        story: 85,
        acting: 90,
        soundtrack: 78,
        rewatchability: 70,
        genreScores: ["scariness": 88, "suspense": 85]
    )

    return NavigationStack {
        CompareRankingsView(
            myRanking: myRanking,
            friendRanking: friendRanking,
            friendUsername: "Sarah"
        )
    }
}
