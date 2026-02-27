//
//  ContentView.swift
//  Moovie
//
//  Created by Alexander McGreevy on 2/27/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Moovie")
            LazyVStack{
                Text("Movies here")
            
            }.border(.black)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
