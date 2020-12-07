//
//  AdvanceSettingViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 28/11/2020.
//

import RxSwift
import RxCocoa

enum AdvanceSettingViewModelContract {
    struct Input: InputType {
        let viewWillAppearTrigger: PublishRelay<()>
    }

    struct Output: OutputType {
        let datasources: Driver<[SettingItemCellType]>
    }
}

final class AdvanceSettingViewModel: BaseViewModel<AdvanceSettingViewModelContract.Input, AdvanceSettingViewModelContract.Output> {

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
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .firmwareVersion(DeviceServiceImpl.shared.firmwareVersion.value.isEmpty ? "N/A" : DeviceServiceImpl.shared.firmwareVersion.value ), color: Asset.secondary.color))))
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .deviceName(DeviceServiceImpl.shared.deviceName.value.isEmpty ? "N/A" : DeviceServiceImpl.shared.deviceName.value), color: Asset.secondary.color))))
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .changeName))))
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .firmwareUpdate))))
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .factoryReset))))
        return datas
    }
}


