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
    private var recommendTracks = BehaviorRelay<[Track]>(value: [])
    private var recommendPlaylists = BehaviorRelay<[Playlist]>(value: [])
    private var allTracks = BehaviorRelay<[Track]>(value: [])
    private var allPlaylist = BehaviorRelay<[Playlist]>(value: [])
    private var playlistDetail = BehaviorRelay<[Track]>(value: [])

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
            if !recommendTracks.value.isEmpty {
                return .server
            }
            return .both
        case .alltrack:
            if !allTracks.value.isEmpty {
                return .server
            }
            return .both
        case .recommendedplaylist:
            if !recommendPlaylists.value.isEmpty {
                return .server
            }
            return .both
        case .playlists:
            if !allPlaylist.value.isEmpty {
                return .server
            }
            return .both
        default:
            return .server
        }
    }

    private func getRecommendedTracksFromServer() -> Observable<[Track]> {
        return api
            .getRecommendTracks()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.recommendTracks.accept(tracks)
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
                self.recommendTracks.accept(cache)
            })

        switch option {
        case .server:
            return serverObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if recommendTracks.value.isEmpty {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return recommendTracks.asObservable()
            }
        default:
            if recommendTracks.value.isEmpty {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return Observable.concat(recommendTracks.asObservable(), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            }
        }
    }

    private func getAllTracksFromServer() -> Observable<[Track]> {
        return api
            .getAllTracks()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.allTracks.accept(tracks)
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
                self.allTracks.accept(cache)
            })

        switch option {
        case .server:
            return serverObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if allTracks.value.isEmpty {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return allTracks.asObservable()
            }
        default:
            if allTracks.value.isEmpty {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return Observable.concat(allTracks.asObservable(), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            }
        }
    }

    private func getPlaylistDetailFromServer() -> Observable<[Track]> {
        return api
            .playlistDetail()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.playlistDetail.accept(tracks)
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
                self.playlistDetail.accept(cache)
            })

        switch option {
        case .server:
            return serverObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if playlistDetail.value.isEmpty {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return playlistDetail.asObservable()
            }
        default:
            if playlistDetail.value.isEmpty {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return Observable.concat(playlistDetail.asObservable(), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            }
        }
    }

    private func getAllPlaylistFromServer() -> Observable<[Playlist]> {
        return api
            .playlists()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.allPlaylist.accept(tracks)
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
                self.allPlaylist.accept(cache)
            })

        switch option {
        case .server:
            return serverObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if allPlaylist.value.isEmpty {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return allPlaylist.asObservable()
            }
        default:
            if allPlaylist.value.isEmpty {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return Observable.concat(allPlaylist.asObservable(), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            }
        }
    }

    private func getRecommendedPlaylistsFromServer() -> Observable<[Playlist]> {
        return api
            .getRecommendPlaylist()
            .do(onSuccess: { [weak self] tracks in
                guard let self = self else { return }
                self.allPlaylist.accept(tracks)
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
        let serverObservable = getAllPlaylistFromServer()
        let localObservable = dataAccess
            .getRecommendedPlaylists()
            .compactMap { $0 }
            .doOnNext({ [weak self] cache in
                guard let self = self else { return }
                self.recommendPlaylists.accept(cache)
            })

        switch option {
        case .server:
            return serverObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
        case .cache:
            if recommendPlaylists.value.isEmpty {
                return localObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return recommendPlaylists.asObservable()
            }
        default:
            if recommendPlaylists.value.isEmpty {
                return Observable.concat(localObservable, serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            } else {
                return Observable.concat(recommendPlaylists.asObservable(), serverObservable)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(queue: backgroundQueue))
            }
        }
    }
}
