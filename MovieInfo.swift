//
//  MovieInfo.swift
//  Moovie
//
//  Created by Alexander McGreevy on 2/27/26.
//

import Foundation

enum Secrets {
    static var tmdbToken: String? {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "TMDB_READ_TOKEN") as? String,
              !token.isEmpty,
              !token.hasPrefix("$(") else {
            return nil
        }
        return token
    }
}

enum MediaType: String {
    case movie
    case tv
}

enum MediaCategory: String {
    case popular
    case nowPlaying = "now_playing"
    case upcoming
    case topRated = "top_rated"
    case onTheAir = "on_the_air"        // TV specific
    case airingToday = "airing_today"   // TV specific
}

struct MovieInfo: Codable, Identifiable {
    var id: Int
    var title: String
    var releaseDate: String
    var ranking: Double
    var description: String?
    var notes: String?
    var poster_path: String?
    //later add actors, image, specific rankings
    
    init(id: Int = 0, title: String = "", releaseDate: String = "", ranking: Double = 0.0, description: String? = nil, notes: String? = nil, poster_path: String? = nil){
        self.id = id
        self.title = title
        self.releaseDate = releaseDate
        self.ranking = ranking
        self.description = description
        self.notes = notes
        self.poster_path = poster_path
    }
}

extension MovieInfo {
    //add stuff for retreiving info from api

    static func fetchMedia(type: MediaType, category: MediaCategory, page: Int = 1) async throws -> [MovieInfo] {
        guard let token = Secrets.tmdbToken else {
            print("❌ TMDB Token is not configured. Please set TMDB_READ_TOKEN in your build configuration.")
            throw NSError(domain: "MovieInfo", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "TMDB API token is not configured. Please check your environment variables."
            ])
        }

        let urlString = "https://api.themoviedb.org/3/\(type.rawValue)/\(category.rawValue)?language=en-US&page=\(page)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Bearer \(token)"
        ]

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard 200...299 ~= httpResponse.statusCode else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                throw NSError(domain: "MovieInfo", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "Server returned error code: \(httpResponse.statusCode)"
                ])
            }

            let decoded = try JSONDecoder().decode(TMDBPopularResponse.self, from: data)

            return decoded.results.map {
                MovieInfo(
                    id: $0.id,
                    title: $0.displayTitle,
                    releaseDate: $0.displayDate,
                    ranking: $0.voteAverage,
                    description: $0.overview,
                    notes: nil,
                    poster_path: $0.poster_path
                )
            }
        } catch let error as DecodingError {
            print("❌ Decoding error: \(error)")
            throw NSError(domain: "MovieInfo", code: 1002, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decode response from TMDB API"
            ])
        } catch {
            print("❌ Network error: \(error)")
            throw error
        }
    }

    // Convenience methods for common use cases
    static func fetchPopularMovies(page: Int = 1) async throws -> [MovieInfo] {
        try await fetchMedia(type: .movie, category: .popular, page: page)
    }

    static func fetchPopularTVShows(page: Int = 1) async throws -> [MovieInfo] {
        try await fetchMedia(type: .tv, category: .popular, page: page)
    }

    static func fetchUpcomingMovies(page: Int = 1) async throws -> [MovieInfo] {
        try await fetchMedia(type: .movie, category: .upcoming, page: page)
    }

    static func fetchNowPlayingMovies(page: Int = 1) async throws -> [MovieInfo] {
        try await fetchMedia(type: .movie, category: .nowPlaying, page: page)
    }
}

private struct TMDBPopularResponse: Codable {
    let results: [TMDBMovie]
}

private struct TMDBMovie: Codable {
    let id: Int
    let title: String?           // for movies
    let name: String?            // for TV shows
    let overview: String?
    let releaseDate: String?     // for movies
    let firstAirDate: String?    // for TV shows
    let voteAverage: Double
    let poster_path: String?

    // Computed properties to normalize the data
    var displayTitle: String {
        title ?? name ?? "Unknown"
    }

    var displayDate: String {
        releaseDate ?? firstAirDate ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case overview
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case poster_path
    }
}
