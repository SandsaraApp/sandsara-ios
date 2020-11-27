//
//  SandsaraDataAccess.swift
//  Sandsara
//
//  Created by Tín Phan on 22/11/2020.
//

import RxSwift
import RxCocoa

// MARK: - Data cache from server
class SandsaraDataAccess {
    func getLocalRecommendTracks() -> Observable<[Track]?> {
        return Observable.create { observer -> Disposable in
            observer.onNext(Preferences.PlaylistsDomain.recommendTracks)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func saveRecommendedTracks(tracks: [Track]) -> Observable<Bool> {
        return Observable.create { observer -> Disposable in
            Preferences.PlaylistsDomain.recommendTracks = tracks
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func getLocalAllTracks() -> Observable<[Track]?> {
        return Observable.create { observer -> Disposable in
            observer.onNext(Preferences.PlaylistsDomain.allTracks)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func saveAllTracks(tracks: [Track]) -> Observable<Bool> {
        return Observable.create { observer -> Disposable in
            Preferences.PlaylistsDomain.allTracks = tracks
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func getAllPlaylists() -> Observable<[Playlist]?> {
        return Observable.create { observer -> Disposable in
            observer.onNext(Preferences.PlaylistsDomain.allRemotePlaylists)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func saveAllPlaylists(playlists: [Playlist]) -> Observable<Bool> {
        return Observable.create { observer -> Disposable in
            Preferences.PlaylistsDomain.allRemotePlaylists = playlists
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func getRecommendedPlaylists() -> Observable<[Playlist]?> {
        return Observable.create { observer -> Disposable in
            observer.onNext(Preferences.PlaylistsDomain.recommendedPlaylists)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func saveRecommendedPlaylists(playlists: [Playlist]) -> Observable<Bool> {
        return Observable.create { observer -> Disposable in
            Preferences.PlaylistsDomain.recommendedPlaylists = playlists
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    // TODO: - query by id when have API
    func getPlaylistDetail() -> Observable<[Track]?> {
        return Observable.create { observer -> Disposable in
            observer.onNext(Preferences.PlaylistsDomain.playlistDetail)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    // TODO: - save playlist by id when have API
    func savePlaylistDetail(tracks: [Track]) -> Observable<Bool> {
        return Observable.create { observer -> Disposable in
            Preferences.PlaylistsDomain.playlistDetail = tracks
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}

