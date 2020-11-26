//
//  SettingsViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import Bluejay

extension Array {
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

class SettingsViewController: BaseVMViewController<SettingViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var testButton: UIBarButtonItem!

    private let viewWillAppearTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, SettingItemCellType>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()


    private var cellHeightsDictionary: [IndexPath: CGFloat] = [:]

    private var documentPicker: DocumentPicker?

    override func setupViewModel() {
        setupTableView()
        viewModel = SettingViewModel(inputs: SettingViewModelContract.Input(viewWillAppearTrigger: viewWillAppearTrigger))
        viewWillAppearTrigger.accept(())

        documentPicker = DocumentPicker(presentationController: self, delegate: self)
    }

    override func bindViewModel() {
        viewModel
            .outputs.datasources
            .map { [Section(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        testButton.rx.tap.asDriver().driveNext {
           self.readBinFile()
        }.disposed(by: disposeBag)
    }

    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()

        tableView.register(ProgressTableViewCell.nib, forCellReuseIdentifier: ProgressTableViewCell.identifier)
        tableView.register(ToogleTableViewCell.nib, forCellReuseIdentifier: ToogleTableViewCell.identifier)
        tableView.register(MenuTableViewCell.nib, forCellReuseIdentifier: MenuTableViewCell.identifier)
        tableView.register(TwoTableViewCell.nib, forCellReuseIdentifier: TwoTableViewCell.identifier)

        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { [weak self] (_, tableView, indexPath, modelType) -> UITableViewCell in
                switch modelType {
                case .speed(let viewModel), .brightness(let viewModel), .lightTemp(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: ProgressTableViewCell.identifier, for: indexPath) as? ProgressTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                case .pause(let viewModel), .lightMode(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: ToogleTableViewCell.identifier, for: indexPath) as? ToogleTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                case .colorSettings(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoTableViewCell.identifier, for: indexPath) as? TwoTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                case .draw(let viewModel), .advanced(let viewModel), .visitSandsara(let viewModel), .help(let viewModel), .sleep(let viewModel), .firmwareUpdate(let viewModel), .nightMode(let viewModel), .disconnect(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier, for: indexPath) as? MenuTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                }
            })
    }

    private func readBinFile() {
        let start = CFAbsoluteTimeGetCurrent()
        var isSendCompleted: Bool = false
        var isSendError: Bool = false

        bluejay.run { sandsaraBoard -> Bool in
            if let bytes: [[UInt8]] = self.getFile(forResource: "proof", withExtension: "bin") {
                do {
                    try sandsaraBoard.write(to: sendFileFlag, value: "proof")
                    for i in 0 ..< bytes.count {
                        //let semaphore = DispatchSemaphore(value: i)
                        
                        try sandsaraBoard.writeAndListen(writeTo: sendBytes, value: Data(bytes: bytes[i], count: bytes[i].count), listenTo: sendBytes, completion: { (result: UInt8) -> ListenAction in
                            // semaphore.signal()
                            let start1 = CFAbsoluteTimeGetCurrent()
                            let diff = CFAbsoluteTimeGetCurrent() - start1
                            print("Send chunks took \(diff) seconds")
                            return .done
                        })
//                        semaphore.wait()
//                        i = i + 1
                    }
                } catch(let error) {
                    debugPrint(error.localizedDescription)
                }

            }
            return false
        } completionOnMainThread: { result in
            switch result {
            case .success(let value):
                isSendCompleted = true
                debugPrint("send success")
                bluejay.write(to: sendFileFlag, value: "completed") { result in
                    switch result {
                    case .success:
                        debugPrint("Send file success")
                        let diff = CFAbsoluteTimeGetCurrent() - start
                        print("Took \(diff) seconds")
                        self.showAlertVC(message: "Took \(diff) seconds")
                    case .failure(let error):
                        debugPrint("Send file error \(error.localizedDescription)")
                    }
                }
            case .failure(let value):
                isSendError = true
                debugPrint("send error")
            }
        }
    }

    func measureTime(for closure: @autoclosure () -> Any) {
        let start = CFAbsoluteTimeGetCurrent()
        closure()
        let diff = CFAbsoluteTimeGetCurrent() - start
        print("Took \(diff) seconds")
    }

    func getFile(forResource resource: String, withExtension fileExt: String?) -> [[UInt8]]? {
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

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeightsDictionary[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightsDictionary[indexPath] ?? UITableView.automaticDimension
    }
}

extension SettingsViewController: DocumentDelegate {
    func didPickDocument(document: Document?) {
        print(document?.fileSize)
    }
}
