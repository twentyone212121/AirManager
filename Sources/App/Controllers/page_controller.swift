import Vapor

final class PageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        routes.get(use: indexHandler)
        routes.get("profile", use: profileHandler)
        routes.get("searchPage", use: searchHandler)
        routes.get("login", use: loginHandler)
        routes.get("logout", use: logoutHandler)
        routes.get("register", use: registerHandler)
        routes.get("header", use: getHeader)
    }

    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("index")
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
    
    func logoutHandler(_ req: Request) throws -> Response {
        // Delete the authentication-related cookie
        req.session.destroy()

        // Redirect the user to the desired page after logout
        return req.redirect(to: "/login")
    }

    func registerHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("register")
    }

    func getHeader(_ req: Request) throws -> EventLoopFuture<View> {
        let userToken = req.session.data["user"]
        let managerToken = req.session.data["manager"]
        
        switch (userToken, managerToken) {
        case (.none, .none):
            return req.view.render("DataTemplates/Headers/guestHeader")
            
        case (.some(let userTokenString), .none):
            guard let loginData = req.application.databaseManager.validateTokenAndGetUser(token: userTokenString) else {
                return req.view.render("DataTemplates/Headers/guestHeader")
            }
            return req.view.render("DataTemplates/Headers/userHeader")
            
        case (.none, .some(let managerTokenString)):
            guard let loginData = req.application.databaseManager.validateTokenAndGetManager(token: managerTokenString) else {
                return req.view.render("DataTemplates/Headers/guestHeader")
            }
            return req.view.render("DataTemplates/Headers/managerHeader")
        
        case (.some(_), .some(_)):
            return req.view.render("DataTemplates/Headers/guestHeader")
        }
    }
}

