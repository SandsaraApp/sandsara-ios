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
