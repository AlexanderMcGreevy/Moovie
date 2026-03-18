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

    
    var body: some View {
        VStack{
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

#Preview {
    DetailedMovieView(movie: MovieInfo(id: 1, title: "Example Movie", releaseDate: "2024-01-01", ranking: 8.5, description: "This is an example movie description.", poster_path: "/example.jpg"))
}

