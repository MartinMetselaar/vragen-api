import Foundation
import Fluent

struct AddSubmittedAnswerMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.flatten([
            database.schema(SubmittedAnswerDatabaseModel.schema)
                .id()
                .field(SubmittedAnswerDatabaseModel.FieldKeys.userId, .string, .required)

                .field(SubmittedAnswerDatabaseModel.FieldKeys.surveyId, .uuid, .required)
                .foreignKey(SubmittedAnswerDatabaseModel.FieldKeys.surveyId, references: SurveyDatabaseModel.schema, .id, onDelete: .cascade)

                .field(SubmittedAnswerDatabaseModel.FieldKeys.questionId, .uuid, .required)
                .foreignKey(SubmittedAnswerDatabaseModel.FieldKeys.questionId, references: QuestionDatabaseModel.schema, .id, onDelete: .cascade)
                
                .field(SubmittedAnswerDatabaseModel.FieldKeys.answerId, .uuid, .required)
                .foreignKey(SubmittedAnswerDatabaseModel.FieldKeys.answerId, references: AnswerDatabaseModel.schema, .id, onDelete: .cascade)

                .field(SubmittedAnswerDatabaseModel.FieldKeys.createdAt, .datetime, .required)
                .field(SubmittedAnswerDatabaseModel.FieldKeys.updatedAt, .datetime, .required)

                .unique(on:
                    SubmittedAnswerDatabaseModel.FieldKeys.userId,
                    SubmittedAnswerDatabaseModel.FieldKeys.surveyId,
                    SubmittedAnswerDatabaseModel.FieldKeys.questionId,
                    name: "uq:userId+surveyId+questionId"
                )

                .create()
        ])
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.flatten([
            database.schema(SubmittedAnswerDatabaseModel.schema).delete(),
        ])
    }
}
