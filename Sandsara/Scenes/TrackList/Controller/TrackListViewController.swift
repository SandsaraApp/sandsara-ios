//
//  TrackListViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Moya

class TrackListViewController: BaseVMViewController<TrackListViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!

    private let viewWillAppearTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, TrackCellViewModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()

    var playlistTitle: String?

    override func setupViewModel() {
        
        setupTableView()
        viewModel = TrackListViewModel(apiService: SandsaraAPIService(apiProvider: MoyaProvider<SandsaraAPI>()), inputs: TrackListViewModelContract.Input(viewWillAppearTrigger: viewWillAppearTrigger))
        viewWillAppearTrigger.accept(())
    }

    override func bindViewModel() {
        viewModel
            .outputs.datasources
            .map { [Section(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        tableView.rx.itemSelected.subscribeNext { [weak self] indexPath in
                guard let self = self else { return }
            self.openTrackDetail(index: indexPath.row)
            }.disposed(by: disposeBag)
    }

    private func setupTableView() {
        tableView.backgroundColor = Asset.background.color
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(TrackTableViewCell.nib, forCellReuseIdentifier: TrackTableViewCell.identifier)
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)

        tableView?.register(HeaderView.nib,
                            forHeaderFooterViewReuseIdentifier: HeaderView.identifier)
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.identifier, for: indexPath) as? TrackTableViewCell else { return UITableViewCell()}
                cell.bind(to: viewModel)
                return cell
            })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func openTrackDetail(index: Int) {
        let trackList = self.storyboard?.instantiateViewController(withIdentifier: TrackDetailViewController.identifier) as! TrackDetailViewController
        trackList.track = DisplayItem.init(trackCellViewModel: viewModel.datas.value[index])
        trackList.tracks = self.viewModel.datas.value.map { $0.inputs.track }
        trackList.selecledIndex = index
        self.navigationController?.pushViewController(trackList, animated: true)
    }

    private func openPlayer(index: Int) {
        let player = self.storyboard?.instantiateViewController(withIdentifier: PlayerViewController.identifier) as! PlayerViewController
        player.modalPresentationStyle = .fullScreen
        player.selecledIndex.accept(index)
        player.tracks = self.viewModel.datas.value.map { $0.inputs.track }
        self.present(player, animated: true, completion: nil)
    }
}

extension TrackListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 390.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderView.identifier) as? HeaderView
        headerView?.section = section
        headerView?.playButton.rx.tap.asDriver().driveNext {
            self.openPlayer(index: 0)
        }.disposed(by: disposeBag)
        headerView?.backButtton.rx.tap.asDriver().driveNext {
            self.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
        return headerView
    }
}
