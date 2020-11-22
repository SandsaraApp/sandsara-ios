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

class Track: Codable {
    var id = 0
    var title = ""
    var thumbnail = ""
    var author = ""

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnail
        case author
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        container.decodeIfPresent(Int.self, forKey: .id, assignTo: &id)
        container.decodeIfPresent(String.self, forKey: .title, assignTo: &title)
        container.decodeIfPresent(String.self, forKey: .thumbnail, assignTo: &thumbnail)
        container.decodeIfPresent(String.self, forKey: .author, assignTo: &author)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encode(author, forKey: .author)
    }
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
