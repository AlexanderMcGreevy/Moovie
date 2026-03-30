//
//  ContentView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 2/27/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack { MyRankingView() }
                .tabItem { Label("Rankings", systemImage: "popcorn.fill") }
            NavigationStack { AddMovieView() }
                .tabItem { Label("Add", systemImage: "plus") }
            NavigationStack { TopMoviesView() }
                .tabItem { Label("Movies", systemImage: "star") }
            NavigationStack { FriendsView() }
                .tabItem { Label("Friends", systemImage: "person.3.fill") }
        }
    }
}

#Preview {
    ContentView()
}
