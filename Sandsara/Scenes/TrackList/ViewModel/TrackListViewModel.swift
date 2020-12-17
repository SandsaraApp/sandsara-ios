//
//  TrackListViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import RxSwift
import RxCocoa

enum PlaylistDetailCellVM {
    case header(PlaylistDetailHeaderViewModel)
    case track(TrackCellViewModel)
    case empty
}

enum TrackListViewModelContract {
    struct Input: InputType {
        let playlistItem: DisplayItem
        let viewWillAppearTrigger: PublishRelay<()>
    }

    struct Output: OutputType {
        let datasources: Driver<[PlaylistDetailCellVM]>
    }
}

final class TrackListViewModel: BaseViewModel<TrackListViewModelContract.Input, TrackListViewModelContract.Output> {

    private let apiService: SandsaraDataServices
    let datas = BehaviorRelay<[PlaylistDetailCellVM]>(value: [])

    var isEmpty = false

    init(apiService: SandsaraDataServices, inputs: BaseViewModel<TrackListViewModelContract.Input, TrackListViewModelContract.Output>.Input) {
        self.apiService = apiService
        super.init(inputs: inputs)
    }

    override func transform() {
        inputs.viewWillAppearTrigger.subscribeNext { [weak self] in
            guard let self = self else { return }
            self.buildCellVM()
        }.disposed(by: disposeBag)

        setOutput(Output(datasources: datas.asDriver()))
    }

    private func buildCellVM()  {
        if inputs.playlistItem.isLocal {
            let isFavlist = inputs.playlistItem.title == L10n.favorite
            let list = isFavlist ? DataLayer.loadFavTracks() : DataLayer.loadPlaylistTracks(name: inputs.playlistItem.title)
            let items = list.map { DisplayItem(track: $0) }.map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0)) }.map {
                PlaylistDetailCellVM.track($0)
            }
            self.isEmpty = items.isEmpty
            let showItems = items.isEmpty ? [PlaylistDetailCellVM.empty] : items
            self.datas.accept(
                [PlaylistDetailCellVM.header(PlaylistDetailHeaderViewModel(inputs: PlaylistDetailHeaderVMContract.Input(track: self.inputs.playlistItem, isFavlist: isFavlist)))] +
                    showItems
            )
        } else {
            if inputs.playlistItem.isTestPlaylist {
                let isFavlist = true
                let list = DataLayer.loadDownloadedDetailList(name: inputs.playlistItem.title)
                let items = list.map { DisplayItem(track: $0) }.map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0)) }.map {
                    PlaylistDetailCellVM.track($0)
                }
                self.isEmpty = items.isEmpty
                let showItems = items.isEmpty ? [PlaylistDetailCellVM.empty] : items
                self.datas.accept(
                    [PlaylistDetailCellVM.header(PlaylistDetailHeaderViewModel(inputs: PlaylistDetailHeaderVMContract.Input(track: self.inputs.playlistItem, isFavlist: isFavlist)))] +
                        showItems
                )
            } else {
                let isFavlist = !inputs.playlistItem.isLocal
                let items = inputs.playlistItem.tracks
                    .map { DisplayItem(track: $0) }
                    .map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0)) }
                    .map { PlaylistDetailCellVM.track($0) }
                self.datas.accept(
                    [PlaylistDetailCellVM.header(PlaylistDetailHeaderViewModel(inputs: PlaylistDetailHeaderVMContract.Input(track: self.inputs.playlistItem,
                                                                                                                            isFavlist: isFavlist)))] +
                        items
                )
            }
        }
    }

    func deleteTracks(index: Int) {
        switch datas.value[index] {
            case .track(let vm):
                let localTrack = LocalTrack(track: vm.inputs.track)
                DataLayer.deleteTrackFromPlaylist(inputs.playlistItem.title, localTrack)
                inputs.viewWillAppearTrigger.accept(())
            default: break
        }
    }
}

enum TrackCellVMContract {
    struct Input: InputType {
        var track: DisplayItem
        var saved: Bool = false
    }

    struct Output: OutputType {
        let title: Driver<String>
        let authorTitle: Driver<String>
        let thumbnailUrl: URL?
        let saved: Driver<Bool>
    }
}

class TrackCellViewModel: BaseCellViewModel<TrackCellVMContract.Input,
                                               TrackCellVMContract.Output> {
    override func transform() {
        let url = URL(string: inputs.track.thumbnail)
        setOutput(Output(title: Driver.just(inputs.track.title),
                         authorTitle: Driver.just(L10n.authorBy(inputs.track.author)),
                         thumbnailUrl: url,
                         saved: Driver.just(DataLayer.checkTrackIsSynced(inputs.track))))
    }
}

enum PlaylistDetailHeaderVMContract {
    struct Input: InputType {
        let track: DisplayItem
        let isFavlist: Bool
    }

    struct Output: OutputType {
        let title: Driver<String>
        let authorTitle: Driver<String>
        let thumbnailUrl: URL?
        let isFavoriteList: Driver<Bool>
    }
}

class PlaylistDetailHeaderViewModel: BaseCellViewModel<PlaylistDetailHeaderVMContract.Input,
                                            PlaylistDetailHeaderVMContract.Output> {
    override func transform() {
        let url = URL(string: inputs.track.thumbnail)
        setOutput(Output(title: Driver.just(inputs.track.title),
                         authorTitle: Driver.just(L10n.authorBy(inputs.track.author)),
                         thumbnailUrl: url,
                         isFavoriteList: Driver.just(inputs.isFavlist)))
    }
}

