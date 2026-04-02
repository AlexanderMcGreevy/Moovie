//
//  RankingsManager.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/2/26.
//

import Foundation
import SwiftData

@Observable
class RankingsManager {
    var modelContext: ModelContext?

    // Weights for universal sliders (must add up to 1.0)
    private let weights: [String: Double] = [
        "enjoyment": 0.35,      // 35%
        "story": 0.25,          // 25%
        "acting": 0.15,         // 15%
        "soundtrack": 0.15,     // 15%
        "rewatchability": 0.10  // 10%
    ]

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - Score Calculation

    func calculateInitialScore(sliderValues: SliderValues) -> Int {
        let enjoymentScore = Double(sliderValues.enjoyment) * weights["enjoyment"]!
        let storyScore = Double(sliderValues.story) * weights["story"]!
        let actingScore = Double(sliderValues.acting) * weights["acting"]!
        let soundtrackScore = Double(sliderValues.soundtrack) * weights["soundtrack"]!
        let rewatchScore = Double(sliderValues.rewatchability) * weights["rewatchability"]!

        let totalScore = (enjoymentScore + storyScore + actingScore + soundtrackScore + rewatchScore) * 100

        return Int(totalScore.rounded())
    }

    // MARK: - Neighbor Finding

    func findNearestNeighbors(score: Int) -> (above: UserMovieRanking?, below: UserMovieRanking?) {
        guard let context = modelContext else { return (nil, nil) }

        let descriptor = FetchDescriptor<UserMovieRanking>(
            sortBy: [SortDescriptor(\.finalScore, order: .reverse)]
        )

        guard let allRankings = try? context.fetch(descriptor) else {
            return (nil, nil)
        }

        var nearestAbove: UserMovieRanking?
        var nearestBelow: UserMovieRanking?

        for ranking in allRankings {
            if ranking.finalScore > score {
                nearestAbove = ranking
            } else if ranking.finalScore < score {
                nearestBelow = ranking
                break // Since sorted, this is the nearest below
            }
        }

        return (nearestAbove, nearestBelow)
    }

    // MARK: - Comparative Adjustment

    func adjustScoreBasedOnComparison(
        currentScore: Int,
        comparedTo: UserMovieRanking,
        choice: ComparisonChoice,
        allRankings: [UserMovieRanking]
    ) -> Int {
        switch choice {
        case .better:
            // Find next ranking above the compared movie
            let higherRankings = allRankings.filter { $0.finalScore > comparedTo.finalScore }
            if let nextHigher = higherRankings.last {
                // Place between comparedTo and nextHigher
                return (comparedTo.finalScore + nextHigher.finalScore) / 2
            } else {
                // This is the best movie
                return comparedTo.finalScore + 100
            }

        case .worse:
            // Find next ranking below the compared movie
            let lowerRankings = allRankings.filter { $0.finalScore < comparedTo.finalScore }
            if let nextLower = lowerRankings.first {
                // Place between comparedTo and nextLower
                return (comparedTo.finalScore + nextLower.finalScore) / 2
            } else {
                // This is the worst movie
                return max(0, comparedTo.finalScore - 100)
            }

        case .same:
            // Need tie-breaker - return same score to trigger tie-breaker question
            return comparedTo.finalScore
        }
    }

    func calculateFinalScore(
        initialScore: Int,
        comparisons: [ComparativeResult],
        allRankings: [UserMovieRanking]
    ) -> Int {
        var currentScore = initialScore

        for comparison in comparisons {
            if let comparedRanking = allRankings.first(where: { $0.movieId == comparison.comparedToMovieId }) {
                currentScore = adjustScoreBasedOnComparison(
                    currentScore: currentScore,
                    comparedTo: comparedRanking,
                    choice: comparison.choice,
                    allRankings: allRankings
                )
            }
        }

        return currentScore
    }

    // MARK: - Ranking Operations

    func addRanking(
        movie: MovieInfo,
        sliderValues: SliderValues,
        comparisons: [ComparativeResult]
    ) throws {
        guard let context = modelContext else {
            print("❌ RankingsManager: No modelContext available!")
            return
        }

        let initialScore = calculateInitialScore(sliderValues: sliderValues)
        print("📊 RankingsManager: Initial score calculated: \(initialScore)")

        let allRankings = try fetchAllRankings()
        print("📋 RankingsManager: Current rankings count: \(allRankings.count)")

        let finalScore = calculateFinalScore(
            initialScore: initialScore,
            comparisons: comparisons,
            allRankings: allRankings
        )
        print("🎯 RankingsManager: Final score: \(finalScore)")

        let ranking = UserMovieRanking(
            movieId: movie.id,
            movieTitle: movie.title,
            posterPath: movie.poster_path,
            releaseDate: movie.releaseDate,
            finalScore: finalScore,
            enjoyment: sliderValues.enjoyment,
            story: sliderValues.story,
            acting: sliderValues.acting,
            soundtrack: sliderValues.soundtrack,
            rewatchability: sliderValues.rewatchability,
            genreScores: sliderValues.genreScores,
            comparisons: comparisons
        )

        print("💾 RankingsManager: Inserting ranking into context...")
        context.insert(ranking)

        print("💾 RankingsManager: Saving context...")
        try context.save()
        print("✅ RankingsManager: Save completed successfully!")
    }

    func updateRanking(
        rankingId: UUID,
        sliderValues: SliderValues,
        comparisons: [ComparativeResult]
    ) throws {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<UserMovieRanking>(
            predicate: #Predicate { $0.id == rankingId }
        )

        guard let ranking = try context.fetch(descriptor).first else { return }

        let initialScore = calculateInitialScore(sliderValues: sliderValues)
        let allRankings = try fetchAllRankings().filter { $0.id != rankingId }
        let finalScore = calculateFinalScore(
            initialScore: initialScore,
            comparisons: comparisons,
            allRankings: allRankings
        )

        ranking.enjoyment = sliderValues.enjoyment
        ranking.story = sliderValues.story
        ranking.acting = sliderValues.acting
        ranking.soundtrack = sliderValues.soundtrack
        ranking.rewatchability = sliderValues.rewatchability
        ranking.finalScore = finalScore
        ranking.genreScores = sliderValues.genreScores
        ranking.comparisons = comparisons
        ranking.lastModified = Date()

        try context.save()
    }

    func deleteRanking(rankingId: UUID) throws {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<UserMovieRanking>(
            predicate: #Predicate { $0.id == rankingId }
        )

        guard let ranking = try context.fetch(descriptor).first else { return }

        context.delete(ranking)
        try context.save()
    }

    func fetchAllRankings() throws -> [UserMovieRanking] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<UserMovieRanking>(
            sortBy: [SortDescriptor(\.finalScore, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    func isMovieAlreadyRanked(movieId: Int) throws -> Bool {
        guard let context = modelContext else { return false }

        let descriptor = FetchDescriptor<UserMovieRanking>(
            predicate: #Predicate { $0.movieId == movieId }
        )

        let results = try context.fetch(descriptor)
        return !results.isEmpty
    }
}

// MARK: - Supporting Types

struct SliderValues {
    var enjoyment: Int
    var story: Int
    var acting: Int
    var soundtrack: Int
    var rewatchability: Int
    var genreScores: [String: Int]

    init(
        enjoyment: Int = 50,
        story: Int = 50,
        acting: Int = 50,
        soundtrack: Int = 50,
        rewatchability: Int = 50,
        genreScores: [String: Int] = [:]
    ) {
        self.enjoyment = enjoyment
        self.story = story
        self.acting = acting
        self.soundtrack = soundtrack
        self.rewatchability = rewatchability
        self.genreScores = genreScores
    }
}
