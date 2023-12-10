import Foundation
import Vapor

class UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let user_routes = routes.grouped("user")
        user_routes.get(use: indexHandler)
        user_routes.post("register", use: registerHandler)
        user_routes.post("data", use: getUserData)
        user_routes.post("buy", use: buyTicket)
        user_routes.get("info", use: getInfo)
        user_routes.post("login", use: login)
    }
    
    func registerHandler(_ req: Request) throws -> EventLoopFuture<View> {
        guard let user = try? req.content.decode(User.self) else {
            throw Abort(.badRequest)
        }
        
        print(user)
        do {
            try req.application.databaseManager.addUser(newUser: user)
        } catch {
            throw Abort(.badRequest)
        }
        return req.view.render("DataTemplates/confirmation", ["email": user.email])
    }
    
    func getUserData(_ req: Request) throws -> EventLoopFuture<View> {
        guard let loginData = try? req.content.decode(LoginData.self) else {
            throw Abort(.badRequest)
        }
        
        do {
            let user = try req.application.databaseManager.getUserData(loginData: loginData)
            return req.view.render("DataTemplates/userData", ["user": user])
        } catch {
            throw Abort(.badRequest)
        }
    }
    
    func buyTicket(_ req: Request) throws -> EventLoopFuture<View> {
        struct BuyData: Content {
            let flightId: Int
        }
        
        guard let token = req.cookies["token"]?.string else {
            // Token not present, user is not authenticated
            return req.eventLoop.future(error: Abort(.unauthorized))
        }
        
        // Validate the token and get the associated user
        guard let loginData = req.application.databaseManager.validateTokenAndGetUser(token: token) else {
            throw Abort(.unauthorized)
        }
        
        guard let buyData = try? req.content.decode(BuyData.self) else {
            throw Abort(.expectationFailed)
        }
        print(buyData)
        try req.application.databaseManager.addTicket(loginData: LoginData(email: loginData.email), flightId: buyData.flightId)
        return req.view.render("DataTemplates/confirmation", ["email": "Confirmed buy"])
    }
    
    func getInfo(_ req: Request) throws -> EventLoopFuture<View> {
        guard let token = req.cookies["token"]?.string else {
            // Token not present, user is not authenticated
            return req.eventLoop.future(error: Abort(.unauthorized))
        }
        
        // Validate the token and get the associated user
        guard let loginData = req.application.databaseManager.validateTokenAndGetUser(token: token) else {
            throw Abort(.unauthorized)
        }
        
        print(loginData)
        let userData = try req.application.databaseManager.getUserData(loginData: loginData)
        return req.view.render("profile", userData.self)
    }

    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("profile")
    }
    
    func login(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let loginData = try? req.content.decode(LoginData.self) else {
            throw Abort(.expectationFailed)
        }
        let token = loginData.email
        
        // Create an HTTP-only cookie with the token
        let cookie = HTTPCookies.Value(
            string: token,
            expires: Date(timeIntervalSinceNow: 3600), // Set an expiration time
            isHTTPOnly: true
        )
        
        // Set the cookie in the response
        let response = Response(status: .ok)
        response.cookies["token"] = cookie
        return req.eventLoop.future(response)
    }
}
