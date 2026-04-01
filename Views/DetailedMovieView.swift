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
    @State private var cast: [CastMember] = []
    @State private var fullMovieDetails: MovieInfo?

    var displayMovie: MovieInfo {
        fullMovieDetails ?? movie
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Poster and Main Info with Backdrop Background
                    ZStack(alignment: .bottomLeading) {
                        // Backdrop Image (dimmed background)
                        if let backdropPath = displayMovie.backdropPath, !backdropPath.isEmpty {
                            let backdropURL = "https://image.tmdb.org/t/p/w1280\(backdropPath)"
                            KFImage(URL(string: backdropURL))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width)
                                .frame(height: 300)
                                .clipped()
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0.85),
                                            Color.black.opacity(0.5),
                                            Color.black.opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                        }

                        // Poster and Info (foreground)
                        HStack(alignment: .bottom, spacing: 16) {
                            // Poster
                            if let poster_path = displayMovie.poster_path, !poster_path.isEmpty {
                                let imageURL = "https://image.tmdb.org/t/p/w500\(poster_path)"
                                KFImage(URL(string: imageURL))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                            }

                            // Main Info
                            VStack(alignment: .leading, spacing: 6) {
                                Text(displayMovie.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 4, x: 0, y: 2)
                                    .lineLimit(3)

                                if let originalTitle = displayMovie.originalTitle, originalTitle != displayMovie.title {
                                    Text(originalTitle)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                        .italic()
                                        .shadow(color: .black, radius: 2, x: 0, y: 1)
                                        .lineLimit(2)
                                }

                                Text("Release Date: \(displayMovie.releaseDate)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .shadow(color: .black, radius: 2, x: 0, y: 1)

                                // Rating and Votes
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                        .shadow(color: .black, radius: 2, x: 0, y: 1)
                                    Text("\(displayMovie.ranking, specifier: "%.1f")")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 2, x: 0, y: 1)
                                    if let voteCount = displayMovie.voteCount {
                                        Text("(\(voteCount) votes)")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                                    }
                                }

                                // Popularity
                                if let popularity = displayMovie.popularity {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .foregroundColor(.blue.opacity(0.9))
                                            .font(.caption)
                                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                                        Text("Popularity: \(popularity, specifier: "%.1f")")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                            .shadow(color: .black, radius: 2, x: 0, y: 1)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .frame(width: geometry.size.width)

                // Additional Details
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    Text("Details")
                        .font(.headline)
                        .fontWeight(.semibold)

                    // Original Language
                    if let language = displayMovie.originalLanguage {
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
                    if let genreIds = displayMovie.genreIds, !genreIds.isEmpty {
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
                    if let adult = displayMovie.adult, adult {
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
                    if let video = displayMovie.video, video {
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
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Overview
                if let description = displayMovie.description, !description.isEmpty {
                    Divider()
                        .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                // Notes
                if let notes = displayMovie.notes, !notes.isEmpty {
                    Divider()
                        .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                // Cast
                if !cast.isEmpty {
                    Divider()
                        .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cast")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(cast.prefix(20)) { castMember in
                                    NavigationLink(destination: PersonDetailView(personId: castMember.id)) {
                                        VStack(spacing: 8) {
                                            if let profilePath = castMember.profilePath, !profilePath.isEmpty {
                                                let imageURL = "https://image.tmdb.org/t/p/w500\(profilePath)"
                                                KFImage(URL(string: imageURL))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(Circle())
                                                    .shadow(radius: 4)
                                            } else {
                                                Circle()
                                                    .fill(Color(.systemGray5))
                                                    .frame(width: 80, height: 80)
                                                    .overlay(
                                                        Image(systemName: "person.fill")
                                                            .foregroundColor(.secondary)
                                                    )
                                            }

                                            VStack(spacing: 2) {
                                                Text(castMember.name)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)

                                                Text(castMember.character)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .frame(width: 80)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(edges: .top)
        }
        .task {
            await loadCast()
        }
    }

    func loadCast() async {
        do {
            // Check if we need to fetch full movie details
            // (e.g., when coming from person's movie credits, we only have partial data)
            if movie.backdropPath == nil || movie.genreIds == nil {
                async let details = MovieInfo.fetchMovieDetails(movieId: movie.id)
                async let credits = MovieInfo.fetchMovieCredits(movieId: movie.id)

                fullMovieDetails = try await details
                cast = try await credits
            } else {
                cast = try await MovieInfo.fetchMovieCredits(movieId: movie.id)
            }
        } catch {
            print("Failed to load cast: \(error.localizedDescription)")
        }
    }
}

#Preview {
    DetailedMovieView(movie: MovieInfo(id: 1, title: "Example Movie", releaseDate: "2024-01-01", ranking: 8.5, description: "This is an example movie description.", poster_path: "/taYgn3RRpCGlTGdaGQvnSIOzXFy.jpg", adult: false, backdropPath: "/eNJhWy7xFzR74SYaSJHqJZuroDm.jpg", originalLanguage: "en", originalTitle: "Example Movie Original", popularity: 567.8,  video: false, voteCount: 1234))
}

