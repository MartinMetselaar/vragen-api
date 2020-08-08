import Vapor
import Fluent

final class QuestionDatabaseModel: Model {
    static let schema = "question"

    struct FieldKeys {
        static var title: FieldKey { "title" }

        static var surveyId: FieldKey { "survey_id" }

        static var createdAt: FieldKey { "created_at" }
        static var updatedAt: FieldKey { "updated_at" }
    }

    @ID() var id: UUID?
    @Field(key: FieldKeys.title) var title: String
    @Children(for: \.$question) var answers: [AnswerDatabaseModel]

    @Parent(key: FieldKeys.surveyId) var survey: SurveyDatabaseModel
    @Field(key: FieldKeys.surveyId) var surveyId: SurveyDatabaseModel.IDValue

    @Timestamp(key: FieldKeys.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.updatedAt, on: .update) var updatedAt: Date?

    init() {}

    init(id: UUID? = nil,
         title: String,
         surveyId: UUID
    ) {
        self.id = id
        self.title = title
        self.$survey.id = surveyId
    }
}

extension QuestionDatabaseModel: APIModel {

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
