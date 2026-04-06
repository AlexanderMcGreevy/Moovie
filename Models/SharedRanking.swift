//
//  SharedRanking.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import Foundation
import SwiftData

@Model
class SharedRanking {
    @Attribute(.unique) var id: UUID
    var friendId: UUID  // Which friend this ranking belongs to
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
    var lastUpdated: Date

    init(
        friendId: UUID,
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
        genreScores: [String: Int] = [:]
    ) {
        self.id = UUID()
        self.friendId = friendId
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
        self.lastUpdated = Date()

        // Encode genre scores
        if let data = try? JSONEncoder().encode(genreScores) {
            self.genreScoresData = data
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
}
