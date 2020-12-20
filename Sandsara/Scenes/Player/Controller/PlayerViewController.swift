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

class PlayerViewController: BaseViewController<NoInputParam> {
    static var shared: PlayerViewController = {
        let playerVC = UIStoryboard(name: "Main",
                                    bundle: nil)
            .instantiateViewController(withIdentifier: PlayerViewController.identifier)
            as! PlayerViewController
        return playerVC
    }()

    @IBOutlet private weak var tableView: UITableView!
    var index: Int = 0
    var tracks = [DisplayItem]()
    var queues = [DisplayItem]()

    var sliderValue: Float = 0.0

    var currentTrack = DisplayItem()

    var isReloaded = false

    var playingTrackCount = 0

    var playlistItem: DisplayItem?

    var nowPlayingQueues = [DisplayItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isReloaded {
            isReloaded = false
            if let item = playlistItem {
                playFromDownloadedPlaylist(item: item)
                showTrack(at: index)
            } else {
                showTrack(at: index)
                playTrack(at: index)
            }
        }
    }

    private func setupTableView() {
        tableView.backgroundColor = Asset.background.color
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(TrackTableViewCell.nib, forCellReuseIdentifier: TrackTableViewCell.identifier)
        tableView.register(PlayerHeaderView.nib, forHeaderFooterViewReuseIdentifier: PlayerHeaderView.identifier)
        tableView.register(PlayerFooterView.nib, forHeaderFooterViewReuseIdentifier: PlayerFooterView.identifier)
        tableView.contentInset = UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension PlayerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return playingTrackCount > 0 ? 96.0 : 0.0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 400
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 184
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlayerHeaderView.identifier) as! PlayerHeaderView
        headerView.reloadHeaderCell(trackDisplay: Driver.just(currentTrack),
                                    trackCount: Driver.just(playingTrackCount))
        headerView
            .backBtn
            .rx.tap.asDriver()
            .driveNext { [weak self] in
                self?.popupPresentationContainer?.closePopup(animated: true, completion: nil)
        }.disposed(by: headerView.disposeBag)
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlayerFooterView.identifier) as! PlayerFooterView
        headerView.nextBtn.addTarget(self, action: #selector(nextBtnTap), for: .touchUpInside)
        headerView.prevBtn.addTarget(self, action: #selector(prevBtnTap), for: .touchUpInside)
        headerView.trackProgressSlider.minimumValue = 0
        headerView.trackProgressSlider.maximumValue = 1.0 // not sure

        headerView.trackProgressSlider.addTarget(self, action: #selector(sliderTouchValueChanged(_:)), for: .valueChanged)
        headerView.trackProgressSlider.addTarget(self, action: #selector(sliderTouchBegan(_:)), for: .touchDown)
        headerView.trackProgressSlider.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
        headerView.trackProgressSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:))))

        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trackInQueue = queues[safe: indexPath.row]

        guard let index = tracks.firstIndex(where: {
            $0.trackId == trackInQueue?.trackId
        }) else { return }
        triggerPlayAction(at: index)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = tableView.tableHeaderView else {return}
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }
    }
}

extension PlayerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queues.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.identifier, for: indexPath) as? TrackTableViewCell,
              queues.count > 0
        else { return UITableViewCell() }

        cell.bind(to: TrackCellViewModel(inputs: TrackCellVMContract
                                            .Input(track: queues[safe: indexPath.row] ?? DisplayItem())))

        return cell
    }
}

// MARK: - Player Method
extension PlayerViewController {
    func createPlaylist(name: String) {
        let fileNames = ([currentTrack] + queues).map {
            $0.fileName
        }.joined(separator: "\r\n")

        let filename = name

        FileServiceImpl.shared.createOrOverwriteEmptyFileInDocuments(filename: filename)
        if let handle = FileServiceImpl.shared.getHandleForFileInDocuments(filename: filename) {
            FileServiceImpl.shared.writeString(string: fileNames, fileHandle: handle)
        }

        FileServiceImpl.shared.sendFiles(fileName: filename.components(separatedBy: ".").first ?? "", extensionName: filename.components(separatedBy: ".").last ?? "", isPlaylist: true)
        playTrack(at: index)
    }

    func playFromDownloadedPlaylist(item: DisplayItem) {
        self.createPlaylist(name: item.title)
    }

    func showTrack(at index: Int) {
        sliderValue = 0
        queues = Array(tracks[index + 1 ..< tracks.count])
        currentTrack = tracks[index]
        playingTrackCount = queues.count
        nowPlayingQueues = [currentTrack] + queues
        self.index = index
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if self.queues.count > 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }

    func playTrack(at index: Int) {
        FileServiceImpl.shared.updateTrack(name: tracks[index].fileName)
    }

    func triggerPlayAction(at index: Int) {
        showTrack(at: index)
        playTrack(at: index)
    }

    @objc func sliderTouchBegan(_ sender: UISlider) {
    }

    @objc func sliderTouchValueChanged(_ sender: UISlider) {
        let playTime = sender.value
        if playTime == sender.maximumValue {
            if index < tracks.count - 1 {
                let indexToPlay = index + 1
                triggerPlayAction(at: indexToPlay)
            }
        }
    }

    @objc func sliderTapped(_ gestureRecognizer: UIGestureRecognizer) {
        guard let slider = gestureRecognizer.view as? UISlider else { return }
        let pointTapped = gestureRecognizer.location(in: slider)

        let positionOfSlider = slider.bounds.origin
        let widthOfSlider = slider.bounds.size.width
        let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(slider.maximumValue) / widthOfSlider)
        slider.setValue(Float(newValue), animated: true)
    }

    @objc func sliderTouchEnded(_ sender: UISlider) {
        let playTime = sender.value
        if playTime == sender.maximumValue {
            if index < tracks.count - 1 {
                let indexToPlay = index + 1
                triggerPlayAction(at: indexToPlay)
            }
        }
    }

    @objc func nextBtnTap() {
        debugPrint("tapped next")
        if self.index < self.tracks.count - 1 {
            let indexToPlay = self.index + 1
            self.triggerPlayAction(at: indexToPlay)
        }
    }

    @objc func prevBtnTap() {
        debugPrint("tapped previous")
        if self.index > 0 {
            let indexToPlay = self.index - 1
            self.triggerPlayAction(at: indexToPlay)
        }
    }

    func addToQueue(track: DisplayItem) {
        tracks.append(track)
        queues.append(track)

        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [IndexPath(row: self.queues.count - 1, section: 0)], with: .automatic)
            self.tableView.endUpdates()
        }
    }
}
