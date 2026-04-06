//
//  MoovieApp.swift
//  Moovie
//
//  Created by Alexander McGreevy on 2/27/26.
//

import SwiftUI
import SwiftData

@main
struct MoovieApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserMovieRanking.self, UserProfile.self])
    }
}
