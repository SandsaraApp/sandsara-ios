//
//  DataLayer.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import RealmSwift
import RxRealm
import RxSwift

// MARK: - Realm Datalayer
class DataLayer {
    static let shareInstance = DataLayer()
    static let realm = try? Realm()

    func config() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
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
                if savedTrack.id == track.id {
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

    static func addTrackToFavoriteList(_ favoriteTrack: LocalTrack) {
        var isExisted: Bool = false
        if let favList = realm?.objects(FavoritePlaylist.self).first {
            for track in favList.tracks {
                if track.id == favoriteTrack.id && !track.isInvalidated{
                    isExisted = true
                    return
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
    }

    static func unLikeTrack(_ trackToDelete: LocalTrack) {
        if let favList = realm?.objects(FavoritePlaylist.self).first {
            // debugPrint(trackToDelete.createdDate)
            var isFound = false
            for i in 0 ..< favList.tracks.count {
                if favList.tracks[i].id == trackToDelete.id && !favList.tracks[i].isInvalidated {
                    isFound = true
                } else { continue }
            }
            if isFound == true {
                var dbTracks = [LocalTrack]()
                for track in favList.tracks {
                    if !track.isInvalidated && track.id != trackToDelete.id {
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
                if track.id == dbTrack.id && !track.isInvalidated {
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
}
