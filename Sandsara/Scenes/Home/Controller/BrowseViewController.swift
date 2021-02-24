//
//  BrowseViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/8/20.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources

class BrowseViewController: BaseVMViewController<BrowseViewModel, NoInputParam>, UISearchBarDelegate {

    @IBOutlet private weak var tableView: UITableView!  {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.register(RecommendTableViewCell.nib,
                               forCellReuseIdentifier: RecommendTableViewCell.identifier)
            tableView.backgroundColor = Asset.background.color
            tableView
                .rx.setDelegate(self)
                .disposed(by: disposeBag)

            tableView.separatorStyle = .none
        }
    }

    @IBOutlet weak var searchView: UIView!
    private let sc = UISearchController(searchResultsController: nil)
    private var viewWillAppearTrigger = PublishRelay<()>()
    private var inputTrigger = BehaviorRelay<String?>(value: nil)
    private var cancelSearchTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, RecommendTableViewCellViewModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()
    private var cellHeightsDictionary: [IndexPath: CGFloat] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSearchBar()
        viewWillAppearTrigger.accept(())
        sc.searchBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goSearchVC)))
        sc.searchBar.isUserInteractionEnabled = true
        sc.searchBar.delegate = self
        DeviceServiceImpl.shared.readSensorValues()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateControllers), name: reloadTab, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            once.run {
                defer {
                    if !bluejay.isConnected {
                        showConnectionVC()
                    }
                }
                delegate.initPlayerBar()
            }
        }
    }

    @objc func goSearchVC() {
        let vc = storyboard?.instantiateViewController(withIdentifier: SearchViewController.identifier) as! SearchViewController
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func updateControllers() {
        if !DeviceServiceImpl.shared.currentTracks.isEmpty {
            DispatchQueue.main.async {
                let player = PlayerViewController.shared
                player.modalPresentationStyle = .fullScreen
                player.index = DeviceServiceImpl.shared.currentTrackIndex
                player.tracks = DeviceServiceImpl.shared.currentTracks
                player.playlistItem = DisplayItem(playlist: Playlist(id: "1", title: DeviceServiceImpl.shared.currentPlaylistName.value, thumbnail: [], author: ""))
                player.queues = Array(player.tracks[player.index + 1 ..< player.tracks.count]) + Array(player.tracks[0 ..< player.index])
                player.playlingState = .showOnly
                player.isReloaded = true
                player.showTrack(at: player.index)
                (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .haveTrack(displayItem: player.tracks[DeviceServiceImpl.shared.currentTrackIndex])
                player.progress.accept(DeviceServiceImpl.shared.currentTrackPosition.value)
                UIApplication.topViewController()?.tabBarController?.popupBar.isHidden = false
                UIApplication.topViewController()?.tabBarController?.popupContentView.popupCloseButton.isHidden = true
                UIApplication.topViewController()?.tabBarController?.presentPopupBar(withContentViewController: player, openPopup: false, animated: false, completion: nil)
            }
        } else {
            DispatchQueue.main.async {
                (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = DeviceServiceImpl.shared.status.value == .calibrating ? .calibrating : .connected
            }
        }
    }

    override func setupViewModel() {
        viewModel = BrowseViewModel(apiService: SandsaraDataServices(),
                                    inputs: BrowseVMContract.Input(searchText: inputTrigger,
                                                                   cancelSearch: cancelSearchTrigger,
                                                                   viewWillAppearTrigger: viewWillAppearTrigger))
    }

    override func bindViewModel() {
        viewModel
            .outputs
            .datasources
            .map {
                 [Section(model: "", items: $0)]
            }.drive(tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)

        viewModel.isLoading
            .drive(loadingActivity.rx.isAnimating)
            .disposed(by: disposeBag)
    }

    private func setUpSearchBar() {
        sc.dimsBackgroundDuringPresentation = false
        searchBarStyle(sc.searchBar)
        navigationItem.searchController = sc
    }

    @objc func hideKeyboard() {
        sc.searchBar.endEditing(true)
        sc.isActive = false
    }

    private func searchBarStyle(_ searchBar: UISearchBar) {
        searchBar.placeholder = "Search"
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        let textFieldInsideSearchBarLabel = textFieldInsideSearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideSearchBarLabel?.textColor = Asset.primary.color
        if let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField,
           let glassIconView = textFieldInsideSearchBar.leftView as? UIImageView {
            glassIconView.image = Asset.smallSearch.image
            glassIconView.image = glassIconView.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            glassIconView.tintColor = Asset.primary.color
            textFieldInsideSearchBar.backgroundColor = UIColor(red: 0.062, green: 0.062, blue: 0.062, alpha: 1)
        }

        extendedLayoutIncludesOpaqueBars = true
        searchBar.tintColor = Asset.primary.color
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: RecommendTableViewCell.identifier, for: indexPath) as? RecommendTableViewCell else { return UITableViewCell()}
                cell.bind(to: viewModel)
                cell.selectedCell.subscribeNext { [weak self] index, item in
                    self?.goDetail(item: item, index: index, viewModel: viewModel)
                }.disposed(by: cell.disposeBag)
                return cell
            })
    }

    private func goDetail(item: DisplayItem, index: Int, viewModel: RecommendTableViewCellViewModel) {
        if item.isPlaylist {
            let trackList = self.storyboard?.instantiateViewController(withIdentifier: TrackListViewController.identifier) as! TrackListViewController
            trackList.playlistItem = item
            navigationController?.pushViewController(trackList, animated: true)
        } else {
            let trackDetail = self.storyboard?.instantiateViewController(withIdentifier: TrackDetailViewController.identifier) as! TrackDetailViewController
            trackDetail.track = item
            trackDetail.tracks = [item]
            navigationController?.pushViewController(trackDetail, animated: true)
        }
    }

    override func triggerAPIAgain() {
        self.showAlert(title: "Alert", message: "No Internet Connection", preferredStyle: .alert, actions:
                        UIAlertAction(title: "Try Again", style: .default, handler: { _ in
                            self.viewWillAppearTrigger.accept(())
                        }),
                       UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        )
    }

    private func showConnectionVC() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: ConnectionGuideViewController.identifier) as! ConnectionGuideViewController
        let navVC = UINavigationController(rootViewController: vc)
        UIApplication.topViewController()?.tabBarController?.present(navVC, animated: true, completion: nil)
    }

    private func showSearch(isShow: Bool) {
        tableView.isHidden = isShow
        tableView.alpha = isShow ? 0 : 1
        searchView.isHidden = !isShow
        searchView.alpha = isShow ? 1 : 0
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        goSearchVC()
        return false
    }
}

extension BrowseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeightsDictionary[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightsDictionary[indexPath] ?? UITableView.automaticDimension
    }
}
