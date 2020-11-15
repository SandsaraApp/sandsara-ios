//
//  APIService.swift
//  Sandsara
//
//  Created by Tín Phan on 14/11/2020.
//

import RxSwift
import Moya

enum ServiceOption {
    case cache
    case server
    case both //-- geting data from cache first and then getting from API
}

protocol APIServiceCall {
    func getRecommendPlaylist() -> Single<[Playlist]>
    func getRecommendTracks() -> Single<[Track]>
    func playlists() -> Single<[Playlist]>
    func playlistDetail() -> Single<[Track]>
    func getAllTracks() -> Single<[Track]>
}

class SandsaraAPIService: APIServiceCall {

    private let apiProvider: MoyaProvider<SandsaraAPI>

    init(apiProvider: MoyaProvider<SandsaraAPI>) {
        self.apiProvider = apiProvider
    }

    func getRecommendTracks() -> Single<[Track]> {
        return apiProvider
            .rx.request(.recommendedtracks)
            .map(TracksResponse.self).map { $0.tracks }
    }

    func getRecommendPlaylist() -> Single<[Playlist]> {
        return apiProvider
            .rx.request(.recommendedplaylist)
            .map(PlaylistsResponse.self)
            .map { $0.playlists }
    }

    func playlistDetail() -> Single<[Track]> {
        return apiProvider
            .rx.request(.playlistDetail)
            .map(TracksResponse.self)
            .map { $0.tracks }
    }

    func playlists() -> Single<[Playlist]> {
        return apiProvider
            .rx.request(.playlists)
            .map(PlaylistsResponse.self)
            .map { $0.playlists }
    }

    func getAllTracks() -> Single<[Track]> {
        return apiProvider
            .rx.request(.alltrack)
            .map(TracksResponse.self).map { $0.tracks }
    }
}
