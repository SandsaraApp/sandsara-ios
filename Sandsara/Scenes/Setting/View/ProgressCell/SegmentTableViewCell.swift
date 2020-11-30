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
    static let collectionViewHeight = 35.0
    static let sliderHeight = 14.0

    static let segmentHeight = 50.0
    static let colorViewHeight = 43.0

    static let colorSliderHeight = 30.0
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
    @IBOutlet weak var customColorView: UIStackView!

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

        lightSpeedSlider.maximumValue = 500
        lightSpeedSlider.minimumValue = 10

        hsbView.isHidden = true
        hsbView.alpha = 0
        staticColorView.isHidden = true
        staticColorView.alpha = 0

        selectionStyle = .none
    }

    override func bindViewModel() {
        viewModel.outputs
            .title
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.outputs
            .segmentsSelection
            .driveNext {
                let isStatic = $0 == .staticMode
                self.mainContentViewHeightConstraint.constant = self.lightModeHeight(isStatic: isStatic)
                self.hsbView.isHidden = isStatic
                self.hsbView.alpha = isStatic ? 0 : 1
                self.staticColorView.isHidden = !isStatic
                self.staticColorView.alpha = isStatic ? 1 : 0
                self.needsUpdateConstraints()
                self.layoutIfNeeded()
                self.cellUpdated.accept(())
            }
            .disposed(by: disposeBag)

        viewModel.outputs
            .datas
            .map { [Section(model: "", items: $0)] }
            .drive(collectionView.rx.items(dataSource: makeDatasource()))
            .disposed(by: disposeBag)

        segmentControl.segmentSelected
            .map { LightMode(rawValue: $0) ?? .rotate }
            .subscribeNext {
                self.viewModel.inputs.segmentsSelection.accept($0)
                self.segmentSelected.accept($0)
            }
            .disposed(by: disposeBag)

        lightSpeedSlider
            .rx.value
            .changed
            .debounce(.milliseconds(400), scheduler: MainScheduler.asyncInstance)
            .compactMap { Int($0) }
            .subscribeNext { value in
                bluejay.write(to: LedStripService.ledStripSpeed, value: String(format:"%02X", value)) { result in
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
                self.colorTempSliderView.isHidden = $0 != StaticMode.colorTemp
                self.colorTempSliderView.alpha = $0 == StaticMode.colorTemp ? 1 : 0
                self.customColorView.alpha = $0 == StaticMode.colorTemp ? 0 : 1
                self.customColorView.isHidden = $0 == StaticMode.colorTemp
                self.mainContentViewHeightConstraint.constant = self.lightModeHeight(isStatic: true)
                self.needsUpdateConstraints()
                self.layoutIfNeeded()
                self.cellUpdated.accept(())

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

    private func lightModeHeight(isStatic: Bool) -> CGFloat {
        if isStatic {
            let height = Constraints.segmentHeight +
            Constraints.commonSpacing * 1.875 +
            Constraints.colorViewHeight
            staticColorViewHeightConstraint.constant = staticModeHeight(isColorTemp: staticColorSegmentControl.segmentSelected.value == 0)
            return CGFloat(height) + staticColorViewHeightConstraint.constant
        } else {
            return CGFloat(Constraints.labelHeight + Constraints.commonSpacing + Constraints.hsbViewHeight + Constraints.commonSpacing * 1.5 + Constraints.labelHeight + Constraints.commonSpacing + Constraints.collectionViewHeight + Constraints.commonSpacing / 2 + Constraints.labelHeight + Constraints.commonSpacing * 1.5 + Constraints.sliderHeight + Constraints.commonSpacing / 2)
        }
    }

    private func staticModeHeight(isColorTemp: Bool) -> CGFloat {
        let spacing = Constraints.commonSpacing * 1.875
        if isColorTemp {
            return CGFloat(
                Constraints.sliderHeight + spacing + Constraints.commonSpacing * 1.375
            )
        } else {

            return CGFloat(
                Constraints.commonSpacing * 1.875 +
                    Constraints.colorSliderHeight +
                Constraints.commonSpacing * 1.75 +
                    Constraints.colorSliderHeight +
                Constraints.commonSpacing * 1.75 +
                    Constraints.colorSliderHeight
            )

        }
    }
}

extension SegmentTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.cellWidth, height: Constants.cellHeight)
    }
}
