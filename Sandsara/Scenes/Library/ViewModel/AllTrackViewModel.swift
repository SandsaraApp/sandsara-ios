//
//  AllTrackViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import UIKit
import RxCocoa
import RxSwift

enum AllTrackCellVM {
    case header(DownloadCellViewModel)
    case track(TrackCellViewModel)
}

enum AllTracksViewModelContract {
    struct Input: InputType {
        let viewWillAppearTrigger: PublishRelay<()>
        let syncAll: PublishRelay<()>
    }

    struct Output: OutputType {
        let datasources: Driver<[AllTrackCellVM]>
    }
}

final class AllTracksViewModel: BaseViewModel<AllTracksViewModelContract.Input, AllTracksViewModelContract.Output> {

    private let apiService: SandsaraDataServices
    let datas = BehaviorRelay<[AllTrackCellVM]>(value: [])

    private var tracks = [TrackCellViewModel]()


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
        let completion = BlockOperation {
            self.inputs.viewWillAppearTrigger.accept(())
        }
        inputs.syncAll.subscribeNext { [weak self] in
            guard let self = self else { return }
            for track in self.tracks  {
                let operation = FileSyncManager.shared.queueDownload(item: track.inputs.track)
                FileSyncManager.shared.triggerOperation(id: track.inputs.track.trackId)
                completion.addDependency(operation)
                OperationQueue.main.addOperation(completion)
            }
            self.inputs.viewWillAppearTrigger.accept(())
        }.disposed(by: disposeBag)

        setOutput(Output(datasources: datas.asDriver()))
    }

    private func buildCellVM()  {
        var datas = [AllTrackCellVM]()

        let list = DataLayer.loadDownloadedTracks()
        let items = list.map { DisplayItem(track: $0) }.map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0, saved: DataLayer.checkTrackIsSynced($0))) }.map {
            AllTrackCellVM.track($0)
        }
        if items.count > 0 {
            datas.append(.header(DownloadCellViewModel(inputs: DownloadCellVMContract.Input(notSyncedTrack: .init(value: DataLayer.loadDownloadedTracks().count - DataLayer.loadSyncedTracks().count), timeRemaining: FileSyncManager.shared.getCurrentTimeRunning(), syncAllTrigger: inputs.syncAll))))
        }
        datas.append(contentsOf: items)
        self.datas.accept(datas)
        self.emitEventLoading(false)
    }
}

enum DownloadCellVMContract {
    struct Input: InputType {
        var notSyncedTrack: BehaviorRelay<Int>
        var timeRemaining: Observable<TimeInterval>?
        var syncAllTrigger: PublishRelay<()>
    }

    struct Output: OutputType {
        var notSyncedTrack: Driver<Int>
        var timeRemaining: Driver<String>?
    }
}


final class DownloadCellViewModel: BaseCellViewModel<DownloadCellVMContract.Input, DownloadCellVMContract.Output> {

    override func transform() {
        setOutput(Output(notSyncedTrack: inputs.notSyncedTrack.asDriver(),
                         timeRemaining: inputs.timeRemaining?.map {
                            String(format:"%.1f", $0 / 60)
                         }.asDriver(onErrorJustReturn: "")))
    }
}
