import Vapor
import Fluent

protocol APIModel: Model {
    associatedtype Input: Content
    associatedtype Output: Content

    var output: Output { get }

    init(input: Input) throws
    func update(input: Input) throws
}
