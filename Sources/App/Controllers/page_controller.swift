import Vapor

final class PageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        routes.get(use: indexHandler)
        routes.get("manager", use: managerHandler)
        routes.get("profile", use: profileHandler)
        routes.get("search", use: searchHandler)
        routes.get("login", use: loginHandler)
        routes.get("register", use: registerHandler)
    }

    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("index")
    }

    func managerHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("manager")
    }

    func profileHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("profile")
    }
    
    func searchHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("search")
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("login")
    }

    func registerHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("register")
    }
}

