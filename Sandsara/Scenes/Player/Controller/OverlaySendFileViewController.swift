//
//  OverlayViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 05/02/2021.
//

import UIKit

class OverlaySendFileViewController: BaseViewController<NoInputParam> {
    
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var syncProgressBar: UIProgressView!
    @IBOutlet weak var remainTrackCountLabel: UILabel!
    
    var notSyncedTracks = [DisplayItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData(_:)), name: reloadNoti, object: nil)
        let completion = BlockOperation {
            print("All track synced is done")
        }
        for track in self.notSyncedTracks {
            let operation = FileSyncManager.shared.queueDownload(item: track)
            FileSyncManager.shared.triggerOperation(id: track.trackId)
            completion.addDependency(operation)
        }
        completion.cancel()
        OperationQueue.main.addOperation(completion)
    }
    

    @objc func reloadData(_ noti: Notification) {
        func getCurrentSyncTask(item: DisplayItem) {
            if let task = FileSyncManager.shared.findCurrentQueue(item: item) {
                self.syncProgressBar.isHidden = false
                self.trackNameLabel.text = item.title
                self.remainTrackCountLabel.text = "\(FileSyncManager.shared.operations.count) tracks are syncing now"
                task.progress
                    .bind(to: self.syncProgressBar.rx.progress)
                    .disposed(by: task.disposeBag)
            } else {
                syncProgressBar.isHidden = true
            }
        }
        
        if let noti = noti.object as? [String: Any], let item = noti["item"] as? DisplayItem {
            getCurrentSyncTask(item: item)
        } else {
            DispatchQueue.main.async {
                self.dismiss(animated: false, completion: {
                    if PlayerViewController.shared.playlingState == .showOnly {
                        PlayerViewController.shared.playlingState = .track
                        self.showSuccessHUD(message: "Track \(DeviceServiceImpl.shared.currentTracks[DeviceServiceImpl.shared.currentTrackIndex].title) was added")
                    }
                    PlayerViewController.shared.createPlaylist()
                    (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .haveTrack(displayItem: DeviceServiceImpl.shared.currentTracks[DeviceServiceImpl.shared.currentTrackIndex])
                })
            }
        }
    }
}
