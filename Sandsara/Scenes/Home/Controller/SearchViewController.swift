//
//  SearchViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 07/01/2021.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class SearchViewController: BaseViewController<NoInputParam>, UISearchControllerDelegate {

    @IBOutlet weak var segmentControl: CustomSegmentControl!
    @IBOutlet weak var containerView: UIView!

    private let sc = UISearchController(searchResultsController: nil)

    private var allTrackVC: BrowseTrackViewController?
    private var playlistsVC: BrowsePlaylistViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSearchBar()
        initControllers()
        setupSegment()
        navigationItem.hidesBackButton = true
        sc.delegate = self
        sc.isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }


    private func setUpSearchBar() {
        sc.dimsBackgroundDuringPresentation = false
        searchBarStyle(sc.searchBar)
        navigationItem.searchController = sc

        sc.searchBar
            .rx
            .text
            .orEmpty
            .asObservable()
            .throttle(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribeNext { text in
                if !text.isEmpty {
                    self.playlistsVC?.searchTrigger.accept(text)
                    self.allTrackVC?.searchTrigger.accept(text)
                }
            }
            .disposed(by: disposeBag)

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

    private func setupSegment() {
        segmentControl.setStyle(font: FontFamily.Tinos.regular.font(size: 30), titles:  [L10n.tracks, L10n.playlists])

        segmentControl
            .segmentSelected
            .observeOn(MainScheduler.instance)
            .subscribeNext { [weak self] index in
                self?.updateControllersByIndex(i: index)
            }
            .disposed(by: disposeBag)
    }

    private func initControllers() {
        allTrackVC = storyboard?.instantiateViewController(withIdentifier: BrowseTrackViewController.identifier) as? BrowseTrackViewController
        playlistsVC = storyboard?.instantiateViewController(withIdentifier: BrowsePlaylistViewController.identifier) as? BrowsePlaylistViewController
        addChildViewController(controller: allTrackVC!, containerView: containerView, byConstraints: true)
    }

    func updateControllersByIndex(i: Int) {
        self.removeAllChildViewController()
        if i == 0 {
            addChildViewController(controller: allTrackVC!, containerView: containerView, byConstraints: true)
            allTrackVC?.viewWillAppearTrigger.accept(())
        } else {
            addChildViewController(controller: playlistsVC!, containerView: containerView, byConstraints: true)
            playlistsVC?.viewWillAppearTrigger.accept(())
        }
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        sc.searchBar.becomeFirstResponder()
    }
    
}