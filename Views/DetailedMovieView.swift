//
//  DetailedMovieView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 3/18/26.
//

import SwiftUI
import Kingfisher

struct DetailedMovieView: View {

    let movie : MovieInfo
    @State private var isLoading = false
    @State private var errorMessage: String?


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Poster and Main Info with Backdrop Background
                ZStack(alignment: .topLeading) {
                    // Backdrop Image (dimmed background)
                    if let backdropPath = movie.backdropPath, !backdropPath.isEmpty {
                        let backdropURL = "https://image.tmdb.org/t/p/w1280\(backdropPath)"
                        KFImage(URL(string: backdropURL))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                            .blur(radius: 4)
                            .opacity(0.555)
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                    }

                    // Poster and Info (foreground)
                    HStack(alignment: .top, spacing: 16) {
                        // Poster
                        if let poster_path = movie.poster_path, !poster_path.isEmpty {
                            let imageURL = "https://image.tmdb.org/t/p/w500\(poster_path)"
                            KFImage(URL(string: imageURL))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 145)
                                .cornerRadius(8)
                                .shadow(radius: 8)
                        }

                        // Main Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(movie.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .shadow(radius: 2)

                            if let originalTitle = movie.originalTitle, originalTitle != movie.title {
                                Text(originalTitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }

                            Text("Release Date: \(movie.releaseDate)")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            // Rating and Votes
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text("\(movie.ranking, specifier: "%.1f")")
                                    .font(.headline)
                                if let voteCount = movie.voteCount {
                                    Text("(\(voteCount) votes)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Popularity
                            if let popularity = movie.popularity {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Popularity: \(popularity, specifier: "%.1f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding()
                }
                .cornerRadius(12)

                // Additional Details
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    Text("Details")
                        .font(.headline)
                        .fontWeight(.semibold)

                    // Original Language
                    if let language = movie.originalLanguage {
                        HStack {
                            Text("Original Language:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(language.uppercased())
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    // Genre IDs
                    if let genreIds = movie.genreIds, !genreIds.isEmpty {
                        HStack(alignment: .top) {
                            Text("Genre IDs:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(genreIds.map { String($0) }.joined(separator: ", "))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    // Adult Content Flag
                    if let adult = movie.adult, adult {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("Adult Content")
                                .font(.caption)
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
                    }

                    // Video Flag
                    if let video = movie.video, video {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text("Video Available")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                }

                // Overview
                if let description = movie.description, !description.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }

                // Notes
                if let notes = movie.notes, !notes.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    DetailedMovieView(movie: MovieInfo(id: 1, title: "Example Movie", releaseDate: "2024-01-01", ranking: 8.5, description: "This is an example movie description.", poster_path: "/taYgn3RRpCGlTGdaGQvnSIOzXFy.jpg", adult: false, backdropPath: "/eNJhWy7xFzR74SYaSJHqJZuroDm.jpg", originalLanguage: "en", originalTitle: "Example Movie Original", popularity: 567.8,  video: false, voteCount: 1234))
}

