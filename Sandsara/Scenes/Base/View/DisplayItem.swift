//
//  DisplayItem.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import Foundation

struct DisplayItem {
    let title: String
    let author: String
    let thumbnail: String
    let id: Int
    let isPlaylist: Bool
    var isLocal: Bool = false
    var fileName: String = ""
    var fileSize: Int64 = 0
    var isSynced: Bool = false
    var isTestPlaylist: Bool = false

    var fileURL = ""

    var tracks = [Track]()

    var trackId: String = ""

    init() {
        title = ""
        author = ""
        thumbnail = ""
        id = 0
        isPlaylist = false
        isLocal = false
    }

    init(track: Track, isPlaylist: Bool = false) {
        self.title = track.title
        self.author = track.author
        self.thumbnail = track.thumbnail?.first?.url ?? ""
        self.id = track.id
        self.isPlaylist = isPlaylist
        self.fileName = track.file?.first?.filename ?? ""
        self.fileSize = track.file?.first?.size ?? 0
        self.trackId = track.trackId
        self.fileURL = track.file?.first?.url ?? ""
    }

    init(playlist: Playlist, isPlaylist: Bool = true, isTestPlaylist: Bool = false) {
        self.title = playlist.title
        self.author = playlist.author
        self.thumbnail = playlist.thumbnail?.first?.url ?? ""
        self.id = 0
        self.isPlaylist = isPlaylist
        self.isTestPlaylist = isTestPlaylist
        self.tracks = playlist.tracks
        self.isLocal = false
        self.fileName = playlist.file?.first?.filename ?? ""
        self.fileSize = playlist.file?.first?.size ?? 0
        self.fileURL = playlist.file?.first?.url ?? ""
    }

    init(track: LocalTrack, isPlaylist: Bool = false, isLocal: Bool = true) {
        self.title = track.title
        self.author = track.author
        self.thumbnail = track.thumbnail
        self.id = track.id
        self.isPlaylist = isPlaylist
        self.isLocal = isLocal
        self.fileName = track.fileName
        self.fileSize = track.fileSize
        self.trackId = track.trackId
    }

    init(playlist: LocalPlaylist, isPlaylist: Bool = true, isLocal: Bool = true) {
        self.title = playlist.playlistName
        self.author = playlist.author
        self.thumbnail = playlist.thumbnail
        self.id = playlist.tracks.first?.id ?? 0
        self.isPlaylist = isPlaylist
        self.isLocal = isLocal
    }

    init(playlist: FavoritePlaylist, isPlaylist: Bool = true, isLocal: Bool = true) {
        self.title = L10n.favorite
        self.author = playlist.author
        self.thumbnail = playlist.thumbnail
        self.id = playlist.tracks.first?.id ?? 0
        self.isPlaylist = isPlaylist
        self.isLocal = isLocal
    }

    init(playlist: DownloadedPlaylist, isPlaylist: Bool = true, isLocal: Bool = false) {
        self.title = playlist.playlistName
        self.author = playlist.author
        self.thumbnail = playlist.thumbnail
        self.id = playlist.tracks.first?.id ?? 0
        self.isPlaylist = isPlaylist
        self.isLocal = isLocal
        self.isTestPlaylist = true
    }

    init(trackCellViewModel: TrackCellViewModel) {
        self = trackCellViewModel.inputs.track
    }
}

