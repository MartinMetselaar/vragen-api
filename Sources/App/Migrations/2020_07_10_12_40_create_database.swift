import Foundation
import Fluent

struct CreateDatabaseMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.flatten([
            database.schema(SurveyDatabaseModel.schema)
                .id()
                .field(SurveyDatabaseModel.FieldKeys.title, .string, .required)
                .field(SurveyDatabaseModel.FieldKeys.createdAt, .date, .required)
                .field(SurveyDatabaseModel.FieldKeys.updatedAt, .date, .required)
                .create(),

            database.schema(QuestionDatabaseModel.schema)
                .id()
                .field(QuestionDatabaseModel.FieldKeys.title, .string, .required)
                .field(QuestionDatabaseModel.FieldKeys.surveyId, .uuid, .required)
                .field(QuestionDatabaseModel.FieldKeys.createdAt, .date, .required)
                .field(QuestionDatabaseModel.FieldKeys.updatedAt, .date, .required)
                .foreignKey(QuestionDatabaseModel.FieldKeys.surveyId, references: SurveyDatabaseModel.schema, .id, onDelete: .cascade)
                .create(),

            database.schema(AnswerDatabaseModel.schema)
                .id()
                .field(AnswerDatabaseModel.FieldKeys.title, .string, .required)
                .field(AnswerDatabaseModel.FieldKeys.questionId, .uuid, .required)
                .field(AnswerDatabaseModel.FieldKeys.createdAt, .date, .required)
                .field(AnswerDatabaseModel.FieldKeys.updatedAt, .date, .required)
                .foreignKey(AnswerDatabaseModel.FieldKeys.questionId, references: QuestionDatabaseModel.schema, .id, onDelete: .cascade)
                .create(),
        ])
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.flatten([
            database.schema(AnswerDatabaseModel.schema).delete(),
            database.schema(QuestionDatabaseModel.schema).delete(),
            database.schema(SurveyDatabaseModel.schema).delete(),
        ])
    }
}