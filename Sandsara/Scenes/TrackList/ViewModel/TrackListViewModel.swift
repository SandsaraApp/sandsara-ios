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
            let items = DataLayer.loadPlaylistTracks(name: inputs.playlistItem.title).map { DisplayItem(track: $0) }.map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0)) }
            self.datas.accept(
                [PlaylistDetailCellVM.header(PlaylistDetailHeaderViewModel(inputs: PlaylistDetailHeaderVMContract.Input(track: self.inputs.playlistItem)))] +
                    items.map {
                        PlaylistDetailCellVM.track($0)
                    }
            )
        } else {
            apiService.getPlaylistDetail(option: apiService.getServicesOption(for: .playlistDetail)).asObservable().subscribeNext { values in
                let items = values.map { DisplayItem(track: $0) }.map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0)) }
                self.datas.accept(
                    [PlaylistDetailCellVM.header(PlaylistDetailHeaderViewModel(inputs: PlaylistDetailHeaderVMContract.Input(track: self.inputs.playlistItem)))] +
                        items.map {
                            PlaylistDetailCellVM.track($0)
                        }
                )
            }.disposed(by: disposeBag)
        }
    }
}

enum TrackCellVMContract {
    struct Input: InputType {
        let track: DisplayItem
    }

    struct Output: OutputType {
        let title: Driver<String>
        let authorTitle: Driver<String>
        let thumbnailUrl: URL?
    }
}

class TrackCellViewModel: BaseCellViewModel<TrackCellVMContract.Input,
                                               TrackCellVMContract.Output> {
    override func transform() {
        let url = URL(string: inputs.track.thumbnail)
        setOutput(Output(title: Driver.just(inputs.track.title),
                         authorTitle: Driver.just(L10n.authorBy(inputs.track.author)), thumbnailUrl: url))
    }
}

enum PlaylistDetailHeaderVMContract {
    struct Input: InputType {
        let track: DisplayItem
    }

    struct Output: OutputType {
        let title: Driver<String>
        let authorTitle: Driver<String>
        let thumbnailUrl: URL?
    }
}

class PlaylistDetailHeaderViewModel: BaseCellViewModel<PlaylistDetailHeaderVMContract.Input,
                                            PlaylistDetailHeaderVMContract.Output> {
    override func transform() {
        let url = URL(string: inputs.track.thumbnail)
        setOutput(Output(title: Driver.just(inputs.track.title),
                         authorTitle: Driver.just(L10n.authorBy(inputs.track.author)), thumbnailUrl: url))
    }
}

