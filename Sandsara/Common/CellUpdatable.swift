import Foundation

protocol UpdatableCell {

    associatedtype ModelDataType

    func bind(with item: ModelDataType)
}
