import Vapor

final class ManagerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let manager_routes = routes.grouped("manager")
        manager_routes.get(use: indexHandler)
        manager_routes.post("action", use: actionHandler)
        manager_routes.post("create", use: createHandler)
        manager_routes.post("search", use: searchHandler)
        manager_routes.post("report", "on", use: reportInterfaceHandler)
        manager_routes.post("change", "changeInput", use: changeInterfaceHandler)
        
        manager_routes.get("getAirplaneSelect", use: getAirplaneSelect)
    }
    
    static func verifyManager(_ req: Request) -> Bool {
        guard let token = req.session.data["manager"] else {
            return false
        }
        // Validate the token and get the associated user
        guard let _ = req.application.databaseManager.validateTokenAndGetManager(token: token) else {
            return false
        }
        return true
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

            return req.view.render("DataTemplates/ManagerActions/SearchInterfaces/\(templateName)")
        }

     func createHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let flight = try? req.content.decode(Flight.self) else {
            throw Abort(.badRequest)
        }

        print(flight)
        do {
            try req.application.databaseManager.addFlight(flight: flight)
        } catch {
            let view = req.view.render("DataTemplates/confirmation", ["text": "Error: \(error)", "type": "fail", "to": "#"])
            let response = view.encodeResponse(for: req)
            return response
        }
        return req.view.render("DataTemplates/confirmation", [
            "text": "You have successfully created a flight.",
            "type": "success",
            "to": "#"
        ]).encodeResponse(for: req)
    }

    func reportInterfaceHandler(_ req: Request) throws -> EventLoopFuture<View> {
        struct FormData: Content {
            let topic: String
        }

        let formData = try req.content.decode(FormData.self)

        let templateName: String

        switch formData.topic {
        case "fuel":
            templateName = "fuelUsageReport"
        case "passengers":
            templateName = "passengersReport"
        case "airport-flights":
            templateName = "airportFlightsReport"
        case "time-flights":
            templateName = "timeFlightsReport"
        default:
            throw Abort(.badRequest)
        }

        return req.view.render("DataTemplates/ManagerActions/ReportInterfaces/\(templateName)")
    }
    
    func getAirplaneSelect(_ req: Request) throws -> EventLoopFuture<View> {
        if !ManagerController.verifyManager(req) {
            throw Abort(.unauthorized)
        }
        
        let airplanes = req.application.databaseManager.getAirplanes()
        
        return req.view.render("DataTemplates/ManagerActions/CreateInterfaces/airplaneSelect", ["airplanes": airplanes])
    }

    func changeInterfaceHandler(_ req: Request) throws -> EventLoopFuture<View> {
        guard let flightId = Int(req.parameters.get("flightId")!) else {
            throw Abort(.expectationFailed)
        }

        return req.view.render("DataTemplates/ManagerActions/SearchInterfaces/changeInput")
    }
}
