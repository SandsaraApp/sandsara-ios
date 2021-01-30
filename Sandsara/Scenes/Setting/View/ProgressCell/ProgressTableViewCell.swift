//
//  ProgressTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit
import RxSwift
import RxCocoa

class ProgressTableViewCell: BaseTableViewCell<ProgressCellViewModel> {
    @IBOutlet private weak var progressNameLabel: UILabel!
    @IBOutlet private weak var progressSlider: WOWMarkSlider!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        progressNameLabel.font = FontFamily.OpenSans.regular.font(size: 18)
        progressNameLabel.textColor = Asset.primary.color
        progressSlider.handlerImage = Asset.thumbs.image
        progressSlider.height = 2
        progressSlider.markWidth = 0
        progressSlider.isContinuous = false
    }

    override func bindViewModel() {
        progressSlider.maximumValue = viewModel.inputs.type.sliderValue.1
        progressSlider.minimumValue = viewModel.inputs.type.sliderValue.0
        
        progressSlider.markPositions = viewModel.inputs.type.ranges

        viewModel
            .outputs
            .title
            .drive(progressNameLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel
            .outputs
            .progress
            .drive(progressSlider.rx.value)
            .disposed(by: disposeBag)

        progressSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderTouchUpInside), for: [.touchUpInside])
        progressSlider.addTarget(self, action: #selector(sliderTouchUpInside), for: [.touchUpOutside])
        progressSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:))))
    }
    @objc func sliderTapped(_ gestureRecognizer: UIGestureRecognizer) {
        guard let slider = gestureRecognizer.view as? UISlider else { return }
        let pointTapped = gestureRecognizer.location(in: slider)

        let positionOfSlider = slider.bounds.origin
        let widthOfSlider = slider.bounds.size.width
        let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(slider.maximumValue) / widthOfSlider)
        slider.setValue(Float(newValue), animated: true)
        viewModel.inputs.progress.accept(Float(newValue).rounded())
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
                case .began:
                // handle drag began
                print("drag began")
                case .moved:
                // handle drag moved
                print("drag moved")
                  //  viewModel.inputs.progress.accept(slider.value.rounded())
                case .ended:
                // handle drag ended
                print("drag ended")
                    viewModel.inputs.progress.accept(slider.value.rounded())
                default:
                    break
            }
        }
    }
    
    @objc func sliderTouchUpInside() {
        print("drag ended")
    }
    

//    @objc func sliderValueChanges(_ slider: WOWMarkSlider) {
//        debugPrint(slider.value)
//        viewModel.inputs.progress.accept(slider.value)
//    }
}
