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

    let sendSuccess = PublishRelay<Bool>()

    let fileExist = PublishRelay<Bool>()

    var chunks = [Int]()

    var originChunks = [Int]()

    let disposeBag = DisposeBag()

    func sendFiles(fileName: String,
                   extensionName: String, isPlaylist: Bool = false) {
        // reset value
        sendSuccess.accept(false)
        fileExist.accept(false)
        let start = CFAbsoluteTimeGetCurrent()
        bluejay.run { sandsaraBoard -> Bool in
            if let bytes: [[UInt8]] = self.getFile(forResource: fileName, withExtension: extensionName, isPlaylist: isPlaylist) {
                self.originChunks = [Int].init(repeating: 0, count: bytes.count)
                do {
                    try sandsaraBoard.write(to: FileService.sendFileFlag, value: fileName)
                    for i in 0 ..< bytes.count {
                        do {
                            try sandsaraBoard.write(to: FileService.sendBytes, value: Data(bytes: bytes[i], count: bytes[i].count))
                        } catch(let error) {
                            if error.localizedDescription.isEmpty {
                                self.chunks.append(i)
                            }
                        }
                    }
                } catch(let error) {
                    debugPrint(error.localizedDescription)
                }
                return false
            }
            return false
        } completionOnMainThread: { result in
            switch result {
            case .success:
                self.fileExist.subscribeNext {
                    if $0 {
                        debugPrint("File exist")
                    }
                }.disposed(by: self.disposeBag)

                if self.originChunks.count == self.chunks.count {
                    bluejay.write(to: FileService.sendFileFlag, value: "completed") { result in
                        switch result {
                        case .success:
                            debugPrint("Send file success")
                            let diff = CFAbsoluteTimeGetCurrent() - start
                            print("Took \(diff) seconds")
                            self.seconds.accept(diff)
                            self.sendSuccess.accept(true)
                            if isPlaylist {
                                self.updatePlaylist(fileName: fileName)
                            }
                        case .failure(let error):
                            self.sendSuccess.accept(false)
                            debugPrint("Send file error \(error.localizedDescription)")
                        }
                    }
                }
            case .failure:
                debugPrint("send error")
            }
        }
    }

    func getFile(forResource resource: String,
                 withExtension fileExt: String?, isPlaylist: Bool = false) -> [[UInt8]]? {
        var chunks = [[UInt8]]()
        // See if the file exists.
        var filePath = ""

        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("\(resource).\(fileExt ?? "")") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                if let stream = InputStream(fileAtPath: filePath) {
                    var buf = [UInt8](repeating: 0, count: 512)
                    stream.open()

                    while case let amount = stream.read(&buf, maxLength: 512), amount > 0 {
                        chunks.append(Array(buf[..<amount]))
                    }
                    stream.close()
                }
            }
        }
        return chunks
    }

    func createOrOverwriteEmptyFileInDocuments(filename: String) {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("ERROR IN createOrOverwriteEmptyFileInDocuments")
            return
        }
        let fileURL = dir.appendingPathComponent(filename)
        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
        }
        catch {
            debugPrint("ERROR WRITING STRING: " + error.localizedDescription)
        }
        debugPrint("FILE CREATED: " + fileURL.absoluteString)
    }

    func writeString(string: String, fileHandle: FileHandle){
        let data = string.data(using: String.Encoding.utf8)
        guard let dataU = data else {
            debugPrint("ERROR WRITING STRING: " + string)
            return
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(dataU)
    }


    private func readFile(filename: String) -> String? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("ERROR OPENING FILE")
            return nil
        }
        let fileURL = dir.appendingPathComponent(filename)

        return fileURL.absoluteString
    }

    func existingFile(fileName: String) -> (Bool, UInt64) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("\(fileName)") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                if let size = getSizeOfFile(withPath: filePath) {
                    return (true, size)
                }
                return (true, 0)
            } else {
                return (false, 0)
            }
        } else {
            return (false, 0)

        }
    }

    private func getSizeOfFile(withPath path:String) -> UInt64? {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: path)
            if let fileSize = fileAttributes[FileAttributeKey.size]  {
                return (fileSize as! NSNumber).uint64Value
            } else {
                print("Failed to get a size attribute from path: \(path)")
            }
        } catch {
            print("Failed to get file attributes for local path: \(path) with error: \(error)")
        }
        return 0
    }

    func getHandleForFileInDocuments(filename: String)->FileHandle? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("ERROR OPENING FILE")
            return nil
        }
        let fileURL = dir.appendingPathComponent(filename)
        do {
            let fileHandle: FileHandle? = try FileHandle(forWritingTo: fileURL)
            return fileHandle
        }
        catch {
            debugPrint("ERROR OPENING FILE: " + error.localizedDescription)
            return nil
        }
    }

    func updatePlaylist(fileName: String) {
        bluejay.write(to: PlaylistService.playlistName, value: fileName) { result in
            switch result {
            case .success:
                debugPrint("Play success")
                DeviceServiceImpl.shared.readPlaylistValue()
            case .failure(let error):
                debugPrint("Play error")
            }
        }
    }

    func updateTrack(name: String) {
        bluejay.write(to: PlaylistService.pathName, value: name) { result in
            switch result {
            case .success:
                debugPrint("Play success")
                DeviceServiceImpl.shared.readPlaylistValue()
            case .failure(let error):
                debugPrint("Play error")
            }
        }
    }
}
