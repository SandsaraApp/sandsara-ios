//
//  FileServiceImpl.swift
//  Sandsara
//
//  Created by Tín Phan on 30/11/2020.
//

import Foundation
import Bluejay
import RxCocoa
import RxSwift

class FileServiceImpl {
    static let shared = FileServiceImpl()

    let seconds = PublishRelay<TimeInterval>()

    let disposeBag = DisposeBag()

    func sendFiles(fileName: String,
                   extensionName: String) {
        let start = CFAbsoluteTimeGetCurrent()
        bluejay.run { sandsaraBoard -> Bool in
            if let bytes: [[UInt8]] = self.getFile(forResource: fileName, withExtension: extensionName) {
                do {
                    try sandsaraBoard.write(to: FileService.sendFileFlag, value: fileName)
                    for i in 0 ..< bytes.count {
                        try sandsaraBoard.writeAndListen(writeTo: FileService.sendBytes, value: Data(bytes: bytes[i], count: bytes[i].count), listenTo: FileService.sendBytes, completion: { (result: UInt8) -> ListenAction in
                            let start1 = CFAbsoluteTimeGetCurrent()
                            let diff = CFAbsoluteTimeGetCurrent() - start1
                            print("Send chunks took \(diff) seconds")
                            return .done
                        })
                    }
                } catch(let error) {
                    debugPrint(error.localizedDescription)
                }

            }
            return false
        } completionOnMainThread: { result in
            switch result {
            case .success:
                debugPrint("send success")
                bluejay.write(to: FileService.sendFileFlag, value: "completed") { result in
                    switch result {
                    case .success:
                        debugPrint("Send file success")
                        let diff = CFAbsoluteTimeGetCurrent() - start
                        print("Took \(diff) seconds")
                        self.seconds.accept(diff)
                    case .failure(let error):
                        debugPrint("Send file error \(error.localizedDescription)")
                    }
                }
            case .failure:
                debugPrint("send error")
            }
        }
    }

    func getFile(forResource resource: String,
                 withExtension fileExt: String?) -> [[UInt8]]? {
        var chunks = [[UInt8]]()
        // See if the file exists.
        guard let filePath = Bundle.main.path(forResource: resource, ofType: fileExt) else {
            return nil
        }

        if let stream = InputStream(fileAtPath: filePath) {
            var buf = [UInt8](repeating: 0, count: 512)
            stream.open()

            while case let amount = stream.read(&buf, maxLength: 512), amount > 0 {
                // print(amount)
                chunks.append(Array(buf[..<amount]))
            }
            stream.close()
        }
        return chunks
    }
}
