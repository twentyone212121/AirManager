import XCTVapor
@testable import App

class AppTests: XCTestCase {
    func testIntegration() async throws {
        // Configure App
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        // Test routes for unregistered users
        try AppTests.search(app)
        try AppTests.upcomingFlights(app)
        
        // Test routes for registered users
        try AppTests.userRegister(app)
        let userCookie = try AppTests.userLogin(app)
        try AppTests.buyTicket(app, userCookie)
        try AppTests.getProfile(app, userCookie)
        
        // Test routes for managers
        let managerCookie = try AppTests.managerLogin(app)
        try AppTests.changeFlight(app, managerCookie)
        try AppTests.getFuelUsage(app, managerCookie)
        try AppTests.getAirportFlights(app, managerCookie)
        try AppTests.getFlightsBetween(app, managerCookie)
        try AppTests.getPassengers(app, managerCookie)
        
        print("Integration test successfully passed")
    }
    
    static func search(_ app: Application) throws {
        try app.test(.GET, "search?from=JFK&to=ATL", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        try app.test(.GET, "search?number=6501", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        try app.test(.GET, "search", afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }
    
    static func upcomingFlights(_ app: Application) throws {
        try app.test(.GET, "upcomingFlights", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    static func userRegister(_ app: Application) throws {
        try app.test(.POST, "user/register", beforeRequest: { req in
            try req.content.encode(User(email: "testuser@mail.com", password: "test123", fullName: "John Doe", passportNumber: "GD446", phoneNumber: 380996241028, gender: "Male"))
        }, afterResponse: {res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    static func userLogin(_ app: Application) throws -> HTTPCookies {
        var cookie: HTTPCookies? = nil
        try app.test(.POST, "user/login", beforeRequest: { req in
            try req.content.encode(LoginData(email: "testuser@mail.com", password: "test123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertNotNil(res.headers.setCookie, "Login should return a session cookie")
            cookie = res.headers.setCookie!
        })
        return cookie!
    }
    
    static func buyTicket(_ app: Application, _ cookie: HTTPCookies) throws {
        try app.test(.GET, "user/buy/1", beforeRequest: { req in
            req.headers.cookie = cookie
        }, afterResponse: {res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    static func getProfile(_ app: Application, _ cookie: HTTPCookies) throws {
        try app.test(.GET, "user/info", beforeRequest: { req in
            req.headers.cookie = cookie
        }, afterResponse: {res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    static func managerLogin(_ app: Application) throws -> HTTPCookies {
        var cookie: HTTPCookies? = nil
        try app.test(.POST, "user/login", beforeRequest: { req in
            try req.content.encode(LoginData(email: "admin@jabber.com", password: "admin"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertNotNil(res.headers.setCookie, "Login should return a session cookie")
            cookie = res.headers.setCookie!
        })
        return cookie!
    }
    
    static func changeFlight(_ app: Application, _ cookie: HTTPCookies) throws {
        struct Params: Content {
            let flightId: Int
            let price: Double
            let freeSeats: Int
        }
        try app.test(.GET, "manager/change", beforeRequest: { req in
            req.headers.cookie = cookie
            try req.query.encode(Params(flightId: 2, price: 122.50, freeSeats: 100))
        }, afterResponse: {res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    static func getFuelUsage(_ app: Application, _ cookie: HTTPCookies) throws {
        try app.test(.GET, "manager/reports/fuelUsage", beforeRequest: { req in
            req.headers.cookie = cookie
            try req.query.encode(["number": 8843])
       }, afterResponse: {res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    static func getAirportFlights(_ app: Application, _ cookie: HTTPCookies) throws {
        try app.test(.GET, "manager/reports/airportFlights", beforeRequest: { req in
            req.headers.cookie = cookie
            try req.query.encode(["airport": "LAX"])
       }, afterResponse: {res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    static func getFlightsBetween(_ app: Application, _ cookie: HTTPCookies) throws {
        try app.test(.GET, "manager/reports/flightsBetween", beforeRequest: { req in
            req.headers.cookie = cookie
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            try req.query.encode(["fromDate": dateFormatter.string(from: Date()), "toDate": dateFormatter.string(from: Date().addingTimeInterval(3600))])
       }, afterResponse: {res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    static func getPassengers(_ app: Application, _ cookie: HTTPCookies) throws {
        try app.test(.GET, "manager/reports/passengersSearch", beforeRequest: { req in
            req.headers.cookie = cookie
            try req.query.encode(["number": 8843])
       }, afterResponse: {res in
            XCTAssertEqual(res.status, .ok)
        })
    }
}
