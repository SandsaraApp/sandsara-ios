//
//  AllTrackViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa

class AllTrackViewController: BaseVMViewController<AllTracksViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!

    let viewWillAppearTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, AllTrackCellVM>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()

    var playlistTitle: String?

    override func setupViewModel() {
        setupTableView()
        viewModel = AllTracksViewModel(apiService: SandsaraDataServices(), inputs: AllTracksViewModelContract.Input(viewWillAppearTrigger: viewWillAppearTrigger))
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
            trackList.tracks = self.viewModel.datas.value.map {
                switch $0 {
                case .track(let vm): return vm.inputs.track
                default: return nil
                }
            }.compactMap { $0 }
        default:
            break
        }

        trackList.selecledIndex = index - 1
        self.navigationController?.pushViewController(trackList, animated: true)
    }
}

extension AllTrackViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 50.0
        }
        return 96.0
    }
}
