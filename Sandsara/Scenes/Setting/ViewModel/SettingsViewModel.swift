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

        datas.append(.pause(ToogleCellViewModel(inputs: ToogleCellVMContract.Input(type: .pause,
                                                                                   toogle: BehaviorRelay(value: false)))))

        datas.append(.speed(ProgressCellViewModel(inputs: ProgressCellVMContract.Input(type: .brightness,
                                                                                       progress: BehaviorRelay(value: 0.2)))))

        datas.append(.lightMode(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .lightMode))))

        datas.append(.colorSettings(ColorSettingsCellViewModel(inputs: ColorSettingsCellVMContract.Input(type: .colorSettings))))

        datas.append(.speed(ProgressCellViewModel(inputs: ProgressCellVMContract.Input(type: .lightTemp,
                                                                                       progress: BehaviorRelay(value: 0.2)))))


        datas.append(.lightMode(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .nightMode))))
        datas.append(.lightMode(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .advanced))))
        datas.append(.lightMode(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .visitSandsara))))
        datas.append(.lightMode(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .help))))
        datas.append(.lightMode(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .firmwareUpdate))))
        datas.append(.lightMode(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .sleep))))
        datas.append(.lightMode(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .draw))))
        return datas
    }
}

