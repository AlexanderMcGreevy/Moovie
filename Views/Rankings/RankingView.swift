//
//  RankingView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/2/26.
//

import SwiftUI
import SwiftData
import Kingfisher

struct RankingView: View {
    let movie: MovieInfo
    let existingRanking: UserMovieRanking? // For re-ranking

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var rankingsManager: RankingsManager
    @Query private var profiles: [UserProfile]

    private var currentProfile: UserProfile? {
        profiles.first
    }

    private var syncManager: SyncManager {
        SyncManager.shared
    }

    // Ranking flow states
    @State private var currentStep: RankingStep = .universal
    @State private var sliderValues: SliderValues
    @State private var genreQuestions: [SliderQuestion] = []

    // Comparative state
    @State private var comparativeQuestions: [ComparativeQuestion] = []
    @State private var currentComparativeIndex = 0
    @State private var comparativeResults: [ComparativeResult] = []

    // Final state
    @State private var finalRanking: UserMovieRanking?
    @State private var rankPosition: Int?

    // Error handling
    @State private var errorMessage: String?
    @State private var showError = false

    init(movie: MovieInfo, existingRanking: UserMovieRanking? = nil) {
        self.movie = movie
        self.existingRanking = existingRanking

        // Initialize slider values from existing ranking or defaults
        let initialValues = existingRanking.map { ranking in
            SliderValues(
                enjoyment: ranking.enjoyment,
                story: ranking.story,
                acting: ranking.acting,
                soundtrack: ranking.soundtrack,
                rewatchability: ranking.rewatchability,
                genreScores: ranking.genreScores
            )
        } ?? SliderValues()

        self._sliderValues = State(initialValue: initialValues)
        self._rankingsManager = State(initialValue: RankingsManager())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Movie Info Card (always shown)
                movieInfoCard

                // Progress Indicator
                progressIndicator

                // Content based on current step
                switch currentStep {
                case .universal:
                    universalSlidersView
                case .genre:
                    genreSlidersView
                case .comparative:
                    comparativeQuestionsView
                case .confirmation:
                    confirmationView
                }
            }
            .padding()
        }
        .navigationTitle(existingRanking == nil ? "Rank Movie" : "Edit Ranking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            rankingsManager.modelContext = modelContext
            setupGenreQuestions()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Movie Info Card

    private var movieInfoCard: some View {
        VStack(spacing: 16) {
            if let posterPath = movie.poster_path, !posterPath.isEmpty {
                let imageURL = "https://image.tmdb.org/t/p/w500\(posterPath)"
                KFImage(URL(string: imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 120)
                    .cornerRadius(12)
                    .shadow(radius: 8)
            }

            VStack(spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(movie.releaseDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStepIndex ? Color.blue : Color(.systemGray4))
                    .frame(width: 10, height: 10)
            }
        }
    }

    private var totalSteps: Int {
        var steps = 1 // Universal
        if !genreQuestions.isEmpty {
            steps += 1 // Genre
        }
        if existingRanking == nil { // Only show comparatives for new rankings
            steps += 1 // Comparative
        }
        steps += 1 // Confirmation
        return steps
    }

    private var currentStepIndex: Int {
        switch currentStep {
        case .universal: return 0
        case .genre: return 1
        case .comparative: return genreQuestions.isEmpty ? 1 : 2
        case .confirmation: return totalSteps - 1
        }
    }

    // MARK: - Universal Sliders View

    private var universalSlidersView: some View {
        VStack(spacing: 16) {
            Text("Rate These Aspects")
                .font(.title3)
                .fontWeight(.semibold)

            EmojiSlider(question: .enjoyment, value: $sliderValues.enjoyment)
            EmojiSlider(question: .story, value: $sliderValues.story)
            EmojiSlider(question: .acting, value: $sliderValues.acting)
            EmojiSlider(question: .soundtrack, value: $sliderValues.soundtrack)
            EmojiSlider(question: .rewatchability, value: $sliderValues.rewatchability)

            Button(action: proceedFromUniversal) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Genre Sliders View

    private var genreSlidersView: some View {
        VStack(spacing: 16) {
            Text("Genre-Specific Questions")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Since this movie is: \(genreNames)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ForEach(genreQuestions) { question in
                EmojiSlider(
                    question: question,
                    value: binding(for: question.id)
                )
            }

            Button(action: proceedFromGenre) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Comparative Questions View

    private var comparativeQuestionsView: some View {
        VStack(spacing: 24) {
            if currentComparativeIndex < comparativeQuestions.count {
                let question = comparativeQuestions[currentComparativeIndex]

                Text("Almost There!")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Did you enjoy \"\(movie.title)\" more than...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Compared movie card
                VStack(spacing: 12) {
                    if let posterPath = question.comparedMovie.posterPath, !posterPath.isEmpty {
                        let imageURL = "https://image.tmdb.org/t/p/w500\(posterPath)"
                        KFImage(URL(string: imageURL))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                            .cornerRadius(8)
                    }

                    Text(question.comparedMovie.movieTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("Your rating: \(question.comparedMovie.finalScore)/10000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Choice buttons
                VStack(spacing: 12) {
                    Button(action: { answerComparative(.better) }) {
                        HStack {
                            Text("👍")
                                .font(.title2)
                            Text("Yes, better")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                    }

                    Button(action: { answerComparative(.same) }) {
                        HStack {
                            Text("🤷")
                                .font(.title2)
                            Text("About the same")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                    }

                    Button(action: { answerComparative(.worse) }) {
                        HStack {
                            Text("👎")
                                .font(.title2)
                            Text("No, worse")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            } else {
                ProgressView("Calculating final ranking...")
            }
        }
    }

    // MARK: - Confirmation View

    private var confirmationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text(existingRanking == nil ? "Ranked Successfully!" : "Ranking Updated!")
                .font(.title2)
                .fontWeight(.bold)

            if let posterPath = movie.poster_path, !posterPath.isEmpty {
                let imageURL = "https://image.tmdb.org/t/p/w500\(posterPath)"
                KFImage(URL(string: imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 120)
                    .cornerRadius(12)
            }

            Text("\"\(movie.title)\"")
                .font(.headline)
                .multilineTextAlignment(.center)

            if let position = rankPosition {
                Text("is now #\(position) in your rankings!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("View All Rankings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func setupGenreQuestions() {
        if let genreIds = movie.genreIds {
            genreQuestions = SliderQuestion.getGenreQuestions(for: genreIds)

            // Initialize genre score values if needed
            for question in genreQuestions {
                if sliderValues.genreScores[question.id] == nil {
                    sliderValues.genreScores[question.id] = 50
                }
            }
        }
    }

    private var genreNames: String {
        guard let genreIds = movie.genreIds else { return "" }
        return genreIds.compactMap { MovieGenre(rawValue: $0)?.displayName }.joined(separator: ", ")
    }

    private func binding(for questionId: String) -> Binding<Int> {
        Binding(
            get: { sliderValues.genreScores[questionId] ?? 50 },
            set: { sliderValues.genreScores[questionId] = $0 }
        )
    }

    private func proceedFromUniversal() {
        if genreQuestions.isEmpty {
            // Skip to comparative or confirmation
            if existingRanking == nil {
                prepareComparativeQuestions()
            } else {
                saveRanking()
            }
        } else {
            currentStep = .genre
        }
    }

    private func proceedFromGenre() {
        if existingRanking == nil {
            prepareComparativeQuestions()
        } else {
            saveRanking()
        }
    }

    private func prepareComparativeQuestions() {
        let initialScore = rankingsManager.calculateInitialScore(sliderValues: sliderValues)
        let (above, below) = rankingsManager.findNearestNeighbors(score: initialScore)

        var questions: [ComparativeQuestion] = []

        if let below = below {
            questions.append(ComparativeQuestion(comparedMovie: below))
        }
        if let above = above {
            questions.append(ComparativeQuestion(comparedMovie: above))
        }

        comparativeQuestions = questions

        if questions.isEmpty {
            // No other movies ranked yet
            saveRanking()
        } else {
            currentStep = .comparative
        }
    }

    private func answerComparative(_ choice: ComparisonChoice) {
        let question = comparativeQuestions[currentComparativeIndex]

        let result = ComparativeResult(
            comparedToMovieId: question.comparedMovie.movieId,
            comparedToMovieTitle: question.comparedMovie.movieTitle,
            choice: choice,
            timestamp: Date()
        )

        comparativeResults.append(result)

        // Check if we need more questions based on the answer
        if choice == .same {
            // Ask tie-breaker
            // For simplicity, we'll just add +1 to place it above
            saveRanking()
        } else {
            // Check if settled
            let settled = checkIfSettled(lastChoice: choice, lastCompared: question.comparedMovie)
            if settled {
                saveRanking()
            } else {
                currentComparativeIndex += 1
                if currentComparativeIndex >= comparativeQuestions.count {
                    saveRanking()
                }
            }
        }
    }

    private func checkIfSettled(lastChoice: ComparisonChoice, lastCompared: UserMovieRanking) -> Bool {
        // Simplified logic: if we've answered questions for both neighbors, we're settled
        return comparativeResults.count >= 2 || comparativeQuestions.count == 1
    }

    private func saveRanking() {
        print("🎬 Attempting to save ranking for: \(movie.title)")
        print("📊 Slider values - Enjoyment: \(sliderValues.enjoyment), Story: \(sliderValues.story)")

        do {
            if let existing = existingRanking {
                // Update existing ranking
                print("✏️ Updating existing ranking")
                try rankingsManager.updateRanking(
                    rankingId: existing.id,
                    sliderValues: sliderValues,
                    comparisons: comparativeResults
                )
            } else {
                // Add new ranking
                print("➕ Adding new ranking")
                try rankingsManager.addRanking(
                    movie: movie,
                    sliderValues: sliderValues,
                    comparisons: comparativeResults
                )
            }

            // Calculate rank position
            let allRankings = try rankingsManager.fetchAllRankings()
            print("📋 Total rankings after save: \(allRankings.count)")

            if let movieRanking = allRankings.first(where: { $0.movieId == movie.id }) {
                rankPosition = allRankings.firstIndex(where: { $0.id == movieRanking.id }).map { $0 + 1 }
                finalRanking = movieRanking
                print("✅ Ranking saved successfully! Position: #\(rankPosition ?? 0)")

                // Sync to Supabase
                if let profile = currentProfile, profile.appleUserID != nil {
                    Task {
                        do {
                            try await syncManager.syncRanking(movieRanking, userId: profile.id)
                            print("☁️ Ranking synced to Supabase")
                        } catch {
                            print("⚠️ Failed to sync ranking to Supabase: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                print("⚠️ Warning: Ranking saved but couldn't find it in the list")
            }

            currentStep = .confirmation
        } catch {
            print("❌ Error saving ranking: \(error.localizedDescription)")
            errorMessage = "Failed to save ranking: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Supporting Types

enum RankingStep {
    case universal
    case genre
    case comparative
    case confirmation
}

struct ComparativeQuestion: Identifiable {
    let id = UUID()
    let comparedMovie: UserMovieRanking
}

#Preview {
    NavigationStack {
        RankingView(movie: MovieInfo(
            id: 1,
            title: "Inception",
            releaseDate: "2010-07-16",
            description: "A thief who steals corporate secrets through the use of dream-sharing technology.",
            poster_path: "/example.jpg",
            genreIds: [28, 878, 53]
        ))
    }
    .modelContainer(for: UserMovieRanking.self, inMemory: true)
}
