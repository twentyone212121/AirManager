import Vapor

final class ManagerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let manager_routes = routes.grouped("manager")
        manager_routes.get(use: indexHandler)
        manager_routes.post("action", use: actionHandler)
        manager_routes.post("create", use: actionHandler)
    }

    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("manager")
    }

    func actionHandler(_ req: Request) throws -> EventLoopFuture<View> {
        struct FormData: Content {
            let action: String
        }

        let formData = try req.content.decode(FormData.self)

        let templateName: String

        switch formData.action {
        case "create":
            templateName = "create"
        case "change":
            templateName = "change"
        case "report":
            templateName = "report"
        default:
            throw Abort(.badRequest)
        }

        return req.view.render("DataTemplates/ManagerActions/\(templateName)")
    }
}