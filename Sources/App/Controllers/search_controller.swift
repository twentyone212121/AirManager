import Foundation
import Vapor

struct SearchQuery: Content {
    var from: String
    var to: String
}

class SearchController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let search = routes.grouped("search")
        search.get(use: searchFlights)
    }
    
    func searchFlights(req: Request) throws -> EventLoopFuture<View> {
        struct FlightsTemplateParams: Encodable {
            let flights: [Flight]
            let from: String
            let to: String
        }
        
        let from: String? = req.query["from"]
        let to: String? = req.query["to"]
        let number: Int? = req.query["number"]
        
        let flights: [Flight]
        switch (from, to, number) {
        case (.none, .none, .some(let number)):
            flights = req.application.databaseManager.getFlights(number: number)
            
        case (.some(var from), .some(var to), _):
            flights = req.application.databaseManager.getFlights(from: &from, to: &to)
            
        default:
            throw Abort(.badRequest)
        }
        
        print("Found \(flights.count) flights.")
        
        let tableTemplate: EventLoopFuture<View>
        if ManagerController.verifyManager(req) {
            tableTemplate = req.view.render(
                "DataTemplates/ManagerActions/managerFlights",
                ["flights": flights]
            )
        } else {
            tableTemplate = req.view.render(
                "DataTemplates/flights",
                FlightsTemplateParams(flights: flights, from: from ?? "", to: to ?? "")
            )
        }
        return tableTemplate
    }
}
