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

class TrackListViewController: BaseVMViewController<TrackListViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!

    private let viewWillAppearTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, PlaylistDetailCellVM>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()

    var playlistItem: DisplayItem?

    private var cellHeightsDictionary: [IndexPath: CGFloat] = [:]

    override func setupViewModel() {
        
        setupTableView()
        viewModel = TrackListViewModel(apiService: SandsaraDataServices(), inputs: TrackListViewModelContract.Input(playlistItem: playlistItem ?? DisplayItem() , viewWillAppearTrigger: viewWillAppearTrigger))
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
    }

    private func setupTableView() {
        tableView.backgroundColor = Asset.background.color
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(TrackTableViewCell.nib, forCellReuseIdentifier: TrackTableViewCell.identifier)
        tableView.register(PlaylistHeaderTableViewCell.nib, forCellReuseIdentifier: PlaylistHeaderTableViewCell.identifier)
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                switch viewModel {
                case .header(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistHeaderTableViewCell.identifier, for: indexPath) as? PlaylistHeaderTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    cell.playAction.asObservable().subscribeNext {
                        self.openPlayer(index: 0)
                    }.disposed(by: cell.disposeBag)
                    cell.backAction.asObservable().subscribeNext {
                        self.navigationController?.popViewController(animated: true)
                    }.disposed(by: cell.disposeBag)
                    return cell
                case .track(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.identifier, for: indexPath) as? TrackTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                }

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

        trackList.selecledIndex = index
        self.navigationController?.pushViewController(trackList, animated: true)
    }

    private func openPlayer(index: Int) {
        let player = PlayerViewController.shared
        player.modalPresentationStyle = .fullScreen
        player.selecledIndex.accept(index)
        player.tracks = self.viewModel.datas.value.map {
            switch $0 {
            case .track(let vm): return vm.inputs.track
            default: return nil
            }
        }.compactMap { $0 }
        player.isReloaded = true
        (tabBarController?.popupBar.customBarViewController as! PlayerBarViewController).state = .haveTrack(displayItem: player.tracks[index])
        tabBarController?.popupBar.isHidden = false
        tabBarController?.popupContentView.popupCloseButton.isHidden = true
        tabBarController?.presentPopupBar(withContentViewController: player, openPopup: true, animated: false, completion: nil)
    }
}

extension TrackListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeightsDictionary[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightsDictionary[indexPath] ?? UITableView.automaticDimension
    }
}
