//
//  DataLayer.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import RealmSwift
import RxSwift


// MARK: - Realm Datalayer
class DataLayer {
    static let shareInstance = DataLayer()
    static let realm = try? Realm()


    private let schemaVersion: UInt64 = 4

    func config() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: schemaVersion,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < self.schemaVersion) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            })

        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
    }

    public static func write(realm: Realm, writeClosure: () -> ()) {
        do {
            try realm.write {
                writeClosure()
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    static func createPlaylist(name: String, thumbnail: String, author: String) -> Bool {
        guard let realm = realm else { return false }
        if realm.objects(LocalPlaylist.self).filter("playlistName == '\(name)'").first != nil {
            return false
        } else {
            let playlist = LocalPlaylist(playlistName: name,
                                         thumbnail: thumbnail,
                                         author: author)
            write(realm: realm, writeClosure: {
                realm.add(playlist)
            })

            return true
        }
    }

    static func addTrackToPlaylist(name: String, track: LocalTrack) -> Bool  {
        if let object = realm?.objects(LocalPlaylist.self).filter("playlistName == '\(name)'").first {
            for savedTrack in object.tracks {
                if savedTrack.trackId == track.trackId {
                    return false
                } else {
                    continue
                }
            }
            write(realm: realm!, writeClosure: {
                object.tracks.append(track)
            })
            return true
        }
        return false
    }

    static func addDuplicateTrackToPlaylist(name: String, track: LocalTrack) -> Bool  {
        if let object = realm?.objects(LocalPlaylist.self).filter("playlistName == '\(name)'").first {
            write(realm: realm!, writeClosure: {
                track.dateModified = Date()
                object.tracks.append(track)
            })
            return true
        }
        return false
    }

    static func addTrackToFavoriteList(_ favoriteTrack: LocalTrack) -> Bool {
        var isExisted: Bool = false
        if let favList = realm?.objects(FavoritePlaylist.self).first {
            for track in favList.tracks {
                if track.trackId == favoriteTrack.trackId && !track.isInvalidated {
                    isExisted = true
                    break
                } else {
                    continue
                }
            }
            if isExisted == false {
                write(realm: realm!, writeClosure: {
                    favList.tracks.append(favoriteTrack)
                })
            }
        } else {
            let list = FavoritePlaylist(thumbnail: favoriteTrack.thumbnail)
            write(realm: realm!, writeClosure: {
                realm?.add(list)
            })
            write(realm: realm!, writeClosure: {
                list.tracks.append(favoriteTrack)
            })
        }

        return isExisted
    }

    static func unLikeTrack(_ trackToDelete: LocalTrack) {
        if let favList = realm?.objects(FavoritePlaylist.self).first {
            var isFound = false
            for i in 0 ..< favList.tracks.count {
                if favList.tracks[i].trackId == trackToDelete.trackId && !favList.tracks[i].isInvalidated {
                    isFound = true
                } else { continue }
            }
            if isFound == true {
                var dbTracks = [LocalTrack]()
                for track in favList.tracks {
                    if !track.isInvalidated && track.trackId != trackToDelete.trackId {
                        dbTracks.append(track)
                    }
                }
                write(realm: realm!, writeClosure: {
                    favList.tracks.removeAll()
                    favList.tracks.append(objectsIn: dbTracks)
                })
            }
        }
    }

    static func loadFavTrack(_ dbTrack: LocalTrack) -> Bool {
        if let list = realm?.objects(FavoritePlaylist.self).first {
            for track in list.tracks {
                if track.trackId == dbTrack.trackId && !track.isInvalidated {
                    return true
                } else{
                    continue
                }
            }
            return false
        }
        return false
    }

    static func loadDownloadedTrack(_ dbTrack: LocalTrack) -> Bool {
        if let list = realm?.objects(DownloadedTracks.self).first {
            for track in list.syncedTracks {
                if track.trackId == dbTrack.trackId && !track.isInvalidated {
                    return true
                } else{
                    continue
                }
            }
            return false
        }
        return false
    }

    static func loadFavList() -> FavoritePlaylist? {
        if let list = realm?.objects(FavoritePlaylist.self).first {
            return list
        }
        return nil
    }

    static func loadFavTracks() -> [LocalTrack] {
        var tracks = [LocalTrack]()
        if let list = realm?.objects(FavoritePlaylist.self).first {
            let sortedTracks = list.tracks.sorted(byKeyPath: "dateModified", ascending: false)
            for track in sortedTracks {
                if !track.isInvalidated {
                    tracks.append(track)
                }
            }
        }
        return tracks
    }

    static func loadPlaylists() -> [LocalPlaylist] {
        var playlists = [LocalPlaylist]()
        let object = realm?.objects(LocalPlaylist.self)
        for playlist in object! {
            playlists.append(playlist)
        }
        return playlists
    }

    static func loadPlaylistTracks(name: String) -> [LocalTrack] {
        var followUsers = [LocalTrack]()
        if let list = realm?.objects(LocalPlaylist.self).filter("playlistName == '\(name)'").first {
            for followUser in list.tracks {
                if !followUser.isInvalidated {
                    followUsers.append(followUser)
                }
            }
        }
        return followUsers
    }

    static func deleteTrackFromPlaylist(_ name: String ,_ trackToDelete: LocalTrack) {
        if let localList = realm?.objects(LocalPlaylist.self).filter("playlistName == '\(name)'").first {
            var isFound = false
            for track in localList.tracks {
                if track.trackId == trackToDelete.trackId && !track.isInvalidated {
                    isFound = true
                }
                else { continue }
            }
            if isFound == true {
                var dbTracks = [LocalTrack]()
                for track in localList.tracks {
                    if !track.isInvalidated && track.trackId != trackToDelete.trackId {
                        dbTracks.append(track)
                    }
                }
                write(realm: realm!, writeClosure: {
                    localList.tracks.removeAll()
                    localList.tracks.append(objectsIn: dbTracks)
                })
            }
        }
    }

    static func deletePlaylist(_ name: String) -> Bool {
        if let object = realm?.objects(LocalPlaylist.self).filter("playlistName == '\(name)'").first {
            write(realm: realm!, writeClosure: {
                object.tracks.removeAll()
                realm?.delete(object)
            })
            return true
        }
        return false
    }

    static func checkTrackIsSynced(_ track: DisplayItem) -> Bool {
        guard DeviceServiceImpl.shared.status.value != .unknown else { return false }
        let localTrack = LocalTrack(track: track)

        guard let realm = realm else { return false }
        if let syncedList = realm.objects(SyncedTracks.self).first {
            for track in syncedList.syncedTracks where localTrack.trackId == track.trackId {
                return true
            }
        }
        return false
    }

    static func addSyncedTrack(_ track: DisplayItem) -> Bool {
        let localTrack = LocalTrack(track: track)
        guard let realm = realm else { return false }

        var isExisted = true
        if let object = realm.objects(SyncedTracks.self).first {
            for syncedTrack in object.syncedTracks {
                if syncedTrack.trackId == localTrack.trackId && !localTrack.isInvalidated {
                    isExisted = true
                    break
                } else {
                    continue
                }
            }
            if isExisted == false {
                write(realm: realm, writeClosure: {
                    object.syncedTracks.append(localTrack)
                })
            }
        } else {
            let list = SyncedTracks()
            write(realm: realm, writeClosure: {
                realm.add(list)
            })
            write(realm: realm, writeClosure: {
                list.syncedTracks.append(localTrack)
            })
        }
        return false
    }

    static func deleteTrackFromSyncedPlaylist(_ trackToDelete: LocalTrack) {
        if let localList = realm?.objects(SyncedTracks.self).first {
            var isFound = false
            for track in localList.syncedTracks where track.trackId == trackToDelete.trackId && !track.isInvalidated {
                isFound = true
            }
            if isFound == true {
                var dbTracks = [LocalTrack]()
                for track in localList.syncedTracks {
                    if !track.isInvalidated && track.trackId != trackToDelete.trackId {
                        dbTracks.append(track)
                    }
                }
                write(realm: realm!, writeClosure: {
                    localList.syncedTracks.removeAll()
                    localList.syncedTracks.append(objectsIn: dbTracks)
                })
            }
        }
    }

    static func addDownloadedTrack(_ track: DisplayItem) -> Bool {
        let localTrack = LocalTrack(track: track)
        guard let realm = realm else { return false }
        var isExisted: Bool = false
        if let object = realm.objects(DownloadedTracks.self).first {
            print("Count \(object.syncedTracks.count)")
            for downloadedTrack in object.syncedTracks {
                if track.trackId == downloadedTrack.trackId && !track.trackId.isEmpty {
                    isExisted = true
                    break
                }
            }

            if !isExisted {
                write(realm: realm, writeClosure: {
                    object.syncedTracks.append(localTrack)
                })
            }

        } else {
            let list = DownloadedTracks()
            write(realm: realm, writeClosure: {
                realm.add(list)
            })
            write(realm: realm, writeClosure: {
                list.syncedTracks.append(localTrack)
            })


        }
        return isExisted
    }

    static func createDownloaedPlaylist(playlist: DisplayItem) -> Bool {
        guard let realm = realm else { return false }
        let playlistToAdd = DownloadedPlaylist(track: playlist)
        let tracks = playlist.tracks.map {
            LocalTrack(track: $0)
        }
        write(realm: realm, writeClosure: {
            realm.add(playlistToAdd)
        })

        write(realm: realm, writeClosure: {
            playlistToAdd.tracks.append(objectsIn: tracks)
        })

        return true
    }

    static func loadDownloadedTracks() -> [LocalTrack] {
        var tracks = [LocalTrack]()
        if let list = realm?.objects(DownloadedTracks.self).first {
            let sortedTracks = list.syncedTracks.sorted(byKeyPath: "dateModified", ascending: false)
            for track in sortedTracks {
                if !track.isInvalidated {
                    tracks.append(track)
                }
            }
        }
        return tracks.unique { $0.trackId }
    }

    static func loadDownloaedPlaylists() -> [DownloadedPlaylist] {
        var playlists = [DownloadedPlaylist]()
        if let list = realm?.objects(DownloadedPlaylist.self) {
            for playlist in list {
                playlists.append(playlist)
            }
        }
        return playlists
    }

    static func loadDownloadedDetailList(name: String) -> [LocalTrack] {
        var tracks = [LocalTrack]()
        if let list = realm?.objects(DownloadedPlaylist.self).filter("playlistName == '\(name)'").first {
            let sortedTracks = list.tracks.sorted(byKeyPath: "dateModified", ascending: false)
            for track in sortedTracks {
                if !track.isInvalidated {
                    tracks.append(track)
                }
            }
        }
        return tracks
    }
}


extension Array {
    func unique<T:Hashable>(map: ((Element) -> (T)))  -> [Element] {
        var set = Set<T>() //the unique list kept in a Set for fast retrieval
        var arrayOrdered = [Element]() //keeping the unique list of elements but ordered
        for value in self {
            if !set.contains(map(value)) {
                set.insert(map(value))
                arrayOrdered.append(value)
            }
        }

        return arrayOrdered
    }
}
