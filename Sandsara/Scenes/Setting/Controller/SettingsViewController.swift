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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationBar(largeTitleColor: Asset.primary.color, backgoundColor: Asset.background.color, tintColor: Asset.primary.color, title: L10n.settings, preferredLargeTitle: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.title = " "
    }

    override func setupViewModel() {
        setupTableView()
        viewModel = SettingViewModel(inputs: SettingViewModelContract.Input(viewWillAppearTrigger: viewWillAppearTrigger))
        viewWillAppearTrigger.accept(())
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

        Observable
            .zip(
                tableView.rx.itemSelected,
                tableView.rx.modelSelected(SettingItemCellType.self)
            ).bind { [weak self] indexPath, model in
                guard let self = self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)
                switch model {
                case .menu(let viewModel):
                    switch viewModel.inputs.type {
                    case .visitSandsara:
                        UIApplication.shared.open(URL(string: "https://www.kickstarter.com/projects/edcano/sandsara")!, options: [:], completionHandler: nil)
                    case .advanced:
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: AdvanceSettingViewController.identifier) as! AdvanceSettingViewController
                        self.navigationController?.pushViewController(vc, animated: true)
                    default:
                        break
                    }
                default: break
                }
            }.disposed(by: disposeBag)
    }

    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()

        tableView.register(ProgressTableViewCell.nib, forCellReuseIdentifier: ProgressTableViewCell.identifier)
        tableView.register(MenuTableViewCell.nib, forCellReuseIdentifier: MenuTableViewCell.identifier)
        tableView.register(PresetsTableViewCell.nib, forCellReuseIdentifier: PresetsTableViewCell.identifier)

        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 73

        tableView.register(SettingHeaderView.nib, forHeaderFooterViewReuseIdentifier: SettingHeaderView.identifier)
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { [weak self] (_, tableView, indexPath, modelType) -> UITableViewCell in
                switch modelType {
                case .speed(let viewModel), .brightness(let viewModel), .lightCycleSpeed(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: ProgressTableViewCell.identifier, for: indexPath) as? ProgressTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                case .menu(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier, for: indexPath) as? MenuTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                case .presets(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: PresetsTableViewCell.identifier, for: indexPath) as? PresetsTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                }

            })
    }

    private func readBinFile() {
        let start = CFAbsoluteTimeGetCurrent()

        bluejay.run { sandsaraBoard -> Bool in
            if let bytes: [[UInt8]] = self.getFile(forResource: "proof", withExtension: "bin") {
                do {
                    try sandsaraBoard.write(to: sendFileFlag, value: "proof")
                    for i in 0 ..< bytes.count {
                        try sandsaraBoard.writeAndListen(writeTo: sendBytes, value: Data(bytes: bytes[i], count: bytes[i].count), listenTo: sendBytes, completion: { (result: UInt8) -> ListenAction in
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

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeightsDictionary[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightsDictionary[indexPath] ?? UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SettingHeaderView.identifier) as? SettingHeaderView
        headerView?.titleLabel.text = L10n.basicSetting
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 73
    }
}
