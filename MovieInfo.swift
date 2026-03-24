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

// MARK: - Discover API Query Builder
struct DiscoverQuery {
    var sortBy: String?
    var withGenres: [Int]?
    var primaryReleaseDateGTE: String?
    var primaryReleaseDateLTE: String?
    var voteCountGTE: Int?
    var voteAverageGTE: Double?
    var page: Int = 1

    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        if let sortBy = sortBy {
            items.append(URLQueryItem(name: "sort_by", value: sortBy))
        }

        if let withGenres = withGenres, !withGenres.isEmpty {
            let genreString = withGenres.map(String.init).joined(separator: ",")
            items.append(URLQueryItem(name: "with_genres", value: genreString))
        }

        if let primaryReleaseDateGTE = primaryReleaseDateGTE {
            items.append(URLQueryItem(name: "primary_release_date.gte", value: primaryReleaseDateGTE))
        }

        if let primaryReleaseDateLTE = primaryReleaseDateLTE {
            items.append(URLQueryItem(name: "primary_release_date.lte", value: primaryReleaseDateLTE))
        }

        if let voteCountGTE = voteCountGTE {
            items.append(URLQueryItem(name: "vote_count.gte", value: "\(voteCountGTE)"))
        }

        if let voteAverageGTE = voteAverageGTE {
            items.append(URLQueryItem(name: "vote_average.gte", value: "\(voteAverageGTE)"))
        }

        return items
    }
}

// MARK: - Movie Display Modes
enum MovieMode: String, CaseIterable, Identifiable {
    case popular = "Popular"
    case topRated = "Top Rated"
    case upcoming = "Upcoming"
    case nowPlaying = "Now Playing"

    var id: String { rawValue }

    func toDiscoverQuery() -> DiscoverQuery {
        let calendar = Calendar.current
        let today = Date()

        switch self {
        case .popular:
            return DiscoverQuery(sortBy: "popularity.desc")

        case .topRated:
            return DiscoverQuery(
                sortBy: "vote_average.desc",
                voteCountGTE: 1000  // Avoid obscure movies with few votes
            )

        case .upcoming:
            // Movies releasing in the next 6 months
            let sixMonthsFromNow = calendar.date(byAdding: .month, value: 6, to: today)!
            return DiscoverQuery(
                sortBy: "popularity.desc",
                primaryReleaseDateGTE: formatDateForAPI(today),
                primaryReleaseDateLTE: formatDateForAPI(sixMonthsFromNow)
            )

        case .nowPlaying:
            // Movies released in the last 45 days
            let fortyFiveDaysAgo = calendar.date(byAdding: .day, value: -45, to: today)!
            return DiscoverQuery(
                sortBy: "popularity.desc",
                primaryReleaseDateGTE: formatDateForAPI(fortyFiveDaysAgo),
                primaryReleaseDateLTE: formatDateForAPI(today)
            )
        }
    }

    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct MovieInfo: Codable, Identifiable {
    var id: Int
    var title: String
    var releaseDate: String
    var ranking: Double
    var description: String?
    var notes: String?
    var poster_path: String?

    // Additional API fields
    var adult: Bool?
    var backdropPath: String?
    var genreIds: [Int]?
    var originalLanguage: String?
    var originalTitle: String?
    var popularity: Double?
    var video: Bool?
    var voteCount: Int?
    //later add actors, image, specific rankings

    init(id: Int = 0, title: String = "", releaseDate: String = "", ranking: Double = 0.0, description: String? = nil, notes: String? = nil, poster_path: String? = nil, adult: Bool? = nil, backdropPath: String? = nil, genreIds: [Int]? = nil, originalLanguage: String? = nil, originalTitle: String? = nil, popularity: Double? = nil, video: Bool? = nil, voteCount: Int? = nil){
        self.id = id
        self.title = title
        self.releaseDate = releaseDate
        self.ranking = ranking
        self.description = description
        self.notes = notes
        self.poster_path = poster_path
        self.adult = adult
        self.backdropPath = backdropPath
        self.genreIds = genreIds
        self.originalLanguage = originalLanguage
        self.originalTitle = originalTitle
        self.popularity = popularity
        self.video = video
        self.voteCount = voteCount
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case releaseDate
        case ranking
        case description
        case notes
        case poster_path
        case adult
        case backdropPath
        case genreIds
        case originalLanguage
        case originalTitle
        case popularity
        case video
        case voteCount
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
                    poster_path: $0.posterPath,
                    adult: $0.adult,
                    backdropPath: $0.backdropPath,
                    genreIds: $0.genreIds,
                    originalLanguage: $0.originalLanguage,
                    originalTitle: $0.originalTitle,
                    popularity: $0.popularity,
                    video: $0.video,
                    voteCount: $0.voteCount
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

    // MARK: - Unified Discover API Method
    static func fetchMoviesWithDiscover(query: DiscoverQuery) async throws -> [MovieInfo] {
        guard let token = Secrets.tmdbToken else {
            print("❌ TMDB Token is not configured. Please set TMDB_READ_TOKEN in your build configuration.")
            throw NSError(domain: "MovieInfo", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "TMDB API token is not configured. Please check your environment variables."
            ])
        }

        var components = URLComponents(string: "https://api.themoviedb.org/3/discover/movie")!
        components.queryItems = query.toQueryItems()

        guard let url = components.url else {
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
                    poster_path: $0.posterPath,
                    adult: $0.adult,
                    backdropPath: $0.backdropPath,
                    genreIds: $0.genreIds,
                    originalLanguage: $0.originalLanguage,
                    originalTitle: $0.originalTitle,
                    popularity: $0.popularity,
                    video: $0.video,
                    voteCount: $0.voteCount
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

    // Convenience method for fetching by mode
    static func fetchMovies(mode: MovieMode, page: Int = 1) async throws -> [MovieInfo] {
        var query = mode.toDiscoverQuery()
        query.page = page
        return try await fetchMoviesWithDiscover(query: query)
    }
}

private struct TMDBPopularResponse: Codable {
    let page: Int
    let results: [TMDBMovie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

private struct TMDBMovie: Codable {
    let adult: Bool
    let backdropPath: String?
    let genreIds: [Int]
    let id: Int
    let originalLanguage: String
    let originalTitle: String?      // for movies
    let title: String?               // for movies
    let name: String?                // for TV shows
    let overview: String?
    let popularity: Double
    let posterPath: String?
    let releaseDate: String?         // for movies
    let firstAirDate: String?        // for TV shows
    let video: Bool?                 // only for movies
    let voteAverage: Double
    let voteCount: Int

    // Computed properties to normalize the data
    var displayTitle: String {
        title ?? name ?? "Unknown"
    }

    var displayDate: String {
        releaseDate ?? firstAirDate ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIds = "genre_ids"
        case id
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case title
        case name
        case overview
        case popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}
