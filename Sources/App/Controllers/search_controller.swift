import Foundation
import Vapor

struct SearchQuery: Content {
    var from: String
    var to: String
}

struct FlightsResult: Encodable {
    let flights: [Flight]
    let from: String
    let to: String
}

class SearchController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let search = routes.grouped("search")
        search.post(use: aa)
    }
    
    func aa(req: Request) throws -> EventLoopFuture<View> {
        guard let searchContent = try? req.content.decode(SearchQuery.self) else {
            throw Abort(.badRequest)
        }
        let flights = req.application.databaseManager.getFlights(from: searchContent.from, to: searchContent.to)
        print("Found \(flights.count) flights.")
        return req.view.render("DataTemplates/flights", ["flights": flights])
    }
}
