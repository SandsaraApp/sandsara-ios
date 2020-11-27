//
//  AllTrackViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import UIKit
import RxCocoa
import RxSwift

enum AllTracksViewModelContract {
    struct Input: InputType {
        let viewWillAppearTrigger: PublishRelay<()>
    }

    struct Output: OutputType {
        let datasources: Driver<[TrackCellViewModel]>
    }
}

final class AllTracksViewModel: BaseViewModel<AllTracksViewModelContract.Input, AllTracksViewModelContract.Output> {

    private let apiService: SandsaraDataServices
    let datas = BehaviorRelay<[TrackCellViewModel]>(value: [])

    init(apiService: SandsaraDataServices, inputs: BaseViewModel<AllTracksViewModelContract.Input, AllTracksViewModelContract.Output>.Input) {
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
        apiService.getAllTracks(option: apiService.getServicesOption(for: .alltrack)).asObservable().subscribeNext { values in
            let items = values.map { DisplayItem(track: $0) }.map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0)) }
            self.datas.accept(items)
            self.emitEventLoading(false)
        }.disposed(by: disposeBag)
    }
}
