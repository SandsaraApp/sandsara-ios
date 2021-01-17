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
import Bluejay

enum PlayingState {
    case playlist
    case track
}

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

    var playlingState: PlayingState = .playlist

    var playingTrackCount = 0

    var playlistItem: DisplayItem?

    var firstPriorityTrack: DisplayItem?

    var timer: Timer?

    var progress = BehaviorRelay<Float>(value: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isReloaded {
            if playlingState == .track {
                if let firstPriority = firstPriorityTrack {
                    addToQueue(track: firstPriority)
                    showTrack(at: self.queues.count - 1)
                }
            } else {
                showTrack(at: index)
                createPlaylist()
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
        headerView.trackProgressSlider.maximumValue = 100 // not sure

        headerView.trackProgressSlider.addTarget(self, action: #selector(sliderTouchValueChanged(_:)), for: .valueChanged)
        headerView.trackProgressSlider.addTarget(self, action: #selector(sliderTouchBegan(_:)), for: .touchDown)
        headerView.trackProgressSlider.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
        headerView.trackProgressSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:))))

        headerView.playBtn.rx.tap.asDriver().driveNext { [weak self] in
            guard let self = self else { return }
            if DeviceServiceImpl.shared.status.value == SandsaraStatus.pause || DeviceServiceImpl.shared.status.value == SandsaraStatus.sleep {
                DeviceServiceImpl.shared.resumeDevice()
                self.readProgress()
                headerView.playBtn.setImage(Asset.pause1.image, for: .normal)
            } else if DeviceServiceImpl.shared.status.value == (SandsaraStatus.running) {
                DeviceServiceImpl.shared.pauseDevice()
                headerView.playBtn.setImage(Asset.play.image, for: .normal)
            }
        }.disposed(by: disposeBag)

        progress
            .bind(to: headerView.trackProgressSlider.rx.value)
            .disposed(by: headerView.disposeBag)

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
    func createPlaylist() {
        let fileNames = tracks.map {
            $0.fileName
        }.joined(separator: "\r\n")

        let filename = "temporal"
        let fileExtension = "playlist"

        FileServiceImpl.shared.createOrOverwriteEmptyFileInDocuments(filename: filename + "." + fileExtension)
        if let handle = FileServiceImpl.shared.getHandleForFileInDocuments(filename: filename + "." + fileExtension) {
            FileServiceImpl.shared.writeString(string: fileNames, fileHandle: handle)
        }

        FileServiceImpl.shared.sendFiles(fileName: filename, extensionName: fileExtension, isPlaylist: true)
        FileServiceImpl.shared.sendSuccess.subscribeNext {
            if $0 {
                if self.isReloaded {
                    self.isReloaded = false
                    FileServiceImpl.shared.updatePlaylist(fileName: filename,
                                                          index: self.playlingState == .track ? self.queues.count - 1 : 0) { success in
                        if success {
                            print("Play playlist \(filename) success")
                            self.readProgress()
                        }
                    }
                }
            }
        }.disposed(by: disposeBag)
    }

    func showTrack(at index: Int) {
        sliderValue = 0
        queues = Array(tracks[index + 1 ..< tracks.count]) + Array(tracks[0 ..< index])
        currentTrack = tracks[index]
        playingTrackCount = queues.count
        self.index = index
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if self.queues.count > 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }

    func playTrack(at index: Int) {
        FileServiceImpl.shared.updatePositionIndex(index: index + 1) { success in
            if success {
                self.readProgress()
                DispatchQueue.main.async {
                    (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .haveTrack(displayItem: self.tracks[index])
                }
            }
        }
    }

    func triggerPlayAction(at index: Int) {
        showTrack(at: index)
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
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
        } else {
            let indexToPlay = 0
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

        if tracks.count > 1 {
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [IndexPath(row: self.queues.count - 1, section: 0)], with: .automatic)
                self.tableView.endUpdates()
            }
        } else {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }

        createPlaylist()
    }

    func readProgress() {
        progress.accept(0)
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateTimer(_:)), userInfo: nil, repeats: true)
    }

    @objc func updateTimer(_ timer: Timer) {
        if progress.value == 100 || DeviceServiceImpl.shared.status.value == SandsaraStatus.pause {
            self.timer?.invalidate()
            self.timer = nil
            self.nextBtnTap()
        } else {
            bluejay.read(from: PlaylistService.progressOfPath) { (result: ReadResult<String>) in
                switch result {
                case .success(let value):
                    let float = Float(value) ?? 0
                    print("Progress \(float)")
                    self.progress.accept(float)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}
