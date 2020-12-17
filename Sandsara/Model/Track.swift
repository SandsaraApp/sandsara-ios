//
//  Track.swift
//  Sandsara
//
//  Created by Tín Phan on 14/11/2020.
//

import Foundation
import RealmSwift

class Thumbnail: Codable {
    var url = ""
}

class File: Codable {
    var id = ""
    var url = ""
    var filename = ""
    var size: Int64 = 0
    var type = ""
}

class TracksResponse: Decodable {
    var tracks: [Track] = []

    enum CodingKeys: String, CodingKey {
        case records
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        container.decodeIfPresent([Track].self, forKey: .records, assignTo: &tracks)
    }
}

class Track: Codable {
    var trackId = ""
    var id = 0
    var title = ""
    var thumbnail: [Thumbnail]?
    var author = ""
    var file: File?

    enum CodingKeys: String, CodingKey {
        case fields
        case trackId = "id"
        case id = "trackNumber"
        case title = "name"
        case thumbnail
        case author
        case file
    }

    init(id: Int, title: String, trackId: String ,thumbnail: [Thumbnail]?, author: String, file: File?) {
        self.id = id
        self.title = title
        self.thumbnail = thumbnail
        self.author = author
        self.file = file
        self.trackId = trackId
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        container.decodeIfPresent(String.self, forKey: .trackId, assignTo: &trackId)
        let fieldContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .fields)
        fieldContainer.decodeIfPresent(Int.self, forKey: .id, assignTo: &id)
        fieldContainer.decodeIfPresent(String.self, forKey: .title, assignTo: &title)
        fieldContainer.decodeIfPresent(String.self, forKey: .author, assignTo: &author)

        if let thumbnail = try fieldContainer.decodeIfPresent([Thumbnail].self, forKey: .thumbnail) {
            self.thumbnail = thumbnail
        }

        if let file = try fieldContainer.decodeIfPresent([File].self, forKey: .file)?.first {
            self.file = file
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(trackId, forKey: .trackId)
        try container.encode(title, forKey: .title)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encode(author, forKey: .author)
        try container.encode(file, forKey: .file)
    }
}

class LocalTrack: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var author: String = ""
    @objc dynamic var thumbnail: String = ""
    @objc dynamic var id: Int = 0
    @objc dynamic var dateModified: Date = Date()
    @objc dynamic var fileName: String = ""
    @objc dynamic var fileSize: Int64 = 0
    @objc dynamic var trackId: String = ""


    required convenience init(track: Track) {
        self.init()
        self.title = track.title
        self.author = track.author
        self.thumbnail = track.thumbnail?.first?.url ?? ""
        self.id = track.id
        self.dateModified = Date()
        self.fileName = track.file?.filename ?? ""
        self.fileSize = track.file?.size ?? 0
        self.trackId = track.trackId
    }

    required convenience init(track: DisplayItem) {
        self.init()
        self.title = track.title
        self.author = track.author
        self.thumbnail = track.thumbnail
        self.id = track.id
        self.dateModified = Date()
        self.fileName = track.fileName
        self.trackId = track.trackId
        self.fileSize = track.fileSize
    }
}
