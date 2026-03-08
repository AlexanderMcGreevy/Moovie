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
                    VStack {
                        Text("Could not load movies")
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } else {
                    List(movies) { movie in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(movie.title)
                                .font(.headline)

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
            movies = try await MovieInfo.fetchTopMovies()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    TopMoviesView(
        previewMovies: [
            MovieInfo(
                id: 1,
                title: "Inception",
                releaseDate: "2010-07-16",
                ranking: 8.8,
                description: "A thief enters people’s dreams to steal information.",
                notes: nil
            ),
            MovieInfo(
                id: 2,
                title: "Interstellar",
                releaseDate: "2014-11-07",
                ranking: 8.6,
                description: "A team travels through a wormhole in space to try to save humanity.",
                notes: nil
            )
        ]
    )
}
