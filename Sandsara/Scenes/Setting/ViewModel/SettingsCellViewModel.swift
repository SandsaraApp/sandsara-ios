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

enum PredifinedColor: Int {
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case eleven
    case twelve

    // these one cannot be editted
//    var gradientColors: (UIColor, UIColor) {
//
//    }
}

enum StaticMode: Int {
    case colorTemp
    case customColor
}

enum LightMode: Int {
    case rotate = 0
    case cycle
    case staticMode
}

enum SettingItemCellType {
    case speed(ProgressCellViewModel)
    case brightness(ProgressCellViewModel)
    case lightMode(LightModeCellViewModel)
    case presets(PresetsCellViewModel)
    case lightCycleSpeed(ProgressCellViewModel)
    case menu(MenuCellViewModel)
}

enum SettingItemType {
    case speed
    case brightness
    case lightMode
    case presets
    case lightCycleSpeed
    case advanced
    case visitSandsara
    case help
    case firmwareUpdate
    case changeName
    case factoryReset
    case deviceName(String)
    case firmwareVersion(String)

    var title: String {
        switch self {
        case .speed:
            return L10n.speed
        case .brightness:
            return L10n.brightness
        case .lightMode:
            return L10n.lightmode
        case .presets:
            return L10n.presets
        case .lightCycleSpeed:
            return L10n.lightCycleSpeed
        case .advanced:
            return L10n.advanceSetting
        case .visitSandsara:
            return L10n.website
        case .help:
            return L10n.help
        case .firmwareUpdate:
            return L10n.updateFirmware
        case .changeName: return L10n.changeName
        case .factoryReset: return L10n.factoryReset
        case .deviceName(let name):
            return L10n.deviceName(name)
        case .firmwareVersion(let version):
            return L10n.firmwareVersion(version)
        }
    }
}

extension SettingItemType: Equatable {
    static func ==(lhs: SettingItemType, rhs: SettingItemType) -> Bool {
        switch (lhs, rhs) {
        case let (.deviceName(name1), .deviceName(name2)):
            return name1 == name2
        case let (.firmwareVersion(version1), .firmwareVersion(version2)):
            return version1 == version2
        default:
            return true
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
    }
}

enum MenuCellVMContract {
    struct Input: InputType {
        let type: SettingItemType
        var color: UIColor = Asset.primary.color
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

enum PresetsCellVMContract {
    struct Input: InputType {
        let type: SettingItemType
    }

    struct Output: OutputType {
        let title: Driver<String>
        let datas: Driver<[PresetCellViewModel]>
    }
}

class PresetsCellViewModel: BaseCellViewModel<PresetsCellVMContract.Input,
                                              PresetsCellVMContract.Output>, SettingSendCommandable {

    private let imageNames: [Int] = [Int](0...11)

    override func transform() {

        let images = imageNames.map {
            if $0 == 0 {
                return "Rectangle"
            }
            return "Rectangle-\($0)"
        }.map {
            PresetCellViewModel(inputs: PresetCellVMContract.Input(item: $0))
        }

        setOutput(Output(title: Driver.just(inputs.type.title),
                         datas: Driver.just(images)))
    }

    func sendCommand(command: String) {
        bluejay.write(to: LedStripService.selectPattle, value: command) { result in
            switch result {
            case .success:
                debugPrint("Write to sensor location is successful.\(result)")
            case .failure(let error):
                debugPrint("Failed to write sensor location with error: \(error.localizedDescription)")
            }
        }
    }
}


enum PresetCellVMContract {
    struct Input: InputType {
        let item: String
    }

    struct Output: OutputType {
        let image: Driver<UIImage?>
    }
}

class PresetCellViewModel: BaseCellViewModel<PresetCellVMContract.Input,
                                                PresetCellVMContract.Output> {
    override func transform() {
        setOutput(Output(image: Driver.just(UIImage(named: inputs.item))))
    }
}


enum LightModeVMContract {
    struct Input: InputType {
        let type: SettingItemType
        let segmentsSelection: BehaviorRelay<LightMode>
    }

    struct Output: OutputType {
        let segmentsSelection: Driver<LightMode>
        let title: Driver<String>
        let datas: Driver<[PresetCellViewModel]>
    }
}

class LightModeCellViewModel: BaseCellViewModel<LightModeVMContract.Input,
                                             LightModeVMContract.Output> {
    private let imageNames: [Int] = [Int](0...11)
    override func transform() {
        let images = imageNames.map {
            if $0 == 0 {
                return "Rectangle"
            }
            return "Rectangle-\($0)"
        }.map {
            PresetCellViewModel(inputs: PresetCellVMContract.Input(item: $0))
        }

        setOutput(Output(segmentsSelection: inputs.segmentsSelection.asDriver(),
                         title: Driver.just(inputs.type.title),
                         datas: Driver.just(images)))
    }
}
