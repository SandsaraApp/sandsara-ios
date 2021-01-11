//
//  BrowseTrackViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 07/01/2021.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa

class BrowseTrackViewController: BaseVMViewController<AllTracksViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet weak var noResultView: UIStackView!
    let viewWillAppearTrigger = PublishRelay<()>()

    var mode: ControllerMode = .search

    typealias Section = SectionModel<String, AllTrackCellVM>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()

    var playlistTitle: String?

    let syncAll = PublishRelay<()>()

    let searchTrigger = PublishRelay<String>()

    override func setupViewModel() {
        setupTableView()
        isPlaySingle = true
        viewModel = AllTracksViewModel(apiService: SandsaraDataServices(), inputs: AllTracksViewModelContract.Input(mode: mode, viewWillAppearTrigger: viewWillAppearTrigger, syncAll: syncAll, searchTrigger: searchTrigger))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearTrigger.accept(())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func bindViewModel() {
        viewModel
            .outputs.datasources
            .map { [Section(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        tableView.rx.itemSelected.subscribeNext { [weak self] indexPath in
            guard let self = self else { return }
            if indexPath.row != 0 {
                self.openTrackDetail(index: indexPath.row)
            }
        }.disposed(by: disposeBag)

        viewModel.isLoading
            .drive(loadingActivity.rx.isAnimating)
            .disposed(by: disposeBag)
    }

    private func setupTableView() {
        tableView.backgroundColor = Asset.background.color
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(TrackTableViewCell.nib, forCellReuseIdentifier: TrackTableViewCell.identifier)
        tableView.register(TrackCountTableViewCell.nib, forCellReuseIdentifier: TrackCountTableViewCell.identifier)
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                switch viewModel {
                case .header(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackCountTableViewCell.identifier, for: indexPath) as? TrackCountTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    cell.playlistTrigger
                        .bind(to: self.syncAll)
                        .disposed(by: cell.disposeBag)
                    return cell
                case .track(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.identifier, for: indexPath) as? TrackTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                }
            })
    }

    private func openTrackDetail(index: Int) {
        let trackList = self.storyboard?.instantiateViewController(withIdentifier: TrackDetailViewController.identifier) as! TrackDetailViewController
        switch viewModel.datas.value[index] {
        case .track(let viewModel):
            trackList.track = viewModel.inputs.track
            trackList.tracks = [viewModel.inputs.track]
        default:
            break
        }

        trackList.selecledIndex = index - 1
        self.navigationController?.pushViewController(trackList, animated: true)
    }
}

extension BrowseTrackViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.0
    }
}