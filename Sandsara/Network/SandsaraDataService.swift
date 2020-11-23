//
//  SandsaraDataService.swift
//  Sandsara
//
//  Created by Tín Phan on 22/11/2020.
//

import Moya
import RxSwift
import RxCocoa

let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)

class SandsaraDataServices {
    private var recommendTracks: [Track]?
    private var recommendPlaylists: [Playlist]?
    private var allTracks: [Track]?
    private var allPlaylist: [Playlist]?
    private var playlistDetail: [Track]?

    private let api: SandsaraAPIService
    private let dataAccess: SandsaraDataAccess

    private let disposeBag = DisposeBag()

    init(api: SandsaraAPIService = SandsaraAPIService(apiProvider: MoyaProvider<SandsaraAPI>()),
         dataAccess: SandsaraDataAccess = SandsaraDataAccess()) {
        self.api = api
        self.dataAccess = dataAccess
    }

    func getServicesOption(for apiType: SandsaraAPI) -> ServiceOption {
        switch apiType {
        case .recommendedtracks:
            if let tracks = recommendTracks {
                return .both
            }
            return .server
        case .alltrack:
            if let tracks = allTracks {
                return .both
            }
            return .server
        case .recommendedplaylist:
            if let tracks = recommendPlaylists {
                return .both
            }
            return .server
        case .playlists:
            if let tracks = allPlaylist {
                return .both
            }
            return .server
        case .playlistDetail:
            if let tracks = playlistDetail {
                return .both
            }
            return .server
        }
    }

    private func getRecommendedTracksFromServer() -> Observable<[Track]> {
        return api
            .getRecommendTracks()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.recommendTracks = tracks
            })
            .asObservable()
            .flatMap { [weak self] result -> Observable<([Track], Bool)> in
                guard let self = self else { return Observable.just((result, false)) }
                return Observable.combineLatest(Observable.just(result), self.dataAccess.saveRecommendedTracks(tracks: result)) { ($0, $1) }
            }
            .map { (cards, _) -> [Track] in
                return cards
            }
    }

    func getRecommendTracks(option: ServiceOption) -> Observable<[Track]> {
        let serverObservable = getRecommendedTracksFromServer()

        let localObservable = dataAccess
            .getLocalRecommendTracks()
            .compactMap { $0 }
            .doOnNext({ [weak self] cache in
                guard let self = self else { return }
                self.recommendTracks = cache
            })

        switch option {
        case .server:
            return serverObservable
              //  .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if let cardList = self.recommendTracks {
                return Observable.of(cardList)
            } else {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        default:
            if let cardList = self.recommendTracks {
                return Observable.concat(Observable.of(cardList), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            } else {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        }
    }

    private func getAllTracksFromServer() -> Observable<[Track]> {
        return api
            .getAllTracks()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.allTracks = tracks
            })
            .asObservable()
            .flatMap { [weak self] result -> Observable<([Track], Bool)> in
                guard let self = self else { return Observable.just((result, false)) }
                return Observable.combineLatest(Observable.just(result), self.dataAccess.saveAllTracks(tracks: result)) { ($0, $1) }
            }
            .map { (cards, _) -> [Track] in
                return cards
            }
    }

    func getAllTracks(option: ServiceOption) -> Observable<[Track]> {
        let serverObservable = getAllTracksFromServer()
        let localObservable = dataAccess
            .getLocalAllTracks()
            .compactMap { $0 }
            .doOnNext({ [weak self] cache in
                guard let self = self else { return }
                self.allTracks = cache
            })

        switch option {
        case .server:
            return serverObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if let cardList = self.allTracks {
                return Observable.of(cardList)
            } else {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        default:
            if let cardList = self.allTracks {
                return Observable.concat(Observable.of(cardList), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            } else {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        }
    }

    private func getPlaylistDetailFromServer() -> Observable<[Track]> {
        return api
            .playlistDetail()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.playlistDetail = tracks
            })
            .asObservable()
            .flatMap { [weak self] result -> Observable<([Track], Bool)> in
                guard let self = self else { return Observable.just((result, false)) }
                return Observable.combineLatest(Observable.just(result), self.dataAccess.savePlaylistDetail(tracks: result)) { ($0, $1) }
            }
            .map { (cards, _) -> [Track] in
                return cards
            }
    }

    func getPlaylistDetail(option: ServiceOption) -> Observable<[Track]> {
        // avoid duplicate playlist detail cache
        let serverObservable = getPlaylistDetailFromServer()
        let localObservable = dataAccess
            .getLocalAllTracks()
            .compactMap { $0 }
            .doOnNext({ [weak self] cache in
                guard let self = self else { return }
                self.playlistDetail = cache
            })

        switch option {
        case .server:
            return serverObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if let cardList = self.playlistDetail {
                return Observable.of(cardList)
            } else {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        default:
            if let cardList = self.playlistDetail {
                return Observable.concat(Observable.of(cardList), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            } else {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        }
    }

    private func getAllPlaylistFromServer() -> Observable<[Playlist]> {
        return api
            .playlists()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.allPlaylist = tracks
            })
            .asObservable()
            .flatMap { [weak self] result -> Observable<([Playlist], Bool)> in
                guard let self = self else { return Observable.just((result, false)) }
                return Observable.combineLatest(Observable.just(result), self.dataAccess.saveAllPlaylists(playlists: result)) { ($0, $1) }
            }
            .map { (cards, _) -> [Playlist] in
                return cards
            }
    }

    func getAllPlaylist(option: ServiceOption) -> Observable<[Playlist]> {
        let serverObservable = getAllPlaylistFromServer()
        let localObservable = dataAccess
            .getAllPlaylists()
            .compactMap { $0 }
            .doOnNext({ [weak self] cache in
                guard let self = self else { return }
                self.allPlaylist = cache
            })

        switch option {
        case .server:
            return serverObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if let cardList = self.allPlaylist {
                return Observable.of(cardList)
            } else {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        default:
            if let cardList = self.allPlaylist {
                return Observable.concat(Observable.of(cardList), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            } else {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        }
    }

    private func getRecommendedPlaylistsFromServer() -> Observable<[Playlist]> {
        return api
            .getRecommendPlaylist()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.recommendPlaylists = tracks
            })
            .asObservable()
            .flatMap { [weak self] result -> Observable<([Playlist], Bool)> in
                guard let self = self else { return Observable.just((result, false)) }
                return Observable.combineLatest(Observable.just(result), self.dataAccess.saveRecommendedPlaylists(playlists: result)) { ($0, $1) }
            }
            .map { (cards, _) -> [Playlist] in
                return cards
            }
    }

    func getRecommendedPlaylists(option: ServiceOption) -> Observable<[Playlist]> {
        let serverObservable = getRecommendedPlaylistsFromServer()
        let localObservable = dataAccess
            .getRecommendedPlaylists()
            .compactMap { $0 }
            .doOnNext({ [weak self] cache in
                guard let self = self else { return }
                self.recommendPlaylists = cache
            })

        switch option {
        case .server:
            return serverObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if let cardList = self.recommendPlaylists {
                return Observable.of(cardList)
            } else {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        default:
            if let cardList = self.recommendPlaylists {
                return Observable.concat(Observable.of(cardList), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            } else {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: backgroundQueue))
            }
        }
    }
}
