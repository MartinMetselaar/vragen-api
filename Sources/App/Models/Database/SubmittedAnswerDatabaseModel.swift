import Vapor
import Fluent

final class SubmittedAnswerDatabaseModel: Model {
    static let schema = "submitted_answer"

    struct FieldKeys {
        static var userId: FieldKey { "userId" }
        static var answerId: FieldKey { "answerId" }
        static var questionId: FieldKey { "questionId" }
        static var surveyId: FieldKey { "surveyId" }

        static var createdAt: FieldKey { "created_at" }
        static var updatedAt: FieldKey { "updated_at" }
    }

    @ID() var id: UUID?

    @Field(key: FieldKeys.userId) var userId: String

    @Parent(key: FieldKeys.answerId) var answer: AnswerDatabaseModel
    @Field(key: FieldKeys.answerId) var answerId: AnswerDatabaseModel.IDValue

    @Parent(key: FieldKeys.questionId) var question: QuestionDatabaseModel
    @Field(key: FieldKeys.questionId) var questionId: QuestionDatabaseModel.IDValue
    
    @Field(key: FieldKeys.surveyId) var surveyId: SurveyDatabaseModel.IDValue

    @Timestamp(key: FieldKeys.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.updatedAt, on: .update) var updatedAt: Date?

    init() {}

    init(id: UUID? = nil,
         userId: String,
         answerId: UUID,
         questionId: UUID,
         surveyId: UUID
    ) {
        self.id = id
        self.userId = userId
        self.answerId = answerId
        self.questionId = questionId
        self.surveyId = surveyId
    }
}
