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
    case showOnly
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
    
    var lastProgress = 0.0
    
    @IBOutlet weak var overlayView: UIView!
    var progress = BehaviorRelay<Float>(value: 0)
    
    @IBOutlet weak var trackProgressSlider: UISlider!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var syncProgressBar: UIProgressView!
    @IBOutlet weak var remainTrackCountLabel: UILabel!
    
    var notSyncedTracks = [DisplayItem]()
    
    var isPlaying = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isReloaded {
            if playlingState == .track {
                if let firstPriority = firstPriorityTrack {
                    tracks.append(firstPriority)
                    if tracks.count > 1 {
                        queues = Array(tracks[index + 1 ..< tracks.count]) + Array(tracks[0 ..< index])
                    } else {
                        queues = tracks
                    }
                    addToQueue(track: firstPriority)
                    showTrack(at: self.tracks.count - 1)
                }
            } else {
                showTrack(at: index)
                if playlingState == .playlist {
                    checkMultipleTracks()
                } else {
                    createPlaylist()
                }
            }
        }
    }
    
    private func setupTableView() {
        tableView.backgroundColor = Asset.background.color
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(TrackTableViewCell.nib, forCellReuseIdentifier: TrackTableViewCell.identifier)
        tableView.register(PlayerHeaderView.nib, forHeaderFooterViewReuseIdentifier: PlayerHeaderView.identifier)
        tableView.contentInset = UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        nextBtn.addTarget(self, action: #selector(nextBtnTap), for: .touchUpInside)
        prevBtn.addTarget(self, action: #selector(prevBtnTap), for: .touchUpInside)
        trackProgressSlider.minimumValue = 0
        trackProgressSlider.maximumValue = 100 // not sure
        
        for state: UIControl.State in [.normal, .selected, .application, .reserved] {
            trackProgressSlider.setThumbImage(Asset.thumbs.image, for: state)
        }
        
        trackProgressSlider.addTarget(self, action: #selector(sliderTouchValueChanged(_:)), for: .valueChanged)
        trackProgressSlider.addTarget(self, action: #selector(sliderTouchBegan(_:)), for: .touchDown)
        trackProgressSlider.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
        trackProgressSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:))))
        
        playBtn.rx.tap.asDriver().driveNext { [weak self] in
            guard let self = self else { return }
            if self.isPlaying {
                self.isPlaying = false
                DeviceServiceImpl.shared.pauseDevice()
                self.pauseTimer()
                self.playBtn.setImage(Asset.play.image, for: .normal)
            } else {
                self.isPlaying = true
                DeviceServiceImpl.shared.resumeDevice()
                self.updateProgressTimer()
                self.playBtn.setImage(Asset.pause1.image, for: .normal)
            }
            self.popupBar.customBarViewController?.popupItemDidUpdate()
        }.disposed(by: disposeBag)
        
        progress
            .bind(to: trackProgressSlider.rx.value)
            .disposed(by: disposeBag)
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
                                            .Input(mode: .remote, track: queues[safe: indexPath.row] ?? DisplayItem())))
        
        return cell
    }
}

// MARK: - Player Method
extension PlayerViewController {
    func createPlaylist() {
        guard playlingState != .showOnly else {
            if timer != nil {
                timer?.invalidate()
                timer = nil
            }
            timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateTimer(_:)), userInfo: nil, repeats: true)
            return
        }
        let fileNames = tracks.map {
            $0.fileName
        }.joined(separator: "\r\n") 
        
        let filename = playlistItem?.title ?? "temporal"
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
                    FileServiceImpl.shared.updatePlaylist(fileName: self.playlistItem?.title ?? "temporal",
                                                          index: self.playlingState == .track ? self.tracks.count : 1,
                                                          mode: self.playlingState) { success in
                        if success {
                            DeviceServiceImpl.shared.readPlaylistValue()
                            print("Play playlist \(self.playlistItem?.title ?? "temporal") success")
                            self.readProgress()
                        }
                    }
                }
            }
        }.disposed(by: disposeBag)
    }
    
    func showTrack(at index: Int) {
        DeviceServiceImpl.shared.currentTrackIndex = index
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
//                DeviceServiceImpl.shared.readDeviceStatus()
//                DeviceServiceImpl.shared.readPlaylistValue()
                self.isPlaying = true
                DeviceServiceImpl.shared.currentTrackPosition.accept(0)
                DispatchQueue.main.async {
                    self.readProgress()
                    (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .haveTrack(displayItem: self.tracks[index])
                }
            }
        }
    }
    
    func triggerPlayAction(at index: Int) {
        defer {
            showTrack(at: index)
            playTrack(at: index)
        }
       // DeviceServiceImpl.shared.readDeviceStatus()
        pauseTimer()
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
        } else {
            let indexToPlay = self.tracks.count - 1
            self.triggerPlayAction(at: indexToPlay)
        }
    }
    
    func addToQueue1(track: DisplayItem) {
        tracks.append(track)
        if tracks.count > 1 {
            queues = Array(tracks[index + 1 ..< tracks.count]) + Array(tracks[0 ..< index])
        } else {
            queues = tracks
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        DeviceServiceImpl.shared.currentTracks = tracks
    }
    
    func addToQueue(track: DisplayItem) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        DeviceServiceImpl.shared.currentTracks = tracks
        
        checkTrackExist(track: track)
    }
    
    // MARK: - check single track
    func checkTrackExist(track: DisplayItem) {
        FileServiceImpl.shared.checkFileExistOnSDCard(name: track.fileName) { isExisted in
            if isExisted { 
                DispatchQueue.main.async {
                    // self.overlayView.isHidden = true
                    self.createPlaylist()
                }
            } else {
                DispatchQueue.main.async {
                    (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .busy
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: OverlaySendFileViewController.identifier) as! OverlaySendFileViewController
                    vc.modalPresentationStyle = .overFullScreen
                    vc.notSyncedTracks = [track]
                    self.present(vc, animated: false)
                }
            }
        }
    }
        
    // MARK: - check multiple tracks 
    func checkMultipleTracks() {
        notSyncedTracks = []
        bluejay.run { sandsaraBoard -> Bool in
            for track in self.tracks {
                do {
                    let value: String = try sandsaraBoard.writeAndRead(writeTo: FileService.checkFileExist, value: track.fileName, readFrom: FileService.receiveFileRespone)
                    if value == "1" {
                        continue
                    } else {
                        self.notSyncedTracks.append(track)
                    }
                }
            }
            return false
        } completionOnMainThread: { result in
            switch result {
            case .success:
                print("checked all")
                if self.notSyncedTracks.isEmpty {
                    self.createPlaylist()
                } else {
                    self.progress.accept(0)
                    self.pauseTimer()
                    DispatchQueue.main.async {
                        (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .busy
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: OverlaySendFileViewController.identifier) as! OverlaySendFileViewController
                        vc.modalPresentationStyle = .overFullScreen
                        vc.notSyncedTracks = self.notSyncedTracks
                        self.present(vc, animated: false)
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func updateProgressTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateTimer(_:)), userInfo: nil, repeats: true)
        }
    }
    
    func pauseTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func readProgress() {
        progress.accept(0)
        trackProgressSlider.setValue(0, animated: false)
        updateProgressTimer()
    }
    
    @objc func updateTimer(_ timer: Timer) {
        if progress.value == 100  {
            defer {
                readProgress()
            }
            self.progress.accept(0)
            if self.timer != nil {
                self.timer?.invalidate()
                self.timer = nil
            }
            if self.index < self.tracks.count - 1 {
                let indexToPlay = self.index + 1
                print("auto play \(indexToPlay)")
                self.showTrack(at: indexToPlay)
            } else {
                let indexToPlay = 0
                self.showTrack(at: indexToPlay)
            }
            
        } else {
            bluejay.read(from: PlaylistService.progressOfPath) { (result: ReadResult<String>) in
                switch result {
                case .success(let value):
                    let float = Float(value) ?? 0
                    print("Progress \(float)")
                    self.progress.accept(float)
                    self.lastProgress = Double(value) ?? 0
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}
