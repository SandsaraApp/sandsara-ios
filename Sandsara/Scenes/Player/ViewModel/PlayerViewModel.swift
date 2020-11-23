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
        let trackDisplay: Driver<DisplayItem?>
        let datasources: Driver<[TrackCellViewModel]>
    }
}

class PlayerViewModel: BaseViewModel<PlayerViewModelContract.Input, PlayerViewModelContract.Output> {

    let displayTrack = BehaviorRelay<DisplayItem?>(value: nil)
    let datas = BehaviorRelay<[TrackCellViewModel]>(value: [])

    override func transform() {
        datas.accept(inputs.tracks.map {
            TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0))
        })
        self.inputs.selectedIndex.subscribeNext { value in
            guard !self.inputs.tracks.isEmpty else { return }
            self.displayTrack.accept(self.inputs.tracks[value])
        }.disposed(by: self.disposeBag)
        self.setOutput(Output(trackDisplay: self.displayTrack.asDriver(onErrorJustReturn: nil),
                              datasources: datas.asDriver()))
    }

    private func placeHolderData() {
        displayTrack.accept(nil)
        datas.accept([])
    }
}

