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
    }

    struct Output: OutputType {
        let datasources: Driver<[SettingItemCellType]>
    }
}

final class SettingViewModel: BaseViewModel<SettingViewModelContract.Input, SettingViewModelContract.Output> {

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
                                                                                       progress: BehaviorRelay(value: 0.2)))))
        datas.append(.brightness(ProgressCellViewModel(inputs: ProgressCellVMContract.Input(type: .brightness,
                                                                                       progress: BehaviorRelay(value: 0.2)))))
        datas.append(.presets(PresetsCellViewModel(inputs: PresetsCellViewModel.Input(type: .presets))))
        datas.append(.lightCycleSpeed(ProgressCellViewModel(inputs: ProgressCellVMContract.Input(type: .lightCycleSpeed,
                                                                                            progress: BehaviorRelay(value: 0.2)))))
        datas.append(.advanced(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .advanced))))
        datas.append(.visitSandsara(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .visitSandsara))))
        datas.append(.help(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .help))))
        return datas
    }
}

