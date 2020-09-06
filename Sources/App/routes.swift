import Vapor

func routes(_ app: Application) throws {
    let api = app.routes.grouped("api")
    let v1 = api.grouped("v1")

    let surveyController = SurveyController()
    let surveys = v1.grouped("surveys")
    surveyController.routes(routes: surveys, id: "surveyId")

    let questions = surveys.grouped(":surveyId", "questions")
    let questionController = QuestionController()
    questionController.routes(routes: questions, id: "questionId")

    let answers = questions.grouped(":questionId", "answers")
    let answerController = AnswerController()
    answerController.routes(routes: answers, id: "answerId")

    let submitAnswerController = SubmitAnswerController()
    let submit = v1.grouped("submit")
    submitAnswerController.routes(routes: submit)
}
