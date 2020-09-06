import Vapor
import Fluent

protocol APIModel: Model {
    associatedtype Input: Codable
    associatedtype Output: (Codable & Content)

    var output: Output? { get }

    init(input: Input) throws
    func update(input: Input) throws
}
