//
//  MovieInfo.swift
//  Moovie
//
//  Created by Alexander McGreevy on 2/27/26.
//

import Foundation

struct MovieInfo: Codable {
    var title: String
    var releaseDate: String
    var ranking: Double
    var description: String?
    var notes: String?
    //later add actors, image, specific rankings
    
    init(title: String = "", releaseDate: String = "", ranking: Double = 0.0, description: String? = nil, notes: String? = nil){
        self.title = title
        self.releaseDate = releaseDate
        self.ranking = ranking
        self.description = description
        self.notes = notes
    }
    
}

extension MovieInfo{
    //add stuff for retreiving info from api
}
