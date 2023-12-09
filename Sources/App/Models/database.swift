import Foundation
import SQLite
import Vapor

struct Flight: Content {
    let date: String
    let fromIata: String
    let fromDate: Date
    let toIata: String
    let toDate: Date
    let duration: Double
    let number: Int
    let price: Double
}

class DatabaseManager {
    public var db: Connection!

    public var countries: CountriesTable!
    public var airports: AirportsTable!
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
            airports = AirportsTable(db: db)
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
        let query: QueryType
        if from.count == 3 && to.count == 3 {
             query = flights.table
                .where(flights.departureIataColumn == from &&
                       flights.arrivalIataColumn == to)
        } else {
            let departureAirport = airports.table.alias("departureAirport")
            let arrivalAirport = airports.table.alias("arrivalAirport")
            query = flights.table
                .join(departureAirport, on: flights.departureIataColumn == departureAirport[airports.iataColumn])
                .join(arrivalAirport, on: flights.arrivalIataColumn == arrivalAirport[airports.iataColumn])
                .filter(departureAirport[airports.cityColumn] == from)
                .filter(arrivalAirport[airports.cityColumn] == to)
                .select(flights.table[*])
        }
                
        var result: [Flight] = []
        do {
            for flight in try db.prepare(query) {
                result.append(Flight(
                    date: flight[flights.dateColumn],
                    fromIata: flight[flights.departureIataColumn],
                    fromDate: flight[flights.departureScheduledColumn],
                    toIata: flight[flights.arrivalIataColumn],
                    toDate: flight[flights.arrivalScheduledColumn],
                    duration: flight[flights.durationColumn],
                    number: flight[flights.flightNumberColumn],
                    price: flight[flights.priceColumn]))
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

