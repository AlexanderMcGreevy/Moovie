//
//  PersonDetailView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 3/18/26.
//

import SwiftUI
import Kingfisher

struct PersonDetailView: View {
    let personId: Int

    @State private var personDetails: PersonDetails?
    @State private var movieCredits: [PersonMovieCredit] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let errorMessage = errorMessage {
                VStack(spacing: 12) {
                    Text("Could not load person details")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Retry") {
                        Task {
                            await loadPersonData()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let person = personDetails {
                VStack(alignment: .leading, spacing: 16) {
                    // Profile Image and Basic Info
                    HStack(alignment: .top, spacing: 16) {
                        if let profilePath = person.profilePath, !profilePath.isEmpty {
                            let imageURL = "https://image.tmdb.org/t/p/w500\(profilePath)"
                            KFImage(URL(string: imageURL))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120)
                                .cornerRadius(8)
                                .shadow(radius: 4)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(person.name)
                                .font(.title)
                                .fontWeight(.bold)

                            if let knownFor = person.knownForDepartment {
                                Text(knownFor)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if let birthday = person.birthday {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(birthday)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            if let placeOfBirth = person.placeOfBirth {
                                HStack(spacing: 4) {
                                    Image(systemName: "location")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(placeOfBirth)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()

                    // Biography
                    if let biography = person.biography, !biography.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Biography")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text(biography)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                    }

                    // Movie Credits
                    if !movieCredits.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Movie Credits")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 100), spacing: 12)
                            ], spacing: 12) {
                                ForEach(movieCredits) { credit in
                                    NavigationLink(destination: DetailedMovieView(movie: MovieInfo(
                                        id: credit.id,
                                        title: credit.title,
                                        releaseDate: credit.releaseDate ?? "",
                                        ranking: credit.voteAverage,
                                        description: nil,
                                        poster_path: credit.posterPath
                                    ))) {
                                        VStack(alignment: .center, spacing: 4) {
                                            if let posterPath = credit.posterPath, !posterPath.isEmpty {
                                                let imageURL = "https://image.tmdb.org/t/p/w500\(posterPath)"
                                                KFImage(URL(string: imageURL))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 100)
                                                    .cornerRadius(8)
                                            } else {
                                                Rectangle()
                                                    .fill(Color(.systemGray5))
                                                    .frame(width: 100, height: 150)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        Text("No Image")
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                    )
                                            }

                                            Text(credit.title)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                                .frame(width: 100)

                                            if let character = credit.character {
                                                Text(character)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                                    .frame(width: 100)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle("Person Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPersonData()
        }
    }

    func loadPersonData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let details = MovieInfo.fetchPersonDetails(personId: personId)
            async let credits = MovieInfo.fetchPersonMovieCredits(personId: personId)

            personDetails = try await details
            movieCredits = try await credits
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PersonDetailView(personId: 1136406)
    }
}
