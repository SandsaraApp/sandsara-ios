//
//  PlaylistViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import RxSwift
import RxCocoa

enum PlaylistViewModelContract {
    struct Input: InputType {
        let viewWillAppearTrigger: PublishRelay<()>
    }

    struct Output: OutputType {
        let datasources: Driver<[PlaylistCellViewModel]>
    }
}

final class PlaylistViewModel: BaseViewModel<PlaylistViewModelContract.Input, PlaylistViewModelContract.Output> {

    private let apiService: SandsaraDataServices
    let datas = BehaviorRelay<[PlaylistCellViewModel]>(value: [])

    var isEmpty = false

    init(apiService: SandsaraDataServices, inputs: BaseViewModel<PlaylistViewModelContract.Input, PlaylistViewModelContract.Output>.Input) {
        self.apiService = apiService
        super.init(inputs: inputs)
    }

    override func transform() {
        emitEventLoading(true)
        inputs.viewWillAppearTrigger.subscribeNext { [weak self] in
            guard let self = self else { return }
            self.buildCellVM()
        }.disposed(by: disposeBag)

        setOutput(Output(datasources: datas.asDriver()))
    }

    private func buildCellVM()  {
        var items = [PlaylistCellViewModel]()

        if let favList = DataLayer.loadFavList(), !favList.tracks.isEmpty {
            items.append(PlaylistCellViewModel(inputs: PlaylistCellVMContract.Input(track: DisplayItem(playlist: favList),
                                                                                    isFavorite: true)))
        }

        if DataLayer.loadPlaylists().count > 0 {
            let localList = DataLayer.loadPlaylists().map {
                DisplayItem(playlist: $0)
            }.map {
                PlaylistCellViewModel(inputs: PlaylistCellVMContract.Input(track: $0, isFavorite: false))
            }
            items.append(contentsOf: localList)
        }

        if DataLayer.loadDownloaedPlaylists().count > 0 {
            let localList = DataLayer.loadDownloaedPlaylists().map {
                DisplayItem(playlist: $0)
            }.map {
                PlaylistCellViewModel(inputs: PlaylistCellVMContract.Input(track: $0, isFavorite: false))
            }
            items.append(contentsOf: localList)
        }
        isEmpty = items.isEmpty
        datas.accept(items)
    }

    func canDeletePlaylist(index: Int) -> Bool {
        return !datas.value[index].inputs.isFavorite
    }

    func deletePlaylist(index: Int) {
        if DataLayer.deletePlaylist(datas.value[index].inputs.track.title) {
            inputs.viewWillAppearTrigger.accept(())
        }
    }
}


enum PlaylistCellVMContract {
    struct Input: InputType {
        let track: DisplayItem
        let isFavorite: Bool
    }

    struct Output: OutputType {
        let title: Driver<String>
        let authorTitle: Driver<String>
        let thumbnailUrl: URL?
    }
}

class PlaylistCellViewModel: BaseCellViewModel<PlaylistCellVMContract.Input,
                                               PlaylistCellVMContract.Output> {
    override func transform() {
        let url = URL(string: inputs.track.thumbnail)
        setOutput(Output(title: Driver.just(inputs.track.title),
                         authorTitle: Driver.just(L10n.authorBy(inputs.track.author)), thumbnailUrl: url))
    }
}
