import SwiftUI
import Kingfisher

struct TopMoviesView: View {
    @State private var movies: [MovieInfo]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedMode: MovieMode = .popular
    @State private var searchQuery: String = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var debouncedSearchQuery: String = ""
    @State private var selectedGenres: Set<MovieGenre> = []
    @State private var isGenrePickerExpanded: Bool = false
    @State private var movieToRank: MovieInfo?

    init(previewMovies: [MovieInfo] = []) {
        _movies = State(initialValue: previewMovies)
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

                // Genre Picker - Expandable Section
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            isGenrePickerExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text(genrePickerLabel)
                                .foregroundColor(.primary)
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: isGenrePickerExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                    }

                    if isGenrePickerExpanded {
                        FlowLayout(spacing: 8) {
                            ForEach(MovieGenre.allCases.filter { $0 != .all }) { genre in
                                Button(action: {
                                    toggleGenre(genre)
                                }) {
                                    Text(genre.displayName)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedGenres.contains(genre) ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(selectedGenres.contains(genre) ? .white : .primary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .transition(.opacity)
                    }
                }

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
                        List(movies) { movie in
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
                            .swipeActions(edge: .trailing) {
                                Button {
                                    movieToRank = movie
                                } label: {
                                    Label("Rank", systemImage: "star.fill")
                                }
                                .tint(.yellow)
                            }
                        }
                        .searchable(text: $searchQuery, prompt: "Search movies...")
                    }
                }
            }
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
            .onChange(of: selectedGenres) { oldValue, newValue in
                Task {
                    await loadMovies()
                }
            }
            .onChange(of: searchQuery) { oldValue, newValue in
                // Cancel previous search task
                searchTask?.cancel()

                // Create new debounced search task
                searchTask = Task {
                    // Wait for 0.8 seconds
                    try? await Task.sleep(nanoseconds: 800_000_000)

                    // Check if task was cancelled
                    guard !Task.isCancelled else { return }

                    // Update debounced query which will trigger loadMovies
                    debouncedSearchQuery = newValue
                }
            }
            .onChange(of: debouncedSearchQuery) { oldValue, newValue in
                Task {
                    await loadMovies()
                }
            }
            .onSubmit(of: .search) {
                // When user presses enter, immediately search
                searchTask?.cancel()
                debouncedSearchQuery = searchQuery
            }
            .navigationDestination(item: $movieToRank) { movie in
                RankingView(movie: movie)
            }
        }
    }

    func loadMovies() async {
        isLoading = true
        errorMessage = nil

        do {
            // Use search API if there's a search query, otherwise use discover API with genre filter
            if debouncedSearchQuery.isEmpty {
                movies = try await MovieInfo.fetchMovies(mode: selectedMode, genres: selectedGenres)
            } else {
                movies = try await MovieInfo.searchMovies(query: debouncedSearchQuery)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private var genrePickerLabel: String {
        if selectedGenres.isEmpty {
            return "Filter by Genre"
        } else if selectedGenres.count == 1 {
            return "Genre: \(selectedGenres.first!.displayName)"
        } else {
            return "Genres: \(selectedGenres.count) selected"
        }
    }

    private func toggleGenre(_ genre: MovieGenre) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
    }
}

// MARK: - FlowLayout for wrapping genre chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    TopMoviesView(
        previewMovies: [
            ]
    )
}
