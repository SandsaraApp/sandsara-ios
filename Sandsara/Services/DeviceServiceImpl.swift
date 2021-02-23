//
//  DeviceServiceImpl.swift
//  Sandsara
//
//  Created by Tín Phan on 30/11/2020.
//

import Foundation
import Bluejay
import RxSwift
import RxCocoa

enum SandsaraStatus: Int {
    case unknown
    case calibrating = 1
    case running
    case pause
    case sleep
    case busy
}

class DeviceServiceImpl {
    static let shared = DeviceServiceImpl()
    
    let firmwareVersion = BehaviorRelay<String>(value: "")
    let deviceName = BehaviorRelay<String>(value: "")
    let ballSpeed = BehaviorRelay<Float>(value: 0)
    
    let sleepStatus = BehaviorRelay<Bool>(value: false)
    
    let status = BehaviorRelay<SandsaraStatus?>(value: nil)
    
    let updateError = BehaviorRelay<Error?>(value: nil)
    
    let ledSpeed = BehaviorRelay<Float>(value: 0)
    let brightness = BehaviorRelay<Float>(value: 0)
    
    let cycleMode = BehaviorRelay<Bool>(value: false)
    
    let flipDirection = BehaviorRelay<Bool>(value: false)
    
    let selectedPalette = BehaviorRelay<Int>(value: 0)
    
    let isSleep = BehaviorRelay<Bool>(value: false)
    
    let lightMode = BehaviorRelay<LightMode>(value: .cycle)
    
    let lightModeInt = BehaviorRelay<Int>(value: 0)
    
    let disposeBag = DisposeBag()
    
    let currentPlaylistName = BehaviorRelay<String>(value: "")
    
    let currentPath = BehaviorRelay<String>(value: "")
    
    let currentPosition = BehaviorRelay<Int>(value: 0)
    
    let runningColor = BehaviorRelay<ColorModel?>(value: nil)
    
    let currentTrackPosition = BehaviorRelay<Float>(value: 0)
    
    var currentTrackIndex = 0
    
    var currentTracks = [DisplayItem]()
    
    var tracks = [String]()
    
    func readSensorValues() {
        bluejay.run { sandsaraBoard -> Bool in
            do {
                let name: String = try sandsaraBoard.read(from: DeviceService.deviceName)
                print("Device Name \(name)")
                self.deviceName.accept(name)
            } catch(let error) {
                print(error.localizedDescription)
            }
            do {
                let firmware: String = try sandsaraBoard.read(from: DeviceService.firmwareVersion)
                print("Firmware Version \(firmware)")
                self.firmwareVersion.accept(firmware)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let ballSpeed: String = try sandsaraBoard.read(from: DeviceService.speed)
                self.ballSpeed.accept(Float(ballSpeed) ?? 0)
                print("Ball Speed \(ballSpeed)")
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let deviceStatus: String = try sandsaraBoard.read(from: DeviceService.deviceStatus)
                let intValue = Int(deviceStatus) ?? 0
                let status = SandsaraStatus(rawValue: intValue) ?? .unknown
                self.status.accept(status)
                self.sleepStatus.accept(status == .sleep)
                print("Device status \(status)")
            } catch(let error) {
                self.status.accept(.unknown)
                print(error.localizedDescription)
            }
            
            do {
                let ledSpeed: String = try sandsaraBoard.read(from: LedStripService.ledStripSpeed)
                print("Led speed \(ledSpeed)")
                self.ledSpeed.accept(Float(ledSpeed) ?? 0)
            } catch(let error) {
                print(error.localizedDescription)
            }
            do {
                let brightness: String = try sandsaraBoard.read(from: LedStripService.brightness)
                print("Brightness \(brightness)")
                self.brightness.accept(Float(brightness) ?? 0)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let cycleMode: String = try sandsaraBoard.read(from: LedStripService.ledStripCycleEnable)
                print("Mode \(cycleMode)")
                self.cycleMode.accept(cycleMode == "0" ? true : false)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let direction: String = try sandsaraBoard.read(from: LedStripService.ledStripDirection)
                print("Mode \(direction)")
                self.flipDirection.accept(direction == "0" ? true : false)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let selectedPalette: String = try sandsaraBoard.read(from: LedStripService.selectPattle)
                print("Led speed \(selectedPalette)")
                self.selectedPalette.accept(Int(selectedPalette) ?? 0)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let selectedPalette: String = try sandsaraBoard.read(from: PlaylistService.playlistName)
                print("\(selectedPalette)")
                self.currentPlaylistName.accept(selectedPalette)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let selectedPalette: String = try sandsaraBoard.read(from: PlaylistService.pathName)
                print("Led speed \(selectedPalette)")
                self.currentPath.accept(selectedPalette)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            var colorModel = ColorModel()
            var positions = [Int]()
            var amount : Int = 0
            do {
                let amountColor: String = try sandsaraBoard.read(from: LedStripService.amountOfColors)
                amount = Int(amountColor) ?? 0
                debugPrint("Amount \(amountColor)")
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let amount: String = try sandsaraBoard.read(from: LedStripService.positions)
                positions = amount.components(separatedBy: ",").map { Int($0) ?? 0 }
                debugPrint("Position \(amount)")
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            var reds = [Float]()
            do {
                let red: String = try sandsaraBoard.read(from: LedStripService.red)
                reds = red.components(separatedBy: ",").map { Float($0) ?? 0.0 }
                debugPrint("reds \(red)")
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            var blues = [Float]()
            do {
                let blue: String = try sandsaraBoard.read(from: LedStripService.blue)
                blues = blue.components(separatedBy: ",").map { Float($0) ?? 0.0 }
                debugPrint("blues \(blue)")
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            var greens = [Float]()
            do {
                let green: String = try sandsaraBoard.read(from: LedStripService.green)
                greens = green.components(separatedBy: ",").map { Float($0) ?? 0.0 }
                debugPrint("greens \(green)")
            } catch(let error) {
                print(error.localizedDescription)
            }
            let colors = zip3(reds, greens, blues).map {
                RGBA(red: CGFloat($0.0) / 255, green: CGFloat($0.1) / 255, blue: CGFloat($0.2) / 255).color().hexString()
            }
            if positions.count == 1 {
                colorModel.position = [0, 255]
                if let color = colors.first {
                    colorModel.colors = [color, color]
                }
            } else {
                colorModel.position = positions
                colorModel.colors = colors
            }
            
            self.runningColor.accept(colorModel)
            
            var resultFiles = ""
            do {
                try sandsaraBoard.writeAndListen(writeTo: FileService.readFileFlag, value: self.currentPlaylistName.value + ".playlist", listenTo: FileService.receiveFileRespone, completion: {
                    (result: String) -> ListenAction in
                    resultFiles = result
                    return .done
                })
            }
            
            if resultFiles == "ok" {
                var bytes = ""
                while(true) {
                    let byteReaded: String = try sandsaraBoard.read(from: FileService.readFiles)
                    bytes += byteReaded
                    if byteReaded.utf8.count < 512 { break }
                }
                
                let progress: String = try sandsaraBoard.read(from: PlaylistService.progressOfPath)
                let index: String = try sandsaraBoard.read(from: PlaylistService.pathPosition)
                
                self.currentTrackPosition.accept(Float(progress) ?? 0.0)
                self.currentTrackIndex = (Int(index) ?? 0) - 1
                self.tracks = bytes.split(separator: "\r\n").map {
                    String($0)
                }
                if self.currentTrackIndex > self.tracks.count {
                    self.currentTrackIndex = self.tracks.count - 1
                }
            }
            
            return false
        } completionOnMainThread: { result in
            switch result {
            case .success:
                self.currentTracks = self.tracks.map {
                    DataLayer.loadDownloadedTrack($0)
                }
                if UIApplication.topViewController()?.tabBarController != nil {
                    NotificationCenter.default.post(name: reloadTab, object: nil)
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func updateDeviceName(name: String) {
        bluejay.write(to: DeviceService.deviceName, value: name) { result in
            switch result {
            case .success:
                self.deviceName.accept(name)
            case .failure(let error):
                print(error.localizedDescription)
                self.updateError.accept(error)
            }
        }
    }
    
    func sleepDevice() {
        bluejay.write(to: DeviceService.sleep, value: "1") { result in
            switch result {
            case .success:
                debugPrint("Sleep Success")
            case .failure(let error):
                print(error.localizedDescription)
                self.updateError.accept(error)
                
                if error.localizedDescription == "" {
                    //   self.readDeviceStatus()
                }
            }
        }
    }
    
    func resumeDevice() {
        bluejay.write(to: DeviceService.play, value: "1") { result in
            switch result {
            case .success:
                debugPrint("Resume Success")
            //  self.readDeviceStatus()
            case .failure(let error):
                print(error.localizedDescription)
                self.updateError.accept(error)
                
                if error.localizedDescription == "" {
                    //     self.readDeviceStatus()
                }
            }
        }
    }
    
    func pauseDevice() {
        bluejay.write(to: DeviceService.pause, value: "1") { result in
            switch result {
            case .success:
                debugPrint("Resume Success")
            //    self.readDeviceStatus()
            case .failure(let error):
                print(error.localizedDescription)
                self.updateError.accept(error)
            }
        }
    }
    
    func readDeviceStatus() {
        bluejay.read(from: DeviceService.deviceStatus) { (result: ReadResult<String>) in
            switch result {
            case .success(let value):
                let intValue = Int(value) ?? 0
                let status = SandsaraStatus(rawValue: intValue)
                self.status.accept(status ?? .calibrating)
                print("Status \(status.debugDescription)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func updateCycleMode(mode: String) {
        bluejay.write(to: LedStripService.ledStripCycleEnable, value: mode) { result in
            switch result {
            case .success:
                print("update cycle done")
            case .failure(let error):
                print(error.localizedDescription)
                self.updateError.accept(error)
            }
        }
    }
    
    func updateDirection(direction: String) {
        bluejay.write(to: LedStripService.ledStripDirection, value: direction) { result in
            switch result {
            case .success:
                print("update direction done")
         
            case .failure(let error):
                print(error.localizedDescription)
                self.updateError.accept(error)
            }
        }
    }
    
    func factoryReset() {
        bluejay.write(to: DeviceService.factoryReset, value: "1") { result in
            switch result {
            case .success:
                self.readDeviceStatus()
            case .failure(let error):
                print(error.localizedDescription)
                self.updateError.accept(error)
                
                if error.localizedDescription == "" {
                    self.readDeviceStatus()
                }
            }
        }
    }
    
    func restart() {
        bluejay.write(to: DeviceService.restart, value: "1") { result in
            switch result {
            case .success:
                self.readDeviceStatus()
            case .failure(let error):
                print(error.localizedDescription)
                self.updateError.accept(error)
                
                if error.localizedDescription == "" {
                    self.readDeviceStatus()
                }
            }
        }
    }
    
    func cleanup() {
        deviceName.accept("")
        firmwareVersion.accept("")
        ballSpeed.accept(0)
        status.accept(nil)
        ledSpeed.accept(0)
        selectedPalette.accept(0)
        cycleMode.accept(false)
        flipDirection.accept(false)
        brightness.accept(0)
        lightMode.accept(.cycle)
        currentPlaylistName.accept("")
        currentPath.accept("")
        currentTrackIndex = 0
        currentTracks = []
    }
    
    func readPlaylistValue() {
        bluejay.run { sandsaraBoard -> Bool in
            do {
                let selectedPalette: String = try sandsaraBoard.read(from: PlaylistService.playlistName)
                print("Current playlist \(selectedPalette)")
                self.currentPlaylistName.accept(selectedPalette)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let selectedPalette: String = try sandsaraBoard.read(from: PlaylistService.pathName)
                print("Current track \(selectedPalette)")
                self.currentPath.accept(selectedPalette)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            do {
                let selectedPalette: String = try sandsaraBoard.read(from: PlaylistService.pathPosition)
                print("Current position \(selectedPalette)")
                self.currentPath.accept(selectedPalette)
            } catch(let error) {
                print(error.localizedDescription)
            }
            return false
        } completionOnMainThread: { result in
            debugPrint(result)
        }
    }
}
