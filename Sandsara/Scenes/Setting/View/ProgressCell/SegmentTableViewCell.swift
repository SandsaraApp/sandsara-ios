//
//  SegmentTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 27/11/2020.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources

private struct Constants {
    static let cellHeight: CGFloat = 29.0
    static let cellWidth: CGFloat = 29.0
}

private struct Constraints {
    static let labelHeight = 25.0
    static let commonSpacing = 16.0
    static let hsbViewHeight = 87.0
    static let collectionViewHeight = 40.0
    static let sliderHeight = 14.0

    static let segmentHeight = 50.0
    static let colorViewHeight = 43.0
    static let colorSliderHeight = 30.0

    static let minColorTemp: Float = 2000.0
    static let maxColorTemp: Float = 10000.0
}

class SegmentTableViewCell: BaseTableViewCell<LightModeCellViewModel> {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var segmentControl: CustomSegmentControl!
    @IBOutlet weak var mainContentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainContentView: UIView!
    @IBOutlet private weak var colorPaletteLabel: UILabel!
    @IBOutlet private weak var presetLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lightSpeedLabel: UILabel!
    @IBOutlet weak var lightSpeedSlider: UISlider!
    @IBOutlet weak var hsbView: UIView!
    @IBOutlet weak var staticColorView: UIView!
    @IBOutlet weak var staticColorSegmentControl: CustomSegmentControl!
    @IBOutlet weak var staticColorViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var advanceInfoLabel: UIButton!
    @IBOutlet weak var sandsaraWebLabel: UIButton!
    @IBOutlet weak var helpLabel: UIButton!
    @IBOutlet weak var colorTempSliderView: UIView!
    @IBOutlet weak var customColorView: HSBASliderGroup!
    @IBOutlet weak var staticColorUpdateView: UIView!
    @IBOutlet weak var colorGradientView: ColorGradientView!
    @IBOutlet weak var overlayGradientView: UIView!
    @IBOutlet weak var overlayLineView: UIView!
    @IBOutlet weak var overlayColorUpdatedView: UIView!
    @IBOutlet weak var overlaySliderView: HSBASliderGroup!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var acceptBtn: UIButton!
    @IBOutlet weak var overlayLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var colorTempSlider: UISlider!

    @IBOutlet weak var flipModeTitleLabel: UILabel!
    @IBOutlet weak var toogleSwitch: ToggleSwitch!
    @IBOutlet weak var flipModeView: UIView!

    @IBOutlet var sliderTempHeightConstraint: NSLayoutConstraint!
    
    let segmentSelected = BehaviorRelay<LightMode>(value: .rotate)
    let cellUpdated = PublishRelay<()>()

    let advancedBtnTap = PublishRelay<()>()

    let staticMode = PublishRelay<StaticMode>()

    typealias Section = SectionModel<String, PresetCellViewModel>
    typealias DataSource = RxCollectionViewSectionedReloadDataSource<Section>

    var selectedCell = PublishRelay<(Int, PresetCellViewModel)>()

    override func awakeFromNib() {
        super.awakeFromNib()
        let font = FontFamily.OpenSans.regular.font(size: 18)
        titleLabel.textColor = Asset.primary.color
        titleLabel.font = font

        segmentControl.setStyle(font: font , titles: [
            L10n.rotate, L10n.cycle, L10n.static
        ])

        staticColorSegmentControl.setStyle(font: font, titles: [
            L10n.colorTemp, L10n.customColor
        ])

        advanceInfoLabel.setTitle(L10n.advanceSetting, for: .normal)
        sandsaraWebLabel.setTitle(L10n.website, for: .normal)
        helpLabel.setTitle(L10n.help, for: .normal)

        colorPaletteLabel.text = L10n.colorPallete
        presetLabel.text = L10n.presets
        lightSpeedLabel.text = L10n.lightCycleSpeed

        collectionView.backgroundColor = Asset.background.color
        collectionView.register(ColorCell.nib, forCellWithReuseIdentifier: ColorCell.identifier)
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)

        lightSpeedSlider.maximumValue = SettingItemType.lightCycleSpeed.sliderValue.1
        lightSpeedSlider.minimumValue = SettingItemType.lightCycleSpeed.sliderValue.0

        for state: UIControl.State in [.normal, .selected, .application, .reserved] {
            lightSpeedSlider.setThumbImage(Asset.thumbs.image, for: state)
        }

        for state: UIControl.State in [.normal, .selected, .application, .reserved] {
            colorTempSlider.setThumbImage(Asset.thumbs.image, for: state)
        }

        hsbView.isHidden = true
        hsbView.alpha = 0
        staticColorView.isHidden = true
        staticColorView.alpha = 0

        colorGradientView.delegate = self

        customColorView.color = Asset.primary.color
        customColorView.showAlphaSlider = false
        customColorView.colorKnob = false
        customColorView.knobSize = CGSize(width: 24.0, height: 24.0)

        overlaySliderView.showAlphaSlider = false
        overlaySliderView.colorKnob = false
        overlaySliderView.knobSize = CGSize(width: 24.0, height: 24.0)

        overlayGradientView.alpha = 0
        overlayGradientView.isHidden = true

        lightSpeedSlider.value = DeviceServiceImpl.shared.ledSpeed.value

        let images = ToggleSwitchImages(baseOnImage: Asset.toggleBaseOn.image,
                                        baseOffImage: Asset.toggleBaseOff.image,
                                        thumbOnImage: Asset.thumbs.image,
                                        thumbOffImage: Asset.thumbs.image)

        toogleSwitch.configurationImages = images
        flipModeTitleLabel.text = L10n.flipMode
        selectionStyle = .none
        colorTempSlider.maximumValue = Constraints.maxColorTemp
    }

    override func bindViewModel() {
        viewModel.outputs
            .title
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.outputs
            .segmentsSelection
            .driveNext {
                self.contraints($0)
            }
            .disposed(by: disposeBag)

        viewModel.outputs
            .datas
            .map { [Section(model: "", items: $0)] }
            .doOnNext { _ in
                self.contraints(DeviceServiceImpl.shared.lightMode.value)
            }
            .drive(collectionView.rx.items(dataSource: makeDatasource()))
            .disposed(by: disposeBag)

        segmentControl.segmentSelected.skip(1)
            .map { LightMode(rawValue: $0) ?? .rotate }
            .subscribeNext {
                self.viewModel.inputs.segmentsSelection.accept($0)
            }
            .disposed(by: disposeBag)

        lightSpeedSlider
            .rx.value
            .changed
            .debounce(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .compactMap { Int($0) }
            .subscribeNext { value in
                bluejay.write(to: LedStripService.ledStripSpeed, value: "\(value)") { result in
                    switch result {
                    case .success:
                        debugPrint("Write to sensor location is successful.\(result)")
                    case .failure(let error):
                        debugPrint("Failed to write sensor location with error: \(error.localizedDescription)")
                    }
                }
            }.disposed(by: disposeBag)

        advanceInfoLabel
            .rx.tap.bind(to: advancedBtnTap)
            .disposed(by: disposeBag)

        sandsaraWebLabel.rx.tap.subscribeNext {
            UIApplication.shared
                .open(URL(string: "https://www.kickstarter.com/projects/edcano/sandsara")!,
                      options: [:],
                      completionHandler: nil)
        }.disposed(by: disposeBag)


        staticColorSegmentControl
            .segmentSelected
            .map { StaticMode(rawValue: $0) }
            .subscribeNext {
                guard self.segmentControl.segmentSelected.value == 2 else {
                    return
                }
                self.colorTempSliderView.isHidden = $0 != StaticMode.colorTemp
                self.colorTempSliderView.alpha = $0 == StaticMode.colorTemp ? 1 : 0
                self.customColorView.alpha = $0 == StaticMode.colorTemp ? 0 : 1
                self.customColorView.isHidden = $0 == StaticMode.colorTemp
                self.mainContentViewHeightConstraint.constant = self.lightModeHeight(isStatic: true)
                self.needsUpdateConstraints()
                self.layoutIfNeeded()
                self.cellUpdated.accept(())
        }.disposed(by: disposeBag)

        collectionView.rx.itemSelected.subscribeNext { [weak self] indexPath in
            guard let self = self else { return }
            self.colorGradientView?.color = PredifinedColor(rawValue: indexPath.item) ?? .one
            bluejay.write(to: LedStripService.selectPattle, value: "\(indexPath.item + 1)") { result in
                switch result {
                case .success:
                    debugPrint("Write to sensor location is successful.\(result)")
                case .failure(let error):
                    debugPrint("Failed to write sensor location with error: \(error.localizedDescription)")
                }
            }
        }.disposed(by: disposeBag)

        acceptBtn.rx.tap.subscribeNext {
            self.overlayGradientView.isHidden = true
            self.overlayGradientView.alpha = 0
            //TODO: add color or update color
            if self.colorGradientView.isFirst {
                self.colorGradientView.updateFirstColor(color: self.overlaySliderView.color)
            } else if self.colorGradientView.isLast {
                self.colorGradientView.updateSecondColor(color: self.overlaySliderView.color)
            } else if self.colorGradientView.addCustomPoint {
                self.colorGradientView.addColor(color: self.overlaySliderView.color)
            } else {
                self.colorGradientView.updatePointColor(color: self.overlaySliderView.color)
            }
        }.disposed(by: disposeBag)

        deleteBtn.rx.tap.subscribeNext {
            self.overlayGradientView.isHidden = true
            self.overlayGradientView.alpha = 0
            if self.colorGradientView.updateCustomPoint {
                self.colorGradientView.removeColor(color: self.overlaySliderView.color)
            }
        }.disposed(by: disposeBag)

        viewModel.outputs.flipDirection.drive(toogleSwitch.rx.isOn).disposed(by: disposeBag)

        toogleSwitch.stateChanged = { [weak self] state in
            self?.viewModel.inputs.flipDirection.accept(state)
        }

        colorTempSlider
            .rx.value.changed
            .subscribeNext { temperature in
                self.staticColorUpdateView.backgroundColor = UIColor(temperature: CGFloat(temperature))
                self.sendColor()
        }.disposed(by: disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    private func makeDatasource() -> DataSource {
        return DataSource(
            configureCell: { (_, collectionView, indexPath, viewModel) -> UICollectionViewCell in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCell.identifier, for: indexPath) as? ColorCell else { return UICollectionViewCell()}
                cell.bind(to: viewModel)
                return cell
            })
    }

    private func contraints(_ mode: LightMode) {
        let isStatic = mode == .staticMode
        mainContentViewHeightConstraint.constant = self.lightModeHeight(isStatic: isStatic)
        hsbView.isHidden = isStatic
        hsbView.alpha = isStatic ? 0 : 1
        collectionView.isHidden = isStatic
        staticColorView.isHidden = !isStatic
        staticColorView.alpha = isStatic ? 1 : 0
        flipModeView.isHidden = isStatic
        flipModeView.alpha = isStatic ? 0 : 1
        layoutIfNeeded()
        cellUpdated.accept(())
        segmentSelected.accept(mode)
    }

    private func lightModeHeight(isStatic: Bool) -> CGFloat {
        if isStatic {
            let height = Constraints.segmentHeight +
            Constraints.commonSpacing * 1.875 +
            Constraints.colorViewHeight
            sliderTempHeightConstraint.isActive = staticColorSegmentControl.segmentSelected.value == 0
            staticColorViewHeightConstraint.constant = staticModeHeight(isColorTemp: staticColorSegmentControl.segmentSelected.value == 0)
            return CGFloat(height) + staticColorViewHeightConstraint.constant
        } else {
            sliderTempHeightConstraint.isActive = false
            return 329.0
        }
    }

    private func staticModeHeight(isColorTemp: Bool) -> CGFloat {
        if isColorTemp {
            return sliderTempHeightConstraint.constant
        } else {
            return customColorView.intrinsicContentSize.height + 30.0
        }
    }

    @IBAction func hsbaSliderGroupValueChanged(_ sender: HSBASliderGroup) {
        updateBackgroundColor()
    }

    @IBAction func hsbaSliderGroupTouchDown(_ sender: HSBASliderGroup) {
        updateBackgroundColor()
    }

    @IBAction func hsbaSliderGroupTouchUpInside(_ sender: HSBASliderGroup) {
        updateBackgroundColor()
        sendColor()
    }

    private func updateBackgroundColor() {
        staticColorUpdateView.backgroundColor = customColorView.color
        print(customColorView.colorFromSliders().hsba())
    }

    @IBAction func overlaySliderGroupValueChanged(_ sender: HSBASliderGroup) {
        overlayColorUpdatedView.backgroundColor = overlaySliderView.color
        overlayLineView.backgroundColor = overlaySliderView.color
    }

    @IBAction func overlaySliderGroupTouchDown(_ sender: HSBASliderGroup) {
        overlayColorUpdatedView.backgroundColor = overlaySliderView.color
        overlayLineView.backgroundColor = overlaySliderView.color
    }

    @IBAction func overlaySliderGroupTouchUpInside(_ sender: HSBASliderGroup) {
        overlayColorUpdatedView.backgroundColor = overlaySliderView.color
        overlayLineView.backgroundColor = overlaySliderView.color
    }

    func sendColor() {
        guard let staticColorViewColor = self.staticColorUpdateView.backgroundColor else { return }
        let postions = ["0", "255"].joined(separator: ",")

        let redColor = (staticColorViewColor.rgba().red * 255).rounded()
        let red = "\(redColor),\(redColor)"

        let greenColor = (staticColorViewColor.rgba().green * 255).rounded()
        let green = "\(greenColor),\(greenColor)"

        let blueColor = (staticColorViewColor.rgba().blue * 255).rounded()

        let blue = "\(blueColor),\(blueColor)"

        let amount = "2"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            LedStripServiceImpl.shared.uploadCustomPalette(amoutColors: amount, postions: postions, red: red, blue: blue, green: green)
        }
    }

}

extension SegmentTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.cellWidth, height: Constants.cellHeight)
    }
}

extension SegmentTableViewCell: ColorGradientViewDelegate {
    func firstPointTouch(color: UIColor) {
        overlayLineView.backgroundColor = color
        overlayLeadingConstraint.constant = 27.0
        overlayGradientView.alpha = 1
        overlayGradientView.isHidden = false
        overlayColorUpdatedView.backgroundColor = color
        overlaySliderView.color = color
        deleteBtn.isHidden = true
    }

    func secondPointTouch(color: UIColor) {
        overlayLineView.backgroundColor = color
        overlayLeadingConstraint.constant = UIScreen.main.bounds.size.width - 29.0
        overlayGradientView.alpha = 1
        overlayGradientView.isHidden = false
        overlayColorUpdatedView.backgroundColor = color
        overlaySliderView.color = color
        deleteBtn.isHidden = true
    }

    func showGradient(atPoint: CGPoint, color: UIColor) {
        overlayLineView.backgroundColor = color
        overlayLeadingConstraint.constant = atPoint.x + 27.0
        overlayGradientView.alpha = 1
        overlayGradientView.isHidden = false
        overlayColorUpdatedView.backgroundColor = color
        overlaySliderView.color = color
        deleteBtn.isHidden = false
    }
}
