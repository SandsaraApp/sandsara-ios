//
//  PlayerViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import RxSwift
import RxCocoa

enum PlayerViewModelContract {
    struct Input: InputType {
        let selectedIndex: BehaviorRelay<Int>
        let tracks: [DisplayItem]
    }

    struct Output: OutputType {
        let trackDisplay: Driver<DisplayItem>
        let datasources: Driver<[TrackCellViewModel]>
    }
}

class PlayerViewModel: BaseViewModel<PlayerViewModelContract.Input, PlayerViewModelContract.Output> {

    override func transform() {
        let displayTrack = inputs.tracks[inputs.selectedIndex.value]
        var updatedList = self.inputs.tracks
        inputs.selectedIndex.subscribeNext { value in
            updatedList.remove(at: self.inputs.selectedIndex.value)
        }.disposed(by: disposeBag)

        setOutput(Output(trackDisplay: Driver.just(displayTrack),
                         datasources: Driver.just(updatedList.map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0)) })))
    }


}

