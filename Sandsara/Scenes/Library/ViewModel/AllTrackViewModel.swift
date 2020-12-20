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
    }

    struct Output: OutputType {
        let datasources: Driver<[AllTrackCellVM]>
    }
}

final class AllTracksViewModel: BaseViewModel<AllTracksViewModelContract.Input, AllTracksViewModelContract.Output> {

    private let apiService: SandsaraDataServices
    let datas = BehaviorRelay<[AllTrackCellVM]>(value: [])

    private var tracks = [TrackCellViewModel]()

    private let syncAll = PublishRelay<()>()

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

        syncAll.subscribeNext { [weak self] in
            guard let self = self else { return }
            for track in self.tracks where DataLayer.addSyncedTrack(track.inputs.track) {
                let inputString = track.inputs.track.fileName
                let splits = inputString.components(separatedBy: ".")
                ServiceSerialQueue.shared.addTask(.syncFiles) { [weak self] commit -> Bool in
                    guard let self = self else { return false }
                    var fileSuccess = false
                    FileServiceImpl.shared.sendFiles(fileName: splits.first ?? "", extensionName: splits.last ?? "")
                    FileServiceImpl.shared.sendSuccess.subscribeNext {
                        if $0 {
                            _ = DataLayer.addSyncedTrack(track.inputs.track)
                        }
                        fileSuccess = $0
                    }.disposed(by: self.disposeBag)
                    return fileSuccess
                }
            }
        }.disposed(by: disposeBag)

        setOutput(Output(datasources: datas.asDriver()))
    }

    private func buildCellVM()  {
        var datas = [AllTrackCellVM]()
        datas.append(.header(DownloadCellViewModel(inputs: DownloadCellVMContract.Input(notSyncedTrack: .init(value: 10), timeRemaining: .init(value: 350), syncAllTrigger: syncAll))))
        let list = DataLayer.loadDownloadedTracks()
        let items = list.map { DisplayItem(track: $0) }.map { TrackCellViewModel(inputs: TrackCellVMContract.Input(track: $0, saved: DataLayer.checkTrackIsSynced($0))) }.map {
            AllTrackCellVM.track($0)
        }
        datas.append(contentsOf: items)
        self.datas.accept(datas)
        self.emitEventLoading(false)
    }
}

enum DownloadCellVMContract {
    struct Input: InputType {
        var notSyncedTrack: BehaviorRelay<Int>
        var timeRemaining: BehaviorRelay<TimeInterval>
        var syncAllTrigger: PublishRelay<()>
    }

    struct Output: OutputType {
        var notSyncedTrack: Driver<Int>
        var timeRemaining: Driver<String>
    }
}


final class DownloadCellViewModel: BaseCellViewModel<DownloadCellVMContract.Input, DownloadCellVMContract.Output> {

    override func transform() {
        setOutput(Output(notSyncedTrack: inputs.notSyncedTrack.asDriver(),
                         timeRemaining: inputs.timeRemaining.map {
                            String(format:"%.1f", $0 / 60)
                         }.asDriver(onErrorJustReturn: "")))
    }
}
