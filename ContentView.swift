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
                .tabItem { Label("Rankings", systemImage: "person.crop.square") }
            NavigationStack { AddMovieView() }
                .tabItem { Label("Add", systemImage: "plus") }
            NavigationStack { TopMoviesView() }
                .tabItem { Label("Movies", systemImage: "star") }
        }
    }
}

#Preview {
    ContentView()
}
