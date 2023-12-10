import Vapor

final class ManagerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let manager_routes = routes.grouped("manager")
        manager_routes.get(use: indexHandler)
        manager_routes.post("action", use: actionHandler)
        manager_routes.post("create", use: createHandler)
        manager_routes.post("search", use: searchHandler)
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

    func searchHandler(_ req: Request) throws -> EventLoopFuture<View> {
            struct FormData: Content {
                let criteria: String
            }

            let formData = try req.content.decode(FormData.self)

            let templateName: String

            switch formData.criteria {
            case "place":
                templateName = "searchPlace"
            case "number":
                templateName = "searchNumber"
            default:
                throw Abort(.badRequest)
            }

            return req.view.render("DataTemplates/ManagerActions/\(templateName)")
        }

     func createHandler(_ req: Request) throws -> EventLoopFuture<View> {
         do {
             try req.content.decode(Flight.self)
         } catch {
             print("Error decoding Flight: \(error)")
         }
        guard let flight = try? req.content.decode(Flight.self) else {
            throw Abort(.badRequest)
        }

        print(flight)
        do {
            try req.application.databaseManager.addFlight(flight: flight)
        } catch {
            print("Error adding to the database: \(error)")
            throw Abort(.badRequest)
        }
        return req.view.render("DataTemplates/confirmation", ["email": "beba"])
    }
}
