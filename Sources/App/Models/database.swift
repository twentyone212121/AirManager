import Foundation
import SQLite
import Vapor

struct Flight: Content {
    let date: String
    let fromIata: String
    let fromDate: Date
    let toIata: String
    let toDate: Date
    let number: Int
}

class DatabaseManager {
    public var db: Connection!

    public var countries: CountriesTable!
    public var flights: FlightsTable!
    public var users: UsersTable!
    public var tickets: TicketsTable!
    
    init() {
        do {
            let path = "Resources/airmanager.sqlite3"
            db = try Connection(path)
            countries = CountriesTable(db: db)
            flights = FlightsTable(db: db)
            users = UsersTable(db: db)
            tickets = TicketsTable(db: db)
        } catch {
            print("Error initializing database: \(error)")
        }
    }
    
    func getCountryIso2(countryName: String) -> String? {
        let query = countries.table
            .where(countries.nameColumn == countryName)
            .select(countries.iso2Column)
        
        do {
            for row in try db.prepare(query) {
                return row[countries.iso2Column]
            }
        } catch {
            return nil
        }
        return nil
    }
    
    func getFlights(from: String, to: String) -> [Flight] {
        let query = flights.table
            .where(flights.departureIataColumn == from &&
                   flights.arrivalIataColumn == to)
        
        var result: [Flight] = []
        do {
            for flight in try db.prepare(query) {
                result.append(Flight(
                    date: flight[flights.dateColumn],
                    fromIata: flight[flights.departureIataColumn],
                    fromDate: flight[flights.departureScheduledColumn],
                    toIata: flight[flights.arrivalIataColumn],
                    toDate: flight[flights.arrivalScheduledColumn],
                    number: flight[flights.flightNumberColumn]))
            }
        } catch {}
        return result
    }

//    func getUsers() -> [String: Int] {
//        var result: [String: Int] = [:]
//
//        do {
//            let usersTable = Table("users")
//            let name = Expression<String>("name")
//            let age = Expression<Int>("age")
//
//            for user in try db.prepare(usersTable) {
//                result[user[name]] = user[age]
//            }
//        } catch {
//            print("Error retrieving users: \(error)")
//        }
//
//        return result
//    }
}

