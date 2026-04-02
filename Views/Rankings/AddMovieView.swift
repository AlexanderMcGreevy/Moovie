//
//  AddMovieView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 2/27/26.
//

import SwiftUI
import Kingfisher

struct AddMovieView: View {
    @State private var searchQuery: String = ""
    @State private var searchResults: [MovieInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedMovie: MovieInfo?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search for a movie to rank...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()

                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                            searchResults = []
                            errorMessage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Content Area
                if isLoading {
                    Spacer()
                    ProgressView("Searching...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Try Again") {
                            Task {
                                await performSearch()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer()
                } else if searchQuery.isEmpty {
                    // Empty State
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Search for a Movie")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Find a movie to add to your rankings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if searchResults.isEmpty {
                    // No Results
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No movies found")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Search Results
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults) { movie in
                                MovieSearchRow(movie: movie)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedMovie = movie
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Add Movie to Rank")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: searchQuery) { oldValue, newValue in
                Task {
                    // Debounce search
                    try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
                    if searchQuery == newValue && !newValue.isEmpty {
                        await performSearch()
                    } else if newValue.isEmpty {
                        searchResults = []
                    }
                }
            }
            .navigationDestination(item: $selectedMovie) { movie in
                RankingView(movie: movie)
            }
        }
    }

    func performSearch() async {
        isLoading = true
        errorMessage = nil

        do {
            searchResults = try await MovieInfo.searchMovies(query: searchQuery)
            isLoading = false
        } catch {
            errorMessage = "Failed to search movies: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

struct MovieSearchRow: View {
    let movie: MovieInfo

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster
            if let posterPath = movie.poster_path, !posterPath.isEmpty {
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
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(movie.releaseDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", movie.ranking))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    AddMovieView()
}
