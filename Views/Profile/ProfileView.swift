//
//  ProfileView.swift
//  Moovie
//
//  Created by Claude Code on 4/9/26.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \UserMovieRanking.finalScore, order: .reverse) private var rankings: [UserMovieRanking]

    @State private var showingEditSheet = false
    @State private var showingSettingsSheet = false
    @State private var isSyncing = false
    @State private var syncError: String?

    private var currentProfile: UserProfile? {
        profiles.first
    }

    private var isSignedIn: Bool {
        currentProfile?.appleUserID != nil
    }

    var body: some View {
        ScrollView {
            if isSignedIn, let profile = currentProfile {
                signedInView(profile: profile)
            } else {
                signInView()
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            if isSignedIn {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }

                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }

                        Button {
                            Task { await syncToSupabase() }
                        } label: {
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Divider()

                        Button(role: .destructive) {
                            signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let profile = currentProfile {
                EditProfileView(profile: profile)
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            if let profile = currentProfile {
                SettingsView(profile: profile)
            }
        }
        .overlay {
            if isSyncing {
                ProgressView("Syncing...")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Sign In View

    private func signInView() -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("Welcome to Moovie")
                .font(.title)
                .fontWeight(.bold)

            Text("Sign in to sync your rankings and connect with friends")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    handleSignInWithApple(result: result)
                }
            )
            .frame(height: 50)
            .padding(.horizontal, 40)
            .signInWithAppleButtonStyle(.black)

            if let error = syncError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Signed In View

    private func signedInView(profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text(profile.username)
                    .font(.title2)
                    .fontWeight(.bold)

                if !profile.bio.isEmpty {
                    Text(profile.bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .padding(.top)

            // Stats
            HStack(spacing: 40) {
                StatCard(title: "Movies Rated", value: "\(rankings.count)")
                StatCard(title: "Member Since", value: formatDate(profile.dateJoined))
            }
            .padding(.horizontal)

            if let favorite = rankings.first {
                Divider()
                    .padding(.horizontal)

                // Favorite Movie Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Favorite Movie")
                        .font(.headline)
                        .padding(.horizontal)

                    NavigationLink(destination: DetailedMovieView(movie: createMovieInfo(from: favorite))) {
                        FavoriteMovieRow(ranking: favorite)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Divider()
                    .padding(.horizontal)
            }

            // Top Movies by Genre
            if !rankings.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Movies by Genre")
                        .font(.headline)
                        .padding(.horizontal)

                    InfiniteGenreScroll(rankings: rankings)
                }
            }

            Spacer(minLength: 40)
        }
    }

    // MARK: - Authentication

    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                syncError = "Failed to get Apple ID credentials"
                return
            }

            let appleUserID = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName

            // Get username from name or use default
            var username = "User"
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                username = "\(givenName) \(familyName)"
            } else if let givenName = fullName?.givenName {
                username = givenName
            }

            // Create or update local profile
            if let existingProfile = currentProfile {
                existingProfile.appleUserID = appleUserID
                existingProfile.email = email
                if existingProfile.username == "User" {
                    existingProfile.username = username
                }
            } else {
                let newProfile = UserProfile(
                    username: username,
                    appleUserID: appleUserID,
                    email: email
                )
                modelContext.insert(newProfile)
            }

            try? modelContext.save()

            // Sync to Supabase
            Task {
                await syncToSupabase()
            }

        case .failure(let error):
            syncError = "Sign in failed: \(error.localizedDescription)"
        }
    }

    private func signOut() {
        guard let profile = currentProfile else { return }
        profile.appleUserID = nil
        try? modelContext.save()
    }

    // MARK: - Supabase Sync

    private func syncToSupabase() async {
        guard let profile = currentProfile, let appleUserID = profile.appleUserID else {
            return
        }

        isSyncing = true
        syncError = nil

        do {
            // Sync profile to Supabase via Auth sign in
            _ = try await SupabaseManager.shared.signInWithApple(
                appleUserID: appleUserID,
                email: profile.email,
                fullName: profile.username
            )

            // Sync all rankings
            for ranking in rankings {
                let rankingDTO = MovieRankingDTO(
                    id: ranking.id,
                    userId: profile.id,
                    movieId: ranking.movieId,
                    movieTitle: ranking.movieTitle,
                    posterPath: ranking.posterPath,
                    releaseDate: ranking.releaseDate,
                    finalScore: ranking.finalScore,
                    enjoyment: ranking.enjoyment,
                    story: ranking.story,
                    acting: ranking.acting,
                    soundtrack: ranking.soundtrack,
                    rewatchability: ranking.rewatchability,
                    genreScores: ranking.genreScores,
                    dateRanked: ranking.dateRanked,
                    lastUpdated: ranking.lastModified
                )

                try await SupabaseManager.shared.upsertRanking(rankingDTO)
            }

            await MainActor.run {
                isSyncing = false
            }

        } catch {
            await MainActor.run {
                syncError = "Sync failed: \(error.localizedDescription)"
                isSyncing = false
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
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

// MARK: - Components

struct InfiniteGenreScroll: View {
    let rankings: [UserMovieRanking]

    @State private var currentIndex: Int = 1 // Start at middle set

    private let genres: [(title: String, key: String)] = [
        ("Horror 💀", "scariness"),
        ("Comedy 🤣", "funniness"),
        ("Action 💥", "actionIntensity"),
        ("Sci-Fi 🌌", "mindBending"),
        ("Drama 💔", "emotionalDepth"),
        ("Romance 💖", "romanceLevel"),
        ("Thriller 😱", "suspense")
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 32) {
                        // Render 3 sets for infinite loop
                        ForEach(0..<3) { setIndex in
                            ForEach(genres.indices, id: \.self) { genreIndex in
                                GenreColumn(
                                    title: genres[genreIndex].title,
                                    rankings: rankings,
                                    genreKey: genres[genreIndex].key
                                )
                                .id("\(setIndex)-\(genreIndex)")
                            }
                        }
                    }
                    .padding(.horizontal)
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: contentGeometry.frame(in: .named("scroll")).minX
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    handleScrollOffset(offset, proxy: proxy, viewWidth: geometry.size.width)
                }
                .onAppear {
                    // Scroll to middle set on appear
                    proxy.scrollTo("1-0", anchor: .leading)
                }
            }
        }
        .frame(height: 680) // Approximate height for 5 posters + spacing
    }

    private func handleScrollOffset(_ offset: CGFloat, proxy: ScrollViewProxy, viewWidth: CGFloat) {
        let genreWidth: CGFloat = 120 + 32 // poster width + spacing
        let setWidth = genreWidth * CGFloat(genres.count)

        // Check if scrolled too far left (into first set)
        if offset > -setWidth * 0.5 {
            // Jump to equivalent position in middle set
            proxy.scrollTo("1-0", anchor: .leading)
        }
        // Check if scrolled too far right (into third set)
        else if offset < -(setWidth * 2.5) {
            // Jump to equivalent position in middle set
            proxy.scrollTo("1-0", anchor: .leading)
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FavoriteMovieRow: View {
    let ranking: UserMovieRanking

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w185\(ranking.posterPath ?? "")")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 90)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                Text(ranking.movieTitle)
                    .font(.headline)
                    .lineLimit(2)

                Text(ranking.releaseDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(String(format: "%.1f", Double(ranking.finalScore) / 1000))/10")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct GenreColumn: View {
    let title: String
    let rankings: [UserMovieRanking]
    let genreKey: String

    private var topMovies: [UserMovieRanking] {
        rankings
            .filter { $0.genreScores[genreKey] != nil }
            .sorted { ($0.genreScores[genreKey] ?? 0) > ($1.genreScores[genreKey] ?? 0) }
            .prefix(5) // Show top 5 movies for this genre
            .map { $0 }
    }

    var body: some View {
        if !topMovies.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(spacing: 12) {
                    ForEach(topMovies, id: \.id) { movie in
                        NavigationLink(destination: DetailedMovieView(movie: createMovieInfo(from: movie))) {
                            GenreMoviePoster(ranking: movie)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
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

struct GenreMoviePoster: View {
    let ranking: UserMovieRanking

    var body: some View {
        AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w185\(ranking.posterPath ?? "")")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    ProgressView()
                )
        }
        .frame(width: 120, height: 180)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile

    @State private var username: String = ""
    @State private var bio: String = ""

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
                        profile.username = username
                        profile.bio = bio
                        dismiss()
                    }
                }
            }
            .onAppear {
                username = profile.username
                bio = profile.bio
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy") {
                    Toggle("Public Profile", isOn: Binding(
                        get: { profile.isPublic },
                        set: { profile.isPublic = $0 }
                    ))

                    Toggle("Share Rankings", isOn: Binding(
                        get: { profile.shareRankings },
                        set: { profile.shareRankings = $0 }
                    ))

                    Toggle("Allow Friend Requests", isOn: Binding(
                        get: { profile.allowFriendRequests },
                        set: { profile.allowFriendRequests = $0 }
                    ))
                }

                Section("Account") {
                    if let email = profile.email {
                        LabeledContent("Email", value: email)
                    }
                    LabeledContent("User ID", value: profile.id.uuidString.prefix(8))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, UserMovieRanking.self, configurations: config)

    // Create preview profile
    let profile = UserProfile(
        username: "Sarah",
        bio: "Movie enthusiast and critic",
        appleUserID: "preview-user-id",
        email: "sarah@example.com"
    )
    container.mainContext.insert(profile)

    // Create preview rankings
    let movies: [(title: String, year: String, score: Int, genreKey: String, genreScore: Int, poster: String)] = [
        ("Parasite", "2019", 9800, "emotionalDepth", 92, "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"),
        ("The Shining", "1980", 9500, "scariness", 98, "/xazWoLealQwEgqZ89MLZklLZD3k.jpg"),
        ("The Grand Budapest Hotel", "2014", 9200, "funniness", 85, "/eWdyYQreja6JGCzqHWXpWHDrrPo.jpg"),
        ("Mad Max: Fury Road", "2015", 9400, "actionIntensity", 99, "/8tZYtuWezp8JbcsvHYO0O46tFbo.jpg"),
        ("Interstellar", "2014", 9600, "mindBending", 96, "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
        ("La La Land", "2016", 8800, "romanceLevel", 85, "/uDO8zWDhfWwoFdKS4fzkUJt0Rf0.jpg"),
        ("Se7en", "1995", 9300, "suspense", 97, "/6yoghtyTpznpBik8EngEmJskVUO.jpg")
    ]

    for movie in movies {
        let ranking = UserMovieRanking(
            movieId: Int.random(in: 1000...9999),
            movieTitle: movie.title,
            posterPath: movie.poster,
            releaseDate: movie.year,
            finalScore: movie.score,
            enjoyment: 90,
            story: 88,
            acting: 85,
            soundtrack: 82,
            rewatchability: 80,
            genreScores: [movie.genreKey: movie.genreScore]
        )
        container.mainContext.insert(ranking)
    }

    return NavigationStack {
        ProfileView()
    }
    .modelContainer(container)
}
