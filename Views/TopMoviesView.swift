import SwiftUI
import Kingfisher

struct TopMoviesView: View {
    @State private var movies: [MovieInfo]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedMode: MovieMode = .popular
    @State private var searchQuery: String = ""

    init(previewMovies: [MovieInfo] = []) {
        _movies = State(initialValue: previewMovies)
    }

    // Computed property to filter movies based on search query
    private var filteredMovies: [MovieInfo] {
        if searchQuery.isEmpty {
            return movies
        } else {
            return movies.filter { movie in
                movie.title.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Picker
                Picker("Movie Mode", selection: $selectedMode) {
                    ForEach(MovieMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content
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
                        List(filteredMovies) { movie in
                            NavigationLink(destination: DetailedMovieView(movie: movie)) {
                                LazyVStack(alignment: .center, spacing: 4) {
                                    if let poster_path = movie.poster_path, !poster_path.isEmpty {
                                        let imageURL = "https://image.tmdb.org/t/p/w500\(poster_path)"
                                        KFImage(URL(string: imageURL))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: 250)
                                            .cornerRadius(8)
                                    }
                                    Text(movie.title)
                                        .font(.headline)


                                    Text("Release Date: \(movie.releaseDate)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    Text("Rating: \(movie.ranking, specifier: "%.1f")")
                                        .font(.subheadline)


                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .searchable(text: $searchQuery, prompt: "Search movies...")
                    }
                }
            }
            .navigationTitle("Movies")
            .task {
                if movies.isEmpty {
                    await loadMovies()
                }
            }
            .onChange(of: selectedMode) { oldValue, newValue in
                Task {
                    await loadMovies()
                }
            }
        }
    }

    func loadMovies() async {
        isLoading = true
        errorMessage = nil

        do {
            movies = try await MovieInfo.fetchMovies(mode: selectedMode)
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
