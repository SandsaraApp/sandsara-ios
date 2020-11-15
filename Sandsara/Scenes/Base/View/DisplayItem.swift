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

    init(track: Track, isPlaylist: Bool = false) {
        self.title = track.title
        self.author = track.author
        self.thumbnail = track.thumbnail
        self.id = track.id
        self.isPlaylist = isPlaylist
    }

    init(playlist: Playlist, isPlaylist: Bool = true) {
        self.title = playlist.title
        self.author = playlist.author
        self.thumbnail = playlist.thumbnail
        self.id = playlist.id
        self.isPlaylist = isPlaylist
    }

    init(track: LocalTrack, isPlaylist: Bool = false) {
        self.title = track.title
        self.author = track.author
        self.thumbnail = track.thumbnail
        self.id = track.id
        self.isPlaylist = isPlaylist
    }

    init(playlist: LocalPlaylist, isPlaylist: Bool = true) {
        self.title = playlist.playlistName
        self.author = playlist.author
        self.thumbnail = playlist.thumbnail
        self.id = playlist.tracks.first?.id ?? 0
        self.isPlaylist = isPlaylist
    }
}

