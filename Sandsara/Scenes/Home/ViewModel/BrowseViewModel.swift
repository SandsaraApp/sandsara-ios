//
//  BrowseViewModel.swift
//  Sandsara
//
//  Created by tin on 5/18/20.
//  Copyright © 2020 tin. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit

enum DiscoverSection: CaseIterable {
    case recommendedPlaylists
    case recommendedTracks

    var title: String {
        switch self {
        case .recommendedPlaylists:
            return L10n.recommendedPlaylists
        case .recommendedTracks:
            return L10n.recommendedTracks
        }
    }

    var sectionHeight: CGFloat {
        return 54.0
    }
}

enum BrowseVMContract {
    struct Input: InputType {
        let searchText: BehaviorRelay<String?>
        let cancelSearch: PublishRelay<()>
        let viewWillAppearTrigger: PublishRelay<()>
    }

    struct Output: OutputType {
        let datasources: Driver<[RecommendTableViewCellViewModel]>
    }
}

class BrowseViewModel: BaseViewModel<BrowseVMContract.Input, BrowseVMContract.Output> {

    private let apiService: SandsaraDataServices

    private let playlists = BehaviorRelay<[DisplayItem]>(value: [])
    private let tracks = BehaviorRelay<[DisplayItem]>(value: [])

    private let cachedPlaylists = BehaviorRelay<[DisplayItem]>(value: [])
    private let cachedTracks = BehaviorRelay<[DisplayItem]>(value: [])
    
    private var datasources: [RecommendTableViewCellViewModel]

    let completion = BlockOperation {
        print("all done")
    }

    init(apiService: SandsaraDataServices, inputs: BaseViewModel<BrowseVMContract.Input, BrowseVMContract.Output>.Input) {
        self.apiService = apiService
        self.datasources = [RecommendTableViewCellViewModel(inputs: RecommendTableViewCellVMContract
                                                                .Input(section: .recommendedPlaylists, items: [])),
                            RecommendTableViewCellViewModel(inputs: RecommendTableViewCellVMContract
                                                                .Input(section: .recommendedTracks, items: []))]
        super.init(inputs: inputs)
    }

    override func transform() {
        inputs
            .searchText
            .subscribeNext { title in
                self.handleSearch(title: title ?? "")
            }.disposed(by: disposeBag)

        inputs
            .cancelSearch
            .subscribeNext { [weak self] in
                self?.resetSearch()
        }.disposed(by: disposeBag)

        inputs.viewWillAppearTrigger
            .subscribeNext { [weak self] in
            guard let self = self else { return }
            self.emitEventLoading(true)
            self.apiService
                .getRecommendedPlaylists(option: self.apiService.getServicesOption(for: .recommendedplaylist))
                .asObservable()
                .doOnNext { [weak self] playlists in
                    guard let self = self else { return }
                    for playlist in playlists {
                        guard let name = playlist.file?.filename, let size = playlist.file?.size, let urlString = playlist.file?.url, let url = URL(string: urlString) else { continue }
                        let resultCheck = FileServiceImpl.shared.existingFile(fileName: name)
                        if resultCheck.0 == false || resultCheck.1 < size {
                            let operation = DownloadManager.shared.queueDownload(url, item: DisplayItem(playlist: playlist))
                            self.completion.addDependency(operation)
                        }
                    }
                }
                .subscribeNext { playlists in
                    let playlists = playlists.map { DisplayItem(playlist: $0)}
                    self.cachedPlaylists.accept(playlists)
                    self.playlists.accept(playlists)
                    self.apiService
                        .getRecommendTracks(option: self.apiService.getServicesOption(for: .recommendedtracks))
                        .asObservable()
                        .doOnNext { [weak self] playlists in
                            guard let self = self else { return }
                            for playlist in playlists {
                                guard let name = playlist.file?.filename, let size = playlist.file?.size, let urlString = playlist.file?.url, let url = URL(string: urlString) else { continue }
                                let resultCheck = FileServiceImpl.shared.existingFile(fileName: name)
                                if resultCheck.0 == false || resultCheck.1 < size {
                                    let operation = DownloadManager.shared.queueDownload(url, item: DisplayItem(track: playlist))
                                    self.completion.addDependency(operation)
                                }
                            }
                        }
                        .subscribeNext { tracks in
                            let tracks = tracks.map { DisplayItem(track: $0) }
                            self.tracks.accept(tracks)
                            self.cachedTracks.accept(tracks)
                            self.emitEventLoading(false)
                        }.disposed(by: self.disposeBag)
                }.disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)

        let datasources = Driver.combineLatest(self.playlists.asDriver(onErrorJustReturn: (Preferences.PlaylistsDomain.recommendedPlaylists ?? []).map { DisplayItem(playlist: $0)}), self.tracks.asDriver(onErrorJustReturn: (Preferences.PlaylistsDomain.recommendTracks ?? []).map { DisplayItem(track: $0)})).map {
            return [RecommendTableViewCellViewModel(inputs: RecommendTableViewCellVMContract.Input(section: .recommendedPlaylists, items: $0)), RecommendTableViewCellViewModel(inputs: RecommendTableViewCellVMContract.Input(section: .recommendedTracks, items: $1))]
        }

        OperationQueue.main.addOperation(self.completion)

        setOutput(Output(datasources: datasources))
    }

    private func handleSearch(title: String) {
        emitEventLoading(false)
        self.playlists.accept(self.cachedPlaylists.value.filter { $0.title.contains(title) })
        let playlistVM = RecommendTableViewCellViewModel(inputs: RecommendTableViewCellVMContract.Input(section: .recommendedPlaylists, items: self.playlists.value))
        self.tracks.accept(self.cachedTracks.value.filter { $0.title.contains(title) })
        let trackVM = RecommendTableViewCellViewModel(inputs: RecommendTableViewCellVMContract.Input(section: .recommendedTracks, items: self.tracks.value))
        self.datasources = [playlistVM, trackVM]
    }

    private func handleDatas(response1: [Playlist], response2: [Track]) {
        let playlists = response1.map { DisplayItem(playlist: $0)}
        self.playlists.accept(playlists)
        let tracks = response2.map { DisplayItem(track: $0) }
        self.tracks.accept(tracks)
        self.cachedPlaylists.accept(playlists)
        self.cachedTracks.accept(tracks)
        emitEventLoading(false)
    }

    private func resetSearch() {
        self.playlists.accept(self.cachedPlaylists.value)
        self.tracks.accept(self.cachedTracks.value)
    }
}
