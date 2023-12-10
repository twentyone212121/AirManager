import Foundation
import Vapor

class UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let user_routes = routes.grouped("user")
        user_routes.get(use: indexHandler)
        user_routes.post("register", use: registerHandler)
        user_routes.get("buy", ":flightId", use: buyTicket)
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
        
    func buyTicket(_ req: Request) throws -> EventLoopFuture<View> {
        guard let token = req.cookies["userToken"]?.string else {
            // Token not present, user is not authenticated
            return req.eventLoop.future(error: Abort(.unauthorized))
        }
        
        // Validate the token and get the associated user
        guard let loginData = req.application.databaseManager.validateTokenAndGetUser(token: token) else {
            throw Abort(.unauthorized)
        }
        
        guard let flightId = Int(req.parameters.get("flightId")!) else {
            throw Abort(.expectationFailed)
        }
        print(flightId)
        try req.application.databaseManager.addTicket(loginData: loginData, flightId: flightId)
        return req.view.render("DataTemplates/confirmation", ["email": "Confirmed buy"])
    }
    
    func getInfo(_ req: Request) throws -> EventLoopFuture<View> {
        guard let token = req.cookies["userToken"]?.string else {
            // Token not present, user is not authenticated
            return req.eventLoop.future(error: Abort(.unauthorized))
        }
        
        // Validate the token and get the associated user
        guard let loginData = req.application.databaseManager.validateTokenAndGetUser(token: token) else {
            throw Abort(.unauthorized)
        }
        
        print(loginData)
        let userData = try req.application.databaseManager.getUserData(loginData: loginData)
        return req.view.render("DataTemplates/userData", userData.self)
    }

    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("profile")
    }
    
    func login(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let loginData = try? req.content.decode(LoginData.self) else {
            throw Abort(.expectationFailed)
        }
        
        guard let userType = req.application.databaseManager.verifyLogin(loginData: loginData) else {
            return req.view.render("DataTemplates/confirmation", ["email": "Incorrect login or password"]).encodeResponse(for: req)
        }
        
        let token = loginData.email
        // Create an HTTP-only cookie with the token
        let cookie = HTTPCookies.Value(
            string: token,
            expires: Date(timeIntervalSinceNow: 3600), // Set an expiration time
            isHTTPOnly: true
        )
        
        let returnHTML: EventLoopFuture<View>
        let cookieName: String
        switch userType {
        case UserType.manager:
            cookieName = "managerToken"
            returnHTML = req.view.render("DataTemplates/confirmation", ["email": "Confirmed manager login."])
        case UserType.user:
            cookieName = "userToken"
            returnHTML = req.view.render("DataTemplates/confirmation", ["email": "Confirmed user login"])
        }
        
        let response = returnHTML.encodeResponse(for: req)
        response.whenSuccess { response in
            response.cookies[cookieName] = cookie
        }
        
        return response
    }
}
