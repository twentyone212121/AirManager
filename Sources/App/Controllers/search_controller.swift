import Foundation
import Vapor

struct SearchContent: Content {
    var search: String
}

class SearchController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let search = routes.grouped("search")
        search.post(use: aa)
    }
    
    func aa(req: Request) async throws -> String {
        guard let searchContent = try? req.content.decode(SearchContent.self) else {
            throw Abort(.badRequest)
        }
        return "Your params are:\n\(searchContent.search)!"
    }

}
