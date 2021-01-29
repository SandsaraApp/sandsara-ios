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
    @IBOutlet weak var toogleSwitch: UISwitch!
    @IBOutlet weak var flipModeView: UIView!
    @IBOutlet weak var rotateModeView: UIView!
    @IBOutlet weak var rotateTitleLabel: UILabel!
    @IBOutlet weak var rotateSwitch: UISwitch!

    @IBOutlet var sliderTempHeightConstraint: NSLayoutConstraint!
    
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
            L10n.cycle, L10n.static
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
        flipModeTitleLabel.text = L10n.flipMode
        rotateTitleLabel.text = L10n.rotate
        selectionStyle = .none
        colorTempSlider.maximumValue = Constraints.maxColorTemp
        colorTempSlider.minimumValue = Constraints.minColorTemp
    }

    override func bindViewModel() {
        viewModel.outputs
            .title
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.outputs
            .segmentsSelection
            .driveNext { value in
                defer {
                    if value == .staticMode {
                        self.resetValue(isColorTemp: self.staticColorSegmentControl.segmentSelected.value == 0)
                    }
                }
                self.contraints(value)
            }
            .disposed(by: disposeBag)

        viewModel
            .outputs
            .preselectedColor
            .compactMap {
                $0
            }
            .driveNext {
                self.colorGradientView.color = $0
            }.disposed(by: disposeBag)

        viewModel.outputs
            .datas
            .map { [Section(model: "", items: $0)] }
            .doOnNext { _ in
                self.contraints(DeviceServiceImpl.shared.lightMode.value)
            }
            .drive(collectionView.rx.items(dataSource: makeDatasource()))
            .disposed(by: disposeBag)

        segmentControl.segmentSelected
            .map { LightMode(rawValue: $0) ?? .cycle }
            .subscribeNext {
                self.viewModel.inputs.segmentsSelection.accept($0)
            }
            .disposed(by: disposeBag)

        lightSpeedSlider
            .rx.value
            .changed
            .debounce(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .compactMap { $0.rounded() }
            .subscribeNext {
                self.viewModel.sendLightSpeed(value: $0)
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
                guard self.segmentControl.segmentSelected.value == 1 else {
                    return
                }
                defer {
                    self.resetValue(isColorTemp: self.staticColorSegmentControl.segmentSelected.value == 0)
                }
                let isColorTemp = $0 == StaticMode.colorTemp
                self.colorTempSliderView.isHidden = !isColorTemp
                self.colorTempSliderView.alpha = isColorTemp ? 1 : 0
                self.customColorView.alpha = isColorTemp ? 0 : 1
                self.customColorView.isHidden = isColorTemp
                self.mainContentViewHeightConstraint.constant = self.lightModeHeight(isStatic: true)
                self.resetValue(isColorTemp: isColorTemp)
                self.needsUpdateConstraints()
                self.layoutIfNeeded()
                self.cellUpdated.accept(())
        }.disposed(by: disposeBag)

        collectionView.rx.itemSelected.subscribeNext { [weak self] indexPath in
            guard let self = self else { return }
            defer {
                self.colorGradientView.colors = (Preferences.AppDomain.colors?[indexPath.item] ?? ColorModel()).colors.map { UIColor(hexString: $0) }
            }
            self.colorGradientView?.color = Preferences.AppDomain.colors?[indexPath.item] ?? ColorModel()
        }.disposed(by: disposeBag)

        acceptBtn.rx.tap.subscribeNext {
            self.hideOverlayView()
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
            self.hideOverlayView()
            if self.colorGradientView.updateCustomPoint {
                self.colorGradientView.removeColor(color: self.overlaySliderView.color)
            }
        }.disposed(by: disposeBag)

        viewModel.outputs.flipDirection.drive(toogleSwitch.rx.isOn).disposed(by: disposeBag)

        viewModel.outputs.rotateToogle.drive(rotateSwitch.rx.isOn).disposed(by: disposeBag)

        toogleSwitch.rx.isOn
            .changed
            .debounce(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .asObservable()
            .subscribeNext { [weak self] state in
                self?.viewModel.inputs.flipDirection.accept(state)
        }.disposed(by: disposeBag)

        rotateSwitch.rx.isOn
            .changed
            .debounce(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .asObservable()
            .subscribeNext { [weak self] state in
                self?.viewModel.inputs.rotateToogle.accept(state)
            }.disposed(by: disposeBag)

        staticColorUpdateView.backgroundColor = UIColor(temperature: 2000.0)

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
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCell.identifier,
                                                                    for: indexPath)
                        as? ColorCell else { return UICollectionViewCell()}
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
        rotateModeView.isHidden = isStatic
        rotateModeView.alpha = isStatic ? 0 : 1
        layoutIfNeeded()
        cellUpdated.accept(())
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
        sendColor()
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
        print(customColorView.colorFromSliders().hexString())
    }

    @IBAction func overlaySliderGroupValueChanged(_ sender: HSBASliderGroup) {
        overlayColorUpdatedView.backgroundColor = overlaySliderView.color
        overlayLineView.backgroundColor = overlaySliderView.color
        if overlaySliderView.color.hsba().brightness < 0.16 {
            overlayLineView.layer.borderWidth = 0.5
            overlayLineView.layer.borderColor = Asset.primary.color.cgColor
            overlayColorUpdatedView.layer.borderWidth = 1
            overlayColorUpdatedView.layer.borderColor = Asset.primary.color.cgColor
        } else {
            overlayLineView.layer.borderWidth = 0
            overlayLineView.layer.borderColor = UIColor.white.cgColor
            overlayColorUpdatedView.layer.borderWidth = 0
            overlayColorUpdatedView.layer.borderColor = Asset.primary.color.cgColor
        }
    }

    @IBAction func overlaySliderGroupTouchDown(_ sender: HSBASliderGroup) {
        overlayColorUpdatedView.backgroundColor = overlaySliderView.color
        overlayLineView.backgroundColor = overlaySliderView.color
        if overlaySliderView.color.hsba().brightness < 0.16 {
            overlayLineView.layer.borderWidth = 0.5
            overlayLineView.layer.borderColor = Asset.primary.color.cgColor
            overlayColorUpdatedView.layer.borderWidth = 1
            overlayColorUpdatedView.layer.borderColor = Asset.primary.color.cgColor
        } else {
            overlayLineView.layer.borderWidth = 0
            overlayLineView.layer.borderColor = Asset.primary.color.cgColor
            overlayColorUpdatedView.layer.borderWidth = 0
            overlayColorUpdatedView.layer.borderColor = Asset.primary.color.cgColor
        }
    }

    @IBAction func overlaySliderGroupTouchUpInside(_ sender: HSBASliderGroup) {
        overlayColorUpdatedView.backgroundColor = overlaySliderView.color
        overlayLineView.backgroundColor = overlaySliderView.color
        if overlaySliderView.color.hsba().brightness < 0.16 {
            overlayLineView.layer.borderWidth = 0.5
            overlayLineView.layer.borderColor = Asset.primary.color.cgColor
            overlayColorUpdatedView.layer.borderWidth = 1
            overlayColorUpdatedView.layer.borderColor = Asset.primary.color.cgColor
        } else {
            overlayLineView.layer.borderWidth = 0
            overlayLineView.layer.borderColor = Asset.primary.color.cgColor
            overlayColorUpdatedView.layer.borderWidth = 0
            overlayColorUpdatedView.layer.borderColor = Asset.primary.color.cgColor
        }
    }

    func sendColor() {
        guard let staticColorViewColor = self.staticColorUpdateView.backgroundColor else { return }
    let position = Data([0, 255].map { UInt8($0) })
    print(position)
    
    let red = Data([UInt8(staticColorViewColor.rgba().red * 255), UInt8(staticColorViewColor.rgba().red * 255)])
    print(red)
    let blue = Data([UInt8(staticColorViewColor.rgba().blue * 255), UInt8(staticColorViewColor.rgba().blue * 255)])
    print(blue)
    let green = Data([UInt8(staticColorViewColor.rgba().green * 255), UInt8(staticColorViewColor.rgba().green * 255)])
    print(green)
    let colorString = [Data([UInt8(2)]), position, red, green, blue].combined
    print(colorString)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            LedStripServiceImpl.shared.uploadCustomPalette(colorString: colorString)
        }
    
    var colorModel = ColorModel()
    var reds = [Float]()
    var blues = [Float]()
    var greens = [Float]()
    var positions = [Int]()
    reds = [(Float(staticColorViewColor.rgba().red) * 255.0), (Float(staticColorViewColor.rgba().red) * 255.0)]
    blues = [(Float(staticColorViewColor.rgba().blue) * 255.0), (Float(staticColorViewColor.rgba().blue) * 255.0)]
    greens = [(Float(staticColorViewColor.rgba().green) * 255.0), (Float(staticColorViewColor.rgba().green) * 255.0)]
    positions = [0, 255]
    
    let colorsTest = zip3(reds, greens, blues).map {
    RGBA(red: CGFloat($0.0) / 255, green: CGFloat($0.1) / 255, blue: CGFloat($0.2) / 255).color().hexString()
    }
    if positions.count == 1 {
    colorModel.position = [0, 255]
    if let color = colorsTest.first {
    colorModel.colors = [color, color]
    }
    } else {
    colorModel.position = positions
    colorModel.colors = colorsTest
    }
    DeviceServiceImpl.shared.runningColor.accept(colorModel)

    }

    func resetValue(isColorTemp: Bool) {
        if isColorTemp {
            colorTempSlider.value = Constraints.minColorTemp
            staticColorUpdateView.backgroundColor = UIColor(temperature: 2000.0)
            sendColor()
        } else {
            customColorView.color = UIColor(hexString: "#FF0000")
            customColorView.slidersFrom(color: .red)
            staticColorUpdateView.backgroundColor = UIColor(hexString: "#FF0000")
            sendColor()
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
        showOverlayView(at: 27.0, by: color)
    }

    func secondPointTouch(color: UIColor) {
        showOverlayView(at: UIScreen.main.bounds.size.width - 29.0, by: color)
    }

    func showGradient(atPoint: CGPoint, color: UIColor) {
        showOverlayView(at: atPoint.x + 27.0, by: color, isDeleteAble: true)
    }

    private func showOverlayView(at point: CGFloat,
                                 by color: UIColor,
                                 isDeleteAble: Bool = false) {
        overlayLineView.backgroundColor = color
        overlayLeadingConstraint.constant = point
        overlayGradientView.alpha = 1
        overlayGradientView.isHidden = false
        overlayColorUpdatedView.backgroundColor = color
        overlaySliderView.color = color
        deleteBtn.isHidden = !isDeleteAble
    }

    private func hideOverlayView() {
        overlayGradientView.isHidden = true
        overlayGradientView.alpha = 0
    }
}
