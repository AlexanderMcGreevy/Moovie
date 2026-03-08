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

struct MovieInfo: Codable, Identifiable {
    var id: Int
    var title: String
    var releaseDate: String
    var ranking: Double
    var description: String?
    var notes: String?
    //later add actors, image, specific rankings
    
    init(id: Int = 0, title: String = "", releaseDate: String = "", ranking: Double = 0.0, description: String? = nil, notes: String? = nil){
        self.id = id
        self.title = title
        self.releaseDate = releaseDate
        self.ranking = ranking
        self.description = description
        self.notes = notes
    }
}

extension MovieInfo {
    //add stuff for retreiving info from api
    
    static func fetchTopMovies() async throws -> [MovieInfo] {
        guard let token = Secrets.tmdbToken else {
            throw URLError(.userAuthenticationRequired)
        }

        let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(TMDBPopularResponse.self, from: data)

        return decoded.results.map {
            MovieInfo(
                id: $0.id,
                title: $0.title,
                releaseDate: $0.releaseDate ?? "",
                ranking: $0.voteAverage,
                description: $0.overview,
                notes: nil
            )
        }
    }
}

private struct TMDBPopularResponse: Codable {
    let results: [TMDBMovie]
}

private struct TMDBMovie: Codable {
    let id: Int
    let title: String
    let overview: String?
    let releaseDate: String?
    let voteAverage: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }
}
