//
//  PlayerViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class PlayerViewController: BaseVMViewController<PlayerViewModel, NoInputParam> {


    static var shared: PlayerViewController = {
        let playerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: PlayerViewController.identifier) as! PlayerViewController
        return playerVC
    }()

    @IBOutlet private weak var tableView: UITableView!

    var selecledIndex = BehaviorRelay<Int>(value: 0)
    var tracks = [DisplayItem]()
    var isReloaded = false

    var playlistItem: DisplayItem?

    typealias Section = SectionModel<String, TrackCellViewModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()

    override func viewDidLoad() {
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isReloaded {
            tableView.dataSource = nil
            tableView.delegate = nil
            setupViewModel()
            bindViewModel()
            viewModel.viewModelDidBind()
            isReloaded = false
            if let item = playlistItem {
                viewModel.playFromDownloadedPlaylist(item: item)
            } else {
                FileServiceImpl.shared.updateTrack(name: self.tracks[selecledIndex.value].fileName)
            }
        }
    }

    override func setupViewModel() {
        viewModel = PlayerViewModel(inputs: PlayerViewModelContract.Input(selectedIndex: selecledIndex, tracks: tracks))
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }

    override func bindViewModel() {
        viewModel.outputs.datasources.filter { !$0.isEmpty }.map {
            [Section(model: "", items: $0)]
        }
        .doOnNext { [weak self] in
            if !$0.isEmpty {
                self?.tableView.scrollsToTop = true
            }
        }
        .drive(tableView.rx.items(dataSource: makeDataSource())).disposed(by: disposeBag)

        viewModel.outputs.trackDisplay.compactMap { $0 }.driveNext { [weak self] track in
            (self?.tableView.headerView(forSection: 0) as? PlayerHeaderView)?.reloadHeaderCell(trackDisplay: Driver.just(track))
        }.disposed(by: disposeBag)

        Observable
            .zip(
                tableView.rx.itemSelected,
                tableView.rx.modelSelected(TrackCellViewModel.self)
            ).bind { [weak self] indexPath, model in
                guard let self = self else { return }
                self.selecledIndex.accept(indexPath.row)
            }.disposed(by: disposeBag)
    }

    private func setupTableView() {
        tableView.backgroundColor = Asset.background.color
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(TrackTableViewCell.nib, forCellReuseIdentifier: TrackTableViewCell.identifier)
        tableView.register(PlayerHeaderView.nib, forHeaderFooterViewReuseIdentifier: PlayerHeaderView.identifier)
        tableView.contentInset = UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.identifier, for: indexPath) as? TrackTableViewCell else { return UITableViewCell()}
                cell.bind(to: viewModel)
                return cell
            })
    }

}

extension PlayerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlayerHeaderView.identifier) as! PlayerHeaderView
        headerView.reloadHeaderCell(trackDisplay: Driver.just(tracks[selecledIndex.value]))
        headerView.backBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.popupPresentationContainer?.closePopup(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        return headerView
    }
}
