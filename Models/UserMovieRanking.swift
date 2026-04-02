//
//  UserMovieRanking.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/2/26.
//

import Foundation
import SwiftData

@Model
class UserMovieRanking {
    @Attribute(.unique) var id: UUID
    var movieId: Int
    var movieTitle: String
    var posterPath: String?
    var releaseDate: String

    // Final calculated score (0-10000)
    var finalScore: Int

    // Universal slider values (0-100)
    var enjoyment: Int
    var story: Int
    var acting: Int
    var soundtrack: Int
    var rewatchability: Int

    // Genre-specific scores (0-100, stored as JSON)
    var genreScoresData: Data?

    // Metadata
    var dateRanked: Date
    var lastModified: Date
    var notes: String?

    // Comparative history (stored as JSON)
    var comparisonsData: Data?

    init(
        movieId: Int,
        movieTitle: String,
        posterPath: String?,
        releaseDate: String,
        finalScore: Int,
        enjoyment: Int,
        story: Int,
        acting: Int,
        soundtrack: Int,
        rewatchability: Int,
        genreScores: [String: Int] = [:],
        comparisons: [ComparativeResult] = []
    ) {
        self.id = UUID()
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.posterPath = posterPath
        self.releaseDate = releaseDate
        self.finalScore = finalScore
        self.enjoyment = enjoyment
        self.story = story
        self.acting = acting
        self.soundtrack = soundtrack
        self.rewatchability = rewatchability
        self.dateRanked = Date()
        self.lastModified = Date()
        self.notes = nil

        // Encode genre scores
        if let data = try? JSONEncoder().encode(genreScores) {
            self.genreScoresData = data
        }

        // Encode comparisons
        if let data = try? JSONEncoder().encode(comparisons) {
            self.comparisonsData = data
        }
    }

    // Computed property for genre scores
    var genreScores: [String: Int] {
        get {
            guard let data = genreScoresData else { return [:] }
            return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
        }
        set {
            genreScoresData = try? JSONEncoder().encode(newValue)
        }
    }

    // Computed property for comparisons
    var comparisons: [ComparativeResult] {
        get {
            guard let data = comparisonsData else { return [] }
            return (try? JSONDecoder().decode([ComparativeResult].self, from: data)) ?? []
        }
        set {
            comparisonsData = try? JSONEncoder().encode(newValue)
        }
    }
}

struct ComparativeResult: Codable {
    let comparedToMovieId: Int
    let comparedToMovieTitle: String
    let choice: ComparisonChoice
    let timestamp: Date
}

enum ComparisonChoice: String, Codable {
    case better
    case same
    case worse
}
