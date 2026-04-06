//
//  ProfileView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/6/26.
//

import SwiftUI
import SwiftData
import Kingfisher
import AuthenticationServices

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \UserMovieRanking.finalScore, order: .reverse) private var rankings: [UserMovieRanking]

    @State private var showingEditProfile = false

    private var currentProfile: UserProfile? {
        profiles.first
    }

    private var favoriteMovie: UserMovieRanking? {
        rankings.first
    }

    private var isSignedIn: Bool {
        currentProfile?.appleUserID != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isSignedIn {
                    // Profile Header
                    profileHeader

                    // Stats Section
                    statsSection

                    // Favorite Movie Section (above genre sections)
                    if let favorite = favoriteMovie {
                        VStack(spacing: 8) {
                            Divider()
                            favoritesSection(favorite: favorite)
                            Divider()
                        }
                    }

                    // Top Movies by Genre
                    topMoviesByGenreSection

                    Spacer(minLength: 40)
                } else {
                    // Sign in prompt
                    signInPrompt
                }
            }
            .padding()
        }
        .navigationTitle("Profile")
        .toolbar {
            if isSignedIn {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditProfile = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            signOut()
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(profile: currentProfile)
        }
        .onAppear {
            ensureProfileExists()
        }
    }

    // MARK: - Sign In Prompt

    private var signInPrompt: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue.opacity(0.5))

            VStack(spacing: 16) {
                Text("Welcome to Moovie")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Sign in with Apple to save your rankings and sync across devices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    handleSignInWithApple(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Picture
            if let imageName = currentProfile?.profileImageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    )
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            }

            // Username
            Text(currentProfile?.username ?? "Movie Lover")
                .font(.title)
                .fontWeight(.bold)

            // Bio
            if let bio = currentProfile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 40) {
            StatCard(title: "Movies Rated", value: "\(rankings.count)")
            StatCard(title: "Member Since", value: memberSinceText)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var memberSinceText: String {
        guard let joinDate = currentProfile?.dateJoined else { return "2026" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: joinDate)
    }

    // MARK: - Favorite Movie Section

    private func favoritesSection(favorite: UserMovieRanking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorite Movie")
                .font(.title2)
                .fontWeight(.bold)

            NavigationLink(destination: DetailedMovieView(movie: createMovieInfo(from: favorite))) {
                HStack(spacing: 16) {
                    // Poster
                    if let posterPath = favorite.posterPath, !posterPath.isEmpty {
                        let imageURL = "https://image.tmdb.org/t/p/w185\(posterPath)"
                        KFImage(URL(string: imageURL))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 120)
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(favorite.movieTitle)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundColor(.primary)

                        Text(favorite.releaseDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", Double(favorite.finalScore) / 1000))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Top Movies by Genre

    private var topMoviesByGenreSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Top Movies by Genre")
                .font(.title2)
                .fontWeight(.bold)

            // Horror
            if let topHorror = getTopMovieForGenre("scariness") {
                GenreTopMovieRow(
                    genreTitle: "Horror 💀",
                    movie: topHorror,
                    genreScoreKey: "scariness"
                )
            }

            // Comedy
            if let topComedy = getTopMovieForGenre("funniness") {
                GenreTopMovieRow(
                    genreTitle: "Comedy 🤣",
                    movie: topComedy,
                    genreScoreKey: "funniness"
                )
            }

            // Action
            if let topAction = getTopMovieForGenre("actionIntensity") {
                GenreTopMovieRow(
                    genreTitle: "Action 💥",
                    movie: topAction,
                    genreScoreKey: "actionIntensity"
                )
            }

            // Sci-Fi
            if let topSciFi = getTopMovieForGenre("mindBending") {
                GenreTopMovieRow(
                    genreTitle: "Sci-Fi 🌌",
                    movie: topSciFi,
                    genreScoreKey: "mindBending"
                )
            }

            // Drama
            if let topDrama = getTopMovieForGenre("emotionalDepth") {
                GenreTopMovieRow(
                    genreTitle: "Drama 💔",
                    movie: topDrama,
                    genreScoreKey: "emotionalDepth"
                )
            }

            // Romance
            if let topRomance = getTopMovieForGenre("romanceLevel") {
                GenreTopMovieRow(
                    genreTitle: "Romance 💖",
                    movie: topRomance,
                    genreScoreKey: "romanceLevel"
                )
            }

            // Thriller
            if let topThriller = getTopMovieForGenre("suspense") {
                GenreTopMovieRow(
                    genreTitle: "Thriller 😱",
                    movie: topThriller,
                    genreScoreKey: "suspense"
                )
            }
        }
    }

    // MARK: - Helper Functions

    private func getTopMovieForGenre(_ genreKey: String) -> UserMovieRanking? {
        rankings
            .filter { $0.genreScores[genreKey] != nil }
            .sorted { first, second in
                let firstScore = first.genreScores[genreKey] ?? 0
                let secondScore = second.genreScores[genreKey] ?? 0
                return firstScore > secondScore
            }
            .first
    }

    private func createMovieInfo(from ranking: UserMovieRanking) -> MovieInfo {
        MovieInfo(
            id: ranking.movieId,
            title: ranking.movieTitle,
            releaseDate: ranking.releaseDate,
            description: nil,
            poster_path: ranking.posterPath
        )
    }

    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName

                // Create or update profile
                if let existingProfile = currentProfile {
                    existingProfile.appleUserID = userID
                    if let email = email {
                        existingProfile.email = email
                    }
                    if let givenName = fullName?.givenName {
                        existingProfile.username = givenName
                    }
                } else {
                    let username = fullName?.givenName ?? "Movie Lover"
                    let newProfile = UserProfile(
                        username: username,
                        appleUserID: userID,
                        email: email
                    )
                    modelContext.insert(newProfile)
                }

                try? modelContext.save()
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }

    private func signOut() {
        if let profile = currentProfile {
            profile.appleUserID = nil
            profile.email = nil
            try? modelContext.save()
        }
    }

    private func ensureProfileExists() {
        // Only create a profile if user is not signed in
        // Profile will be created during sign-in flow
        if profiles.isEmpty {
            // Don't auto-create, let user sign in first
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Genre Top Movie Row

struct GenreTopMovieRow: View {
    let genreTitle: String
    let movie: UserMovieRanking
    let genreScoreKey: String

    var genreScore: Int {
        movie.genreScores[genreScoreKey] ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(genreTitle)
                .font(.headline)

            NavigationLink(destination: DetailedMovieView(movie: createMovieInfo(from: movie))) {
                HStack(spacing: 12) {
                    // Poster
                    if let posterPath = movie.posterPath, !posterPath.isEmpty {
                        let imageURL = "https://image.tmdb.org/t/p/w92\(posterPath)"
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
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.movieTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .foregroundColor(.primary)

                        Text(movie.releaseDate)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Text("Score:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(genreScore)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }

    private func createMovieInfo(from ranking: UserMovieRanking) -> MovieInfo {
        MovieInfo(
            id: ranking.movieId,
            title: ranking.movieTitle,
            releaseDate: ranking.releaseDate,
            description: nil,
            poster_path: ranking.posterPath
        )
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let profile: UserProfile?

    @State private var username: String
    @State private var bio: String

    init(profile: UserProfile?) {
        self.profile = profile
        _username = State(initialValue: profile?.username ?? "Movie Lover")
        _bio = State(initialValue: profile?.bio ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Information") {
                    TextField("Username", text: $username)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveProfile() {
        if let existingProfile = profile {
            existingProfile.username = username
            existingProfile.bio = bio
        } else {
            let newProfile = UserProfile(username: username, bio: bio)
            modelContext.insert(newProfile)
        }
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: UserProfile.self, UserMovieRanking.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Create test profile (bypassing Apple sign-in for preview)
    let profile = UserProfile(
        username: "Alex",
        bio: "Passionate movie lover and critic",
        appleUserID: "preview-user-id",
        email: "alex@preview.com"
    )
    container.mainContext.insert(profile)

    // Create diverse test rankings covering all genres

    // Favorite movie (highest score)
    let parasite = UserMovieRanking(
        movieId: 496243,
        movieTitle: "Parasite",
        posterPath: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
        releaseDate: "2019-05-30",
        finalScore: 9800,
        enjoyment: 98,
        story: 100,
        acting: 95,
        soundtrack: 90,
        rewatchability: 92,
        genreScores: ["emotionalDepth": 95, "suspense": 92, "mysteryIntrigue": 88]
    )

    // Horror
    let theShining = UserMovieRanking(
        movieId: 694,
        movieTitle: "The Shining",
        posterPath: "/xazWoLealQwEgqZ89MLZklLZD3k.jpg",
        releaseDate: "1980-05-23",
        finalScore: 9500,
        enjoyment: 90,
        story: 85,
        acting: 95,
        soundtrack: 88,
        rewatchability: 80,
        genreScores: ["scariness": 98, "suspense": 90]
    )

    // Comedy
    let grandBudapest = UserMovieRanking(
        movieId: 120467,
        movieTitle: "The Grand Budapest Hotel",
        posterPath: "/eWdyYQreja6JGCzqHWXpWHDrrPo.jpg",
        releaseDate: "2014-03-07",
        finalScore: 9200,
        enjoyment: 98,
        story: 88,
        acting: 90,
        soundtrack: 92,
        rewatchability: 88,
        genreScores: ["funniness": 85, "visualCreativity": 95]
    )

    // Action
    let madMax = UserMovieRanking(
        movieId: 76341,
        movieTitle: "Mad Max: Fury Road",
        posterPath: "/hA2ple9q4qnwxp3hKVNhroipsir.jpg",
        releaseDate: "2015-05-15",
        finalScore: 9000,
        enjoyment: 95,
        story: 80,
        acting: 88,
        soundtrack: 95,
        rewatchability: 92,
        genreScores: ["actionIntensity": 99, "adventureScale": 95]
    )

    // Sci-Fi
    let interstellar = UserMovieRanking(
        movieId: 157336,
        movieTitle: "Interstellar",
        posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
        releaseDate: "2014-11-05",
        finalScore: 9400,
        enjoyment: 92,
        story: 95,
        acting: 90,
        soundtrack: 100,
        rewatchability: 85,
        genreScores: ["mindBending": 96, "emotionalDepth": 88, "adventureScale": 92]
    )

    // Romance
    let lalaland = UserMovieRanking(
        movieId: 313369,
        movieTitle: "La La Land",
        posterPath: "/uDO8zWDhfWwoFdKS4fzkUJt0Rf0.jpg",
        releaseDate: "2016-12-09",
        finalScore: 8800,
        enjoyment: 90,
        story: 82,
        acting: 88,
        soundtrack: 98,
        rewatchability: 82,
        genreScores: ["romanceLevel": 92, "soundtrackQuality": 98, "emotionalDepth": 85]
    )

    // Thriller
    let seVen = UserMovieRanking(
        movieId: 807,
        movieTitle: "Se7en",
        posterPath: "/6yoghtyTpznpBik8EngEmJskVUO.jpg",
        releaseDate: "1995-09-22",
        finalScore: 9100,
        enjoyment: 88,
        story: 92,
        acting: 95,
        soundtrack: 85,
        rewatchability: 78,
        genreScores: ["suspense": 97, "mysteryIntrigue": 90, "emotionalDepth": 75]
    )

    // Drama
    let shawshank = UserMovieRanking(
        movieId: 278,
        movieTitle: "The Shawshank Redemption",
        posterPath: "/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg",
        releaseDate: "1994-09-23",
        finalScore: 9600,
        enjoyment: 95,
        story: 98,
        acting: 96,
        soundtrack: 88,
        rewatchability: 90,
        genreScores: ["emotionalDepth": 98, "suspense": 75]
    )

    // Additional movies for variety
    let inception = UserMovieRanking(
        movieId: 27205,
        movieTitle: "Inception",
        posterPath: "/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg",
        releaseDate: "2010-07-16",
        finalScore: 9300,
        enjoyment: 95,
        story: 90,
        acting: 88,
        soundtrack: 92,
        rewatchability: 88,
        genreScores: ["mindBending": 95, "actionIntensity": 85, "suspense": 88]
    )

    let pulpFiction = UserMovieRanking(
        movieId: 680,
        movieTitle: "Pulp Fiction",
        posterPath: "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg",
        releaseDate: "1994-09-10",
        finalScore: 9400,
        enjoyment: 94,
        story: 95,
        acting: 92,
        soundtrack: 88,
        rewatchability: 90,
        genreScores: ["funniness": 78, "suspense": 85, "emotionalDepth": 80]
    )

    // Insert all rankings
    container.mainContext.insert(parasite)
    container.mainContext.insert(theShining)
    container.mainContext.insert(grandBudapest)
    container.mainContext.insert(madMax)
    container.mainContext.insert(interstellar)
    container.mainContext.insert(lalaland)
    container.mainContext.insert(seVen)
    container.mainContext.insert(shawshank)
    container.mainContext.insert(inception)
    container.mainContext.insert(pulpFiction)

    return NavigationStack {
        ProfileView()
    }
    .modelContainer(container)
}
