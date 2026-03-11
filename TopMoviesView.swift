import SwiftUI

struct TopMoviesView: View {
    @State private var movies: [MovieInfo]
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(previewMovies: [MovieInfo] = []) {
        _movies = State(initialValue: previewMovies)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading movies...")
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) {
                        Text("Could not load movies")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Retry") {
                            Task {
                                await loadMovies()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    List(movies) { movie in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(movie.title)
                                .font(.headline)
                            Image(movie.posterImageName)

                            Text("Release Date: \(movie.releaseDate)")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("Rating: \(movie.ranking, specifier: "%.1f")")
                                .font(.subheadline)

                            if let description = movie.description, !description.isEmpty {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Top Movies")
            .task {
                if movies.isEmpty {
                    await loadMovies()
                }
            }
        }
    }

    func loadMovies() async {
        isLoading = true
        errorMessage = nil

        do {
            movies = try await MovieInfo.fetchPopularMovies()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    TopMoviesView(
        previewMovies: [
            ]
    )
}
