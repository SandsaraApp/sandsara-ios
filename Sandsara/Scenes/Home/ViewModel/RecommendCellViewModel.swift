//
//  RecommendCellViewModel.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import RxSwift
import RxCocoa
import RxDataSources

enum RecommendCellVMContract {
    struct Input: InputType {
        let item: DisplayItem
    }

    struct Output: OutputType {
        let url: URL?
    }
}

class RecommendCellViewModel: BaseCellViewModel<RecommendCellVMContract.Input,
                                                RecommendCellVMContract.Output> {
    override func transform() {
        let url = URL(string: inputs.item.thumbnail)
        setOutput(Output(url: url))
    }
}

enum RecommendTableViewCellVMContract {
    struct Input: InputType {
        let section: DiscoverSection
        let items: [DisplayItem]
    }

    struct Output: OutputType {
        let title: Driver<String>
        let dataSources: Driver<[RecommendCellViewModel]>
    }
}

class RecommendTableViewCellViewModel: BaseCellViewModel<RecommendTableViewCellVMContract.Input,
                                                         RecommendTableViewCellVMContract.Output> {

    override func transform() {
        let vms = inputs.items.map {
            RecommendCellViewModel(inputs: RecommendCellVMContract.Input(item: $0))
        }
        setOutput(Output(title: Driver.just(inputs.section.title),dataSources: Driver.just(vms)))
    }
}
