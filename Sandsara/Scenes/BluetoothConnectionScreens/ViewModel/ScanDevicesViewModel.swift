//
//  ScanDevicesViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 11/7/20.
//

import Foundation
import RxSwift
import RxCocoa
import RxBluetoothKit

enum ScanDevicesViewModelContract {
    struct Input: InputType {
        var scanAction: PublishRelay<()>
        var stopAction: PublishRelay<()>
    }

    struct Output: OutputType {
        var scanningOutput: Observable<Result<ScannedPeripheral, Error>>
    }
}

class ScanDevicesViewModel: BaseViewModel<ScanDevicesViewModelContract.Input, ScanDevicesViewModelContract.Output> {

    var service: RxBluetoothKitService

    init(inputs: BaseViewModel<ScanDevicesViewModelContract.Input, ScanDevicesViewModelContract.Output>.Input, service: RxBluetoothKitService) {
        self.service = service
        super.init(inputs: inputs)
    }

    override func transform() {
        inputs
            .scanAction
            .subscribeNext { [weak self] _ in
                guard let self = self else { return }
                self.service.startScanning()
        }.disposed(by: disposeBag)

        inputs
            .stopAction
            .subscribeNext { [weak self] _ in
                guard let self = self else { return }
                self.service.stopScanning()
        }.disposed(by: disposeBag)

        setOutput(Output(scanningOutput: service.scanningOutput))
    }
}
