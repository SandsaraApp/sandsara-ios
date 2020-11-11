//
//  SettingsCellViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum SettingItemCellType {
    case speed(ProgressCellViewModel)
    case pause(ToogleCellViewModel)
    case brightness(ProgressCellViewModel)
    case lightMode(MenuCellViewModel)
    case colorSettings(ColorSettingsCellViewModel)
    case lightTemp(ProgressCellViewModel)
    case nightMode(MenuCellViewModel)
    case advanced(MenuCellViewModel)
    case visitSandsara(MenuCellViewModel)
    case help(MenuCellViewModel)
    case firmwareUpdate(MenuCellViewModel)
    case sleep(MenuCellViewModel)
    case draw(MenuCellViewModel)
}

enum SettingItemType {
    case speed
    case pause
    case brightness
    case lightMode
    case colorSettings
    case lightTemp
    case nightMode
    case advanced
    case visitSandsara
    case help
    case firmwareUpdate
    case sleep
    case draw

    var title: String {
        switch self {
        case .speed:
            return "Speed"
        case .pause:
            return "Pause between tracks"
        case .brightness:
            return "Brightness"
        case .lightMode:
            return "Lighting Mode"
        case .colorSettings:
            return "Color Settings"
        case .lightTemp:
            return "Lighting Color temperature"
        case .nightMode:
            return "Night Mode"
        case .advanced:
            return "Advanced"
        case .visitSandsara:
            return "Visit Sandsara"
        case .help: return "Help"
        case .firmwareUpdate: return "Firmware update"
        case .sleep: return "Sleep"
        case .draw: return "Draw"
        }
    }
}

extension SettingItemCellType: Equatable {
    static func == (lhs: SettingItemCellType, rhs: SettingItemCellType) -> Bool {
        return false
    }
}

protocol SettingSendCommandable {
    func sendCommand(command: String)
}


enum ProgressCellVMContract {
    struct Input: InputType {
        let type: SettingItemType
        let progress: BehaviorRelay<Float>
    }

    struct Output: OutputType {
        let title: Driver<String>
        let command: Driver<String>
    }
}

class ProgressCellViewModel: BaseCellViewModel<ProgressCellVMContract.Input,
                                               ProgressCellVMContract.Output>, SettingSendCommandable {
    override func transform() {
        inputs
            .progress
            .subscribeNext { value in
                self.sendCommand(command: "\(value)")
        }.disposed(by: disposeBag)

        setOutput(Output(title: Driver.just(inputs.type.title),
                         command: Driver.just("\(inputs.progress.value)")))
    }

    func sendCommand(command: String) {
        // TODO: support multi type here
    }
}


enum ToogleCellVMContract {
    struct Input: InputType {
        let type: SettingItemType
        let toogle: BehaviorRelay<Bool>
    }

    struct Output: OutputType {
        let title: Driver<String>
        let command: Driver<String>
    }
}

class ToogleCellViewModel: BaseCellViewModel<ToogleCellVMContract.Input,
                                               ToogleCellVMContract.Output>, SettingSendCommandable {
    override func transform() {
        inputs
            .toogle
            .subscribeNext { value in
                self.sendCommand(command: "\(value)")
            }.disposed(by: disposeBag)

        setOutput(Output(title: Driver.just(inputs.type.title),
                         command: Driver.just("\(inputs.toogle.value)")))
    }

    func sendCommand(command: String) {
        // TODO: support multi type here
    }
}

enum MenuCellVMContract {
    struct Input: InputType {
        let type: SettingItemType
    }

    struct Output: OutputType {
        let title: Driver<String>
    }
}

class MenuCellViewModel: BaseCellViewModel<MenuCellVMContract.Input,
                                             MenuCellVMContract.Output> {
    override func transform() {
        setOutput(Output(title: Driver.just(inputs.type.title)))
    }
}

enum DropDownCellVMContract {
    struct Input: InputType {
        let type: SettingItemType
    }

    struct Output: OutputType {
        let title: Driver<String>
        let datas: Driver<[String]>
    }
}

class DropDownCellViewModel: BaseCellViewModel<DropDownCellVMContract.Input,
                                           DropDownCellVMContract.Output> {
    override func transform() {
        setOutput(Output(title: Driver.just(inputs.type.title),
                         datas: Driver.just(["1", "2", "3", "4"])))
    }
}

enum ColorSettingsCellVMContract {
    struct Input: InputType {
        let type: SettingItemType
    }

    struct Output: OutputType {
        let title: Driver<String>
        let buttonTitles: Driver<[String]>
    }
}

class ColorSettingsCellViewModel: BaseCellViewModel<ColorSettingsCellVMContract.Input,
                                                    ColorSettingsCellVMContract.Output> {
    override func transform() {
        setOutput(Output(title: Driver.just(inputs.type.title),
                         buttonTitles: Driver.just(["Primary", "Secondary"])))
    }
}
