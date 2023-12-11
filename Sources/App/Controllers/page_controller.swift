import Vapor

final class PageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        routes.get(use: indexHandler)
        routes.get("manager", use: managerHandler)
        routes.get("profile", use: profileHandler)
        routes.get("search", use: searchHandler)
        routes.get("login", use: loginHandler)
        routes.get("register", use: registerHandler)
        routes.get("header", use: getHeader)
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

    func getHeader(_ req: Request) throws -> EventLoopFuture<View> {
        guard let userToken = req.cookies["userToken"]?.string else {
            // Token not present, user is not authenticated
            return req.view.render("DataTemplates/Headers/guestHeader")
        }
        // Validate the token and get the associated user
        guard let loginData = req.application.databaseManager.validateTokenAndGetUser(token: userToken) else {
            return req.view.render("DataTemplates/Headers/guestHeader")
        }
//
//        guard let managerToken = req.cookies["managerToken"]?.string else {
//            // Token not present, user is not authenticated
//            return req.eventLoop.future(error: Abort(.unauthorized))
//        }
//        // Validate the token and get the associated user
//        guard let loginData = req.application.databaseManager.validateTokenAndGetUser(token: managerToken) else {
//            throw Abort(.unauthorized)
//        }
        return req.view.render("DataTemplates/Headers/userHeader")
    }
}

