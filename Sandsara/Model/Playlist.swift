//
//  Playlist.swift
//  Sandsara
//
//  Created by Tín Phan on 14/11/2020.
//

import RealmSwift

class Playlist: Decodable {
    @objc dynamic var id = 0
    @objc dynamic var title = ""
    @objc dynamic var thumbnail = ""
    @objc dynamic var author = ""

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
}

class LocalPlaylist: Object {
    @objc dynamic var playlistName: String = ""
    @objc dynamic var thumbnail: String = ""
    @objc dynamic var author: String = ""
    let tracks = List<LocalTrack>()
    required convenience init(playlistName: String, thumbnail: String, author: String = "Sandsara") {
        self.init()
        self.playlistName = playlistName
        self.thumbnail = thumbnail
        self.author = author
    }
}

class FavoritePlaylist: Object {
    @objc dynamic var thumbnail: String = ""
    @objc dynamic var author: String = ""
    let tracks = List<LocalTrack>()
    required convenience init(thumbnail: String, author: String = "Sandsara") {
        self.init()
        self.thumbnail = thumbnail
        self.author = author
    }
}
