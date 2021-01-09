//
//  LedStripServiceImpl.swift
//  Sandsara
//
//  Created by Tín Phan on 30/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

extension StringProtocol {
    var data: Data { .init(utf8) }
    var bytes: [UInt8] { .init(utf8) }
}

class LedStripServiceImpl {
    static let shared = LedStripServiceImpl()

    func uploadCustomPalette(amoutColors: String, postions: String, red: String, blue: String, green: String) {
        var step = 0
        bluejay.run { sandsaraBoard -> Bool in
            do {
                try sandsaraBoard.write(to: LedStripService.amountOfColors, value: amoutColors)
                step += 1

                print("step \(step)")

            } catch(let error) {
                print(error.localizedDescription)
            }
            do {
                try sandsaraBoard.write(to: LedStripService.positions, value: postions)

                step += 1

                print("step \(step)")

            } catch(let error) {
                print(error.localizedDescription)
            }

            do {
                try sandsaraBoard.write(to: LedStripService.red, value: red)

                step += 1

                print("step \(step)")

            } catch(let error) {
                print(error.localizedDescription)
            }

            do {
                try sandsaraBoard.write(to: LedStripService.green, value: green)
                step += 1

                print("step \(step)")

            } catch(let error) {
                print(error.localizedDescription)
            }

            do {
                try sandsaraBoard.write(to: LedStripService.blue, value: blue)

                step += 1

                print("step \(step)")

            } catch(let error) {
                print(error.localizedDescription)
            }

            do {
                try sandsaraBoard.write(to: LedStripService.uploadCustomPalette, value: "1")

                step += 1

                print("step \(step)")

            } catch(let error) {
                print(error.localizedDescription)
            }

            return false
        } completionOnMainThread: { result in
            debugPrint(result)

            switch result {
            case .success:
                bluejay.write(to: LedStripService.selectPattle, value: "16") { result in
                    switch result {
                    case .success:
                        var colorModel = ColorModel()
                        var reds = [Float]()
                        var blues = [Float]()
                        var greens = [Float]()
                        var positions = [Int]()
                        reds = red.components(separatedBy: ",").map { Float($0) ?? 0.0 }
                        blues = blue.components(separatedBy: ",").map { Float($0) ?? 0.0 }
                        greens = green.components(separatedBy: ",").map { Float($0) ?? 0.0 }
                        positions = postions.components(separatedBy: ",").map { Int($0) ?? 0 }

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
                        DeviceServiceImpl.shared.runningColor.accept(colorModel)
                        
                        debugPrint("Write to sensor location is successful.\(result)")
                    case .failure(let error):
                        debugPrint("Failed to write sensor location with error: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
