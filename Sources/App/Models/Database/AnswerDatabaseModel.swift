import Vapor
import Fluent

final class AnswerDatabaseModel: Model {
    static let schema = "answer"

    struct FieldKeys {
        static var title: FieldKey { "title" }

        static var questionId: FieldKey { "questionId" }

        static var createdAt: FieldKey { "created_at" }
        static var updatedAt: FieldKey { "updated_at" }
    }

    @ID() var id: UUID?
    @Field(key: FieldKeys.title) var title: String

    @Parent(key: FieldKeys.questionId) var question: QuestionDatabaseModel
    @Field(key: FieldKeys.questionId) var questionId: QuestionDatabaseModel.IDValue

    @Timestamp(key: FieldKeys.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.updatedAt, on: .update) var updatedAt: Date?

    init() {}

    init(id: UUID? = nil,
         title: String,
         questionId: UUID
    ) {
        self.id = id
        self.title = title
        self.$question.id = questionId
    }
}

extension AnswerDatabaseModel: APIModel {

    struct InputContent: Content {
        let title: String
    }

    struct OutputContent: Content, Equatable {
        let id: String
        let title: String
    }

    typealias Input = InputContent
    typealias Output = OutputContent

    var output: OutputContent {
        OutputContent(id: id?.uuidString ?? "unknown", title: title)
    }

    convenience init(input: InputContent) throws {
        self.init()
        self.title = input.title
    }

    func update(input: InputContent) throws {
        title = input.title
    }
}
