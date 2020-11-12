//
//  TrendingViewModel.swift
//  MiniYoutubePlayer
//
//  Created by tin on 5/18/20.
//  Copyright © 2020 tin. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

protocol TrendingViewModelDelegate: class {
    func emitLoading(isLoading: Bool)
    func reloadData()
    func showError(error: Error)
    //func playSection(tracks: [DBTrack])
    func showAllGenre(genres: [GenreItem])
    //func playTrack(index: Int, tracks: [DBTrack])
}

enum DiscoverSections: CaseIterable {
    case topMusic
    case genres

    var title: String {
        switch self {
        case .topMusic:
            return "Recommend Playlist"
        default:
            return "All Playlist"
        }
    }

    var sectionHeight: CGFloat {
        return 50.0
    }
}

class TrendingViewModel {

    // MARK: - VM Input
    weak private var delegate: TrendingViewModelDelegate?

    required init(_ delegate: TrendingViewModelDelegate) {
        self.delegate = delegate
    }

    private let group = DispatchGroup()

    // MARK: - VM Output

    var featurePlaylistSection = [GenreItem]()

    private var genresSection = [GenreItem]()

    var displayGenresSection = [GenreItem]()

    let prefix = UIDevice.current.userInterfaceIdiom == .pad ? 5 : 3

    // MARK: - VM execute function
    func apiCall() {
        if let featuresList = Preferences.PlaylistsDomain.featuredList {
            featurePlaylistSection = featuresList
        }

        if let discoverPlaylist = Preferences.PlaylistsDomain.categories {
            genresSection = discoverPlaylist
            displayGenresSection = genresSection
        }

        delegate?.emitLoading(isLoading: true)

       // getPlaylist(id: Preferences.PlaylistsDomain.topListId ?? "")

        group.notify(queue: .main) { [weak self] in
            self?.delegate?.emitLoading(isLoading: false)
            self?.delegate?.reloadData()
        }
    }

//    func playSection(section: Int) {
//        if section == 0 {
//            self.delegate?.playSection(tracks: self.topMusicSection)
//        }
//
//        if section == 2 {
//            self.delegate?.showAllGenre(genres: self.genresSection)
//        }
//    }
//
//    func playTrackOnSection(section: Int, index: Int) {
//        var videos = [DBTrack]()
//        if section == 0 {
//            videos = topMusicSection
//        }
//        
//        self.delegate?.playTrack(index: index, tracks: videos)
//    }
}
