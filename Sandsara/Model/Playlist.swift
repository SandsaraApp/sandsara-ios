//
//  Playlist.swift
//  Sandsara
//
//  Created by Tín Phan on 14/11/2020.
//

import RealmSwift

class PlaylistsResponse: Decodable {
    let playlists: [Playlist]
}

class Playlist: Codable {
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

    required convenience init(track: DisplayItem) {
        self.init()
        self.playlistName = track.title
        self.author = track.author
        self.thumbnail = track.thumbnail
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
