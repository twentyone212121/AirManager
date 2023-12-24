import XCTest
import SQLite
@testable import App

class DatabaseManagerTests: XCTestCase {
    let testDatabasePath = "Resources/testDB.sqlite3"
    var databaseManager: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        // pass path to database mock
        databaseManager = DatabaseManager(path: testDatabasePath)
    }
    
    final override class func tearDown() {
        super.tearDown()
        // Delete test database file
        let testDatabasePath = "Resources/testDB.sqlite3"
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: testDatabasePath) {
            try! fileManager.removeItem(atPath: testDatabasePath)
        }
    }
    
    func testFlightDecoding() {
        let json = """
        {
            "fromIata": "JFK",
            "toIata": "LAX",
            "freeSeats": 100,
            "number": 123,
            "price": 500.0,
            "airplaneId": 1,
            "fromDate": "2023-12-08T12:00",
            "toDate": "2023-12-08T17:30"
        }
        """
        
        let jsonData = json.data(using: .utf8)!
        
        do {
            let flight = try JSONDecoder().decode(Flight.self, from: jsonData)
        } catch {
            XCTFail("Failed to decode Flight: \(error)")
        }
    }
    
    func testGetCountryIso2() {
        let country = "Ukraine"
        let iso2 = databaseManager.getCountryIso2(countryName: country)
        XCTAssert(iso2 == "UA", "getCountryIso2 should return proper iso2 code of the country")
    }
    
    func testGetFlightById() {
        let flightIdBad = -1
        let flightIdGood = 1
        
        let badResult = databaseManager.getFlight(id: flightIdBad)
        let goodResult = databaseManager.getFlight(id: flightIdGood)
        
        XCTAssert(badResult == nil, "DB flight id shouldn't be less then 0")
        XCTAssert(goodResult != nil, "DB flight id of 1 should be present")
    }
    
    func testGetUpcomingFlights() {
        let upcomingFlights = databaseManager.getUpcomingFlights()
        
        XCTAssertFalse(upcomingFlights.isEmpty, "Upcoming flights shouldn't be empty")
    }
    
    func testAddUser() {
        // Arrange
        let firstUser = User(email: "u@g.com", password: "password", fullName: "John Doe", passportNumber: "GD446", phoneNumber: 380996241028, gender: "Male")
        let secondUser = User(email: "u@g.com", password: "password", fullName: "John Doe", passportNumber: "GD446", phoneNumber: 380996241028, gender: "Male")
        let loginData = LoginData(email: "u@g.com", password: "password")
        
        // Act & Assert
        XCTAssertNoThrow(try databaseManager.addUser(newUser: firstUser), "Adding new user shouldn't throw an error")
        XCTAssertThrowsError(try databaseManager.addUser(newUser: secondUser), "Adding user with the same email should throw an error")
        let userType = databaseManager.verifyLogin(loginData: loginData)
        XCTAssert(userType == UserType.user, "User type should be User")
    }
    
    func testAddManager() {
        // Arrange
        let firstManager = Manager(email: "a@g.com", password: "password", fullName: "John Doe")
        let secondManager = Manager(email: "a@g.com", password: "password", fullName: "John Doe")
        let loginData = LoginData(email: "a@g.com", password: "password")
        
        // Act & Assert
        XCTAssertNoThrow(try databaseManager.addManager(newManager: firstManager), "Adding new manager shouldn't throw an error")
        XCTAssertThrowsError(try databaseManager.addManager(newManager: secondManager), "Adding manager with the same email should throw an error")
        let userType = databaseManager.verifyLogin(loginData: loginData)
        XCTAssert(userType == UserType.manager, "Manager type should be Manager")

    }
    
    func testAddTicket() {
        let loginData = LoginData(email: "u@g.com", password: "password")
        let flightId = 1
        
        XCTAssertNoThrow(try databaseManager.addTicket(loginData: loginData, flightId: flightId), "Buying a first ticket with enough freeSeats shouldn't throw an error")
        XCTAssertThrowsError(try databaseManager.addTicket(loginData: loginData, flightId: flightId), "Buying a second the same ticket should throw an error")
    }
    
    func testGetFuelUsage() {
        // Arrange
        let flightNumber = 6501
        
        // Act
        let fuelUsageRows = databaseManager.getFuelUsage(flightNumber: flightNumber)
        
        // Assert
        XCTAssertFalse(fuelUsageRows.isEmpty, "Fuel usage rows should not be empty")
        XCTAssertTrue(fuelUsageRows[0].number == flightNumber, "Number should match")
    }
    
    func testGetFlightsFromAirport() {
        // Arrange
        let departureIata = "JFK"
        
        // Act
        let flights = databaseManager.getFlightsFromAirport(departureIata: departureIata)
        
        // Assert
        XCTAssertFalse(flights.isEmpty, "Flights should not be empty")
        XCTAssertTrue(flights.allSatisfy({$0.fromIata == "JFK"}), "Departure code should match")
    }
    
    func testGetFlightsBetween() {
        // Arrange
        let fromDate = Date()
        let toDate = Date().addingTimeInterval(3600)
        
        // Act
        let flights = databaseManager.getFlightsBetween(from: fromDate, to: toDate)
        
        // Assert
        XCTAssertFalse(flights.isEmpty, "Flights should not be empty")
        XCTAssertTrue(flights.allSatisfy({fromDate...toDate ~= $0.fromDate}), "Flights should be in correct timerange.")
    }
    
    func testGetUsers() {
        // Arrange
        let flightId = 8843
        
        // Act
        let users = databaseManager.getUsers(by: flightId)
        
        // Assert
        XCTAssertTrue(users.allSatisfy({$0.password == ""}), "Users info shouldn't contain passwords")
    }
}
