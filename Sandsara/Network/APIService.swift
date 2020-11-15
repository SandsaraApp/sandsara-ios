//
//  APIService.swift
//  Sandsara
//
//  Created by Tín Phan on 14/11/2020.
//

import RxAlamofire
import RxSwift
import Moya

enum ServiceOption {
    case cache
    case server
    case both //-- geting data from cache first and then getting from API
}

protocol APIServiceCall {
    func getRecommendPlaylist() -> Single<[Track]>
    func getRecommendTracks() -> Single<[Track]>
    func playlists() -> Single<[Playlist]>
    func playlistDetail() -> Single<[Track]>
}

class SandsaraAPIService: APIServiceCall {

    private let apiProvider: MoyaProvider<SandsaraAPI>

    init(apiProvider: MoyaProvider<SandsaraAPI>) {
        self.apiProvider = apiProvider
    }

    func getRecommendTracks() -> Single<[Track]> {
        return apiProvider.rx.request(.recommendedtracks).map([Track].self)
    }

    func getRecommendPlaylist() -> Single<[Track]> {
        return apiProvider.rx.request(.recommendedplaylist).map([Track].self)
    }

    func playlistDetail() -> Single<[Track]> {
        return apiProvider.rx.request(.playlistDetail).map([Track].self)
    }

    func playlists() -> Single<[Playlist]> {
        return apiProvider.rx.request(.playlists).map([Playlist].self)
    }
}
