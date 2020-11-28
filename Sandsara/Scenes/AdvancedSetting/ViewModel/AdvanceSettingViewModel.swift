//
//  AdvanceSettingViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 28/11/2020.
//

import RxSwift
import RxCocoa

final class AdvanceSettingViewModel: BaseViewModel<SettingViewModelContract.Input, SettingViewModelContract.Output> {

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
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .firmwareVersion("1.09.1"), color: Asset.secondary.color))))
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .deviceName("Sandsara"), color: Asset.secondary.color))))
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .changeName))))
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .firmwareUpdate))))
        datas.append(.menu(MenuCellViewModel(inputs: MenuCellVMContract.Input(type: .factoryReset))))
        return datas
    }
}


