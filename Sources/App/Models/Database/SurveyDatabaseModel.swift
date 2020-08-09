import Vapor
import Fluent
import VragenAPIModels

final class SurveyDatabaseModel: Model {
    static let schema = "survey"

    struct FieldKeys {
        static var title: FieldKey { "title" }

        static var createdAt: FieldKey { "created_at" }
        static var updatedAt: FieldKey { "updated_at" }
    }

    @ID() var id: UUID?
    @Field(key: FieldKeys.title) var title: String
    @Children(for: \.$survey) var questions: [QuestionDatabaseModel]

    @Timestamp(key: FieldKeys.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.updatedAt, on: .update) var updatedAt: Date?

    init() {}

    init(id: UUID? = nil,
         title: String
    ) {
        self.id = id
        self.title = title
    }
}
