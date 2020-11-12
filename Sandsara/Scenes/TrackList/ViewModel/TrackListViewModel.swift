//
//  TrackListViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import RxSwift
import RxCocoa

enum TrackListViewModelContract {
    struct Input: InputType {
        let viewWillAppearTrigger: PublishRelay<()>
    }

    struct Output: OutputType {
        let datasources: Driver<[TrackCellViewModel]>
    }
}

final class TrackListViewModel: BaseViewModel<TrackListViewModelContract.Input, TrackListViewModelContract.Output> {

    override func transform() {
        let datas = BehaviorRelay<[TrackCellViewModel]>(value: [])
        inputs.viewWillAppearTrigger.subscribeNext { [weak self] in
            guard let self = self else { return }
            datas.accept(self.buildCellVM())
        }.disposed(by: disposeBag)

        setOutput(Output(datasources: datas.asDriver()))
    }

    private func buildCellVM() -> [TrackCellViewModel] {
        var datas = [TrackCellViewModel]()

        let playlists: [Track] = Array(repeating: Track(title: "SongTitle", author: "Author"), count: 10)

        datas = playlists.map {
            return TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0))
        }
        return datas
    }
}

struct Track {
    let title: String
    let author: String
}

enum TrackCellVMContract {
    struct Input: InputType {
        let track: Track
    }

    struct Output: OutputType {
        let title: Driver<String>
        let authorTitle: Driver<String>
    }
}

class TrackCellViewModel: BaseCellViewModel<TrackCellVMContract.Input,
                                               TrackCellVMContract.Output> {
    override func transform() {
        setOutput(Output(title: Driver.just(inputs.track.title),
                         authorTitle: Driver.just(inputs.track.author)))
    }
}

