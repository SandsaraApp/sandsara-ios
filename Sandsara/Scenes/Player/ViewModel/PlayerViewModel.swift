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
        let isReloaded: BehaviorRelay<Bool>
    }

    struct Output: OutputType {
        let trackDisplay: Driver<DisplayItem?>
        let datasources: Driver<[TrackCellViewModel]>
    }
}

class PlayerViewModel: BaseViewModel<PlayerViewModelContract.Input, PlayerViewModelContract.Output> {

    override func transform() {
        inputs.isReloaded.subscribeNext { [weak self] in
            if $0 {
                self?.reloadData()
            } else {
                self?.placeHolderData()
            }
        }.disposed(by: disposeBag)
    }

    private func placeHolderData() {
        self.setOutput(Output(trackDisplay: Driver.just(nil),
                              datasources: Driver.just([])))
    }

    private func reloadData() {
        let displayTrack = self.inputs.tracks.count > 0 ? self.inputs.tracks[self.inputs.selectedIndex.value] : nil
        var updatedList = self.inputs.tracks
        self.inputs.selectedIndex.subscribeNext { value in
            if !updatedList.isEmpty {
                updatedList.remove(at: self.inputs.selectedIndex.value)
            }
        }.disposed(by: self.disposeBag)

        self.setOutput(Output(trackDisplay: Driver.just(displayTrack),
                              datasources: Driver.just(updatedList.map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0)) })))
    }


}

