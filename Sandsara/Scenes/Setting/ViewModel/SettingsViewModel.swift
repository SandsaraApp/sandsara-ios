//
//  SettingsViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit
import RxSwift
import RxCocoa


enum SettingViewModelContract {
    struct Input: InputType {
        let viewWillAppearTrigger: PublishRelay<()>
        let lightMode: BehaviorRelay<LightMode>
    }

    struct Output: OutputType {
        let datasources: Driver<[SettingItemCellType]>
    }
}

final class SettingViewModel: BaseViewModel<SettingViewModelContract.Input, SettingViewModelContract.Output> {

    var status = BehaviorRelay<SandsaraStatus?>(value: nil)

    var sleepMode = BehaviorRelay<Bool>(value: false)

    override func transform() {
        let datas = BehaviorRelay<[SettingItemCellType]>(value: [])
        inputs.viewWillAppearTrigger.subscribeNext { [weak self] in
            guard let self = self else { return }
            datas.accept(self.buildCellVM())
        }.disposed(by: disposeBag)

        setOutput(Output(datasources: datas.asDriver()))
    }

    private func buildCellVM() -> [SettingItemCellType] {
        var datas = [SettingItemCellType]()
        datas.append(.speed(ProgressCellViewModel(inputs: ProgressCellVMContract.Input(type: .speed,
                                                                                       progress: DeviceServiceImpl.shared.ballSpeed))))
        datas.append(.brightness(ProgressCellViewModel(inputs: ProgressCellVMContract.Input(type: .brightness,
                                                                                            progress: DeviceServiceImpl.shared.brightness))))
        datas.append(.lightMode(LightModeCellViewModel(inputs: LightModeVMContract.Input(type: .lightMode, segmentsSelection: inputs.lightMode,
                                                                                         flipDirection: DeviceServiceImpl.shared.flipDirection))))

        datas.append(.toogle(ToogleCellViewModel(inputs: ToogleCellVMContract.Input(type: .sleep, toogle: DeviceServiceImpl.shared.sleepStatus))))
        datas.append(.toogle(ToogleCellViewModel(inputs: ToogleCellVMContract.Input(type: .rotate, toogle: DeviceServiceImpl.shared.cycleMode))))
        return datas
    }
}

