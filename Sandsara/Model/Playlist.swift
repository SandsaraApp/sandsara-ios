//
//  Playlist.swift
//  Sandsara
//
//  Created by Tín Phan on 14/11/2020.
//

import RealmSwift

class PlaylistsResponse: Decodable {
    var playlists: [Playlist] = []

    enum CodingKeys: String, CodingKey {
        case records
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        container.decodeIfPresent([Playlist].self, forKey: .records, assignTo: &playlists)
    }
}

class Playlist: Codable {
    var id = ""
    var title = ""
    var thumbnail: [Thumbnail]?
    var author = ""

    var names = [String]()
    var trackId = [String]()

    var file: File?
    var files: [File]?
    var authors = [String]()

    var tracks = [Track]()
    

    enum CodingKeys: String, CodingKey {
        case fields
        case id
        case title = "name"
        case thumbnails
        case author

        case trackId
        case authors
        case names
        case file
        case files

        case tracks
    }

    init(id: String, title: String, thumbnail: [Thumbnail], author: String) {
        self.id = id
        self.title = title
        self.thumbnail = thumbnail
        self.author = author
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fieldContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .fields)
        fieldContainer.decodeIfPresent(String.self, forKey: .id, assignTo: &id)
        fieldContainer.decodeIfPresent(String.self, forKey: .title, assignTo: &title)
        if let thumbnail = try fieldContainer.decodeIfPresent([Thumbnail].self, forKey: .thumbnails) {
            self.thumbnail = thumbnail
        }
        fieldContainer.decodeIfPresent(String.self, forKey: .author, assignTo: &author)

        fieldContainer.decodeIfPresent([String].self, forKey: .names, assignTo: &names)

        fieldContainer.decodeIfPresent([String].self, forKey: .trackId, assignTo: &trackId)

        fieldContainer.decodeIfPresent([String].self, forKey: .authors, assignTo: &authors)

        if let files = try fieldContainer.decodeIfPresent([File].self, forKey: .files) {
            self.files = files
            for i in 0 ..< files.count {
                if let thumbnail = thumbnail?[i] {
                    print(trackId[i])
                    tracks.append(Track(id: i, title: names[i], trackId: trackId[i] ,thumbnail: [thumbnail], author: authors[i], file: files[i]))
                }
            }
        }

        if let file = try fieldContainer.decodeIfPresent([File].self, forKey: .file)?.first {
            self.file = file
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(thumbnail, forKey: .thumbnails)
        try container.encode(author, forKey: .author)
        try container.encode(file, forKey: .file)
        try container.encode(files, forKey: .files)
        try container.encode(names, forKey: .names)
        try container.encode(authors, forKey: .authors)
        try container.encode(trackId, forKey: .trackId)
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

class SyncedTracks: Object {
    let syncedTracks = List<LocalTrack>()
}

class DownloadedTracks: Object {
    let syncedTracks = List<LocalTrack>()
}

class DownloadedPlaylist: Object {
    @objc dynamic var playlistName: String = ""
    @objc dynamic var thumbnail: String = ""
    @objc dynamic var author: String = ""
    @objc dynamic var fileName: String = ""
    @objc dynamic var fileSize: Int64 = 0
    let tracks = List<LocalTrack>()

    required convenience init(track: DisplayItem) {
        self.init()
        self.playlistName = track.title
        self.author = track.author
        self.thumbnail = track.thumbnail
        self.fileName = track.fileName
        self.fileSize = track.fileSize
    }
}
