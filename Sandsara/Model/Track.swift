//
//  Track.swift
//  Sandsara
//
//  Created by Tín Phan on 14/11/2020.
//

import Foundation
import RealmSwift

class TracksResponse: Decodable {
    let tracks: [Track]
}

class Track: Decodable {
    let title: String
    let author: String
    let thumbnail: String
    let id: Int
}

class LocalTrack: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var author: String = ""
    @objc dynamic var thumbnail: String = ""
    @objc dynamic var id: Int = 0
    @objc dynamic var dateModified: Date = Date()

    required convenience init(track: Track) {
        self.init()
        self.title = track.title
        self.author = track.author
        self.thumbnail = track.thumbnail
        self.id = track.id
        self.dateModified = Date()
    }
}
