//
//  PresetsTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 27/11/2020.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa

private struct Constants {
    static let cellHeight: CGFloat = 29.0
    static let cellWidth: CGFloat = 29.0
}

class PresetsTableViewCell: BaseTableViewCell<PresetsCellViewModel> {

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var titleLabel: UILabel!

    typealias Section = SectionModel<String, PresetCellViewModel>
    typealias DataSource = RxCollectionViewSectionedReloadDataSource<Section>

    var selectedCell = PublishRelay<(Int, PresetCellViewModel)>()

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = Asset.background.color
        titleLabel.font = FontFamily.OpenSans.regular.font(size: 18)
        titleLabel.textColor = Asset.primary.color
        collectionView.backgroundColor = Asset.background.color
        collectionView.register(ColorCell.nib, forCellWithReuseIdentifier: ColorCell.identifier)
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
    }
    override func bindViewModel() {
        viewModel.outputs
            .datas
            .map { [Section(model: "", items: $0)] }
            .drive(collectionView.rx.items(dataSource: makeDatasource()))
            .disposed(by: disposeBag)

        viewModel
            .outputs.title
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)

        Observable
            .zip(
                collectionView.rx.itemSelected,
                collectionView.rx.modelSelected(PresetCellViewModel.self)
            ).bind { [weak self] indexPath, model in
                guard let self = self else { return }
                self.collectionView.deselectItem(at: indexPath, animated: true)
                self.selectedCell.accept((indexPath.row, model))
            }.disposed(by: disposeBag)

        selectedCell.subscribeNext {
            self.viewModel.sendCommand(command: String(format:"%02X", ($0.0 + 1)))
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
}

extension PresetsTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.cellWidth, height: Constants.cellHeight)
    }
}
