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

    override func transform() {
        let datas = BehaviorRelay<[PlaylistCellViewModel]>(value: [])
        inputs.viewWillAppearTrigger.subscribeNext { [weak self] in
            guard let self = self else { return }
            datas.accept(self.buildCellVM())
        }.disposed(by: disposeBag)

        setOutput(Output(datasources: datas.asDriver()))
    }

    private func buildCellVM() -> [PlaylistCellViewModel] {
        var datas = [PlaylistCellViewModel]()

        let playlists = ["default playlist".uppercased(), "Guest artist".uppercased(), "Demo".uppercased(), "favorites".uppercased(), "Create Playlist".uppercased()]

        datas = playlists.map {
            return PlaylistCellViewModel(inputs: PlaylistCellVMContract.Input(title: $0))
        }
        return datas
    }
}


enum PlaylistCellVMContract {
    struct Input: InputType {
        let title: String
    }

    struct Output: OutputType {
        let title: Driver<String>
    }
}

class PlaylistCellViewModel: BaseCellViewModel<PlaylistCellVMContract.Input,
                                               PlaylistCellVMContract.Output> {
    override func transform() {
        setOutput(Output(title: Driver.just(inputs.title)))
    }
}
